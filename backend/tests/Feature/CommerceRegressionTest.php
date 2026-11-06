<?php

namespace Tests\Feature;

use App\Exceptions\CheckoutException;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Settlement;
use App\Models\Store;
use App\Models\User;
use App\Services\CashService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CommerceRegressionTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $role): User
    {
        return User::factory()->create(['role' => $role, 'status' => 'active']);
    }

    private function product(User $seller): Product
    {
        $store = Store::create(['user_id' => $seller->id, 'name' => 'Studio', 'slug' => 'studio-'.$seller->id]);

        return Product::create(['store_id' => $store->id, 'name' => 'Bag', 'slug' => 'bag-'.$seller->id,
            'price_fiat' => 20, 'price_tokens' => 16, 'stock' => 5, 'status' => 'active']);
    }

    private function delivery(User $customer, Product $product, ?User $driver = null): Delivery
    {
        $order = Order::create(['order_number' => 'ORD-'.uniqid(), 'customer_id' => $customer->id,
            'store_id' => $product->store_id, 'total_fiat' => 22.5, 'discount_amount' => 2,
            'delivery_fee' => 4.5, 'payment_method' => 'cash', 'shipping_address' => 'Test street',
            'status' => $driver ? 'out_for_delivery' : 'ready_for_pickup']);
        OrderItem::create(['order_id' => $order->id, 'product_id' => $product->id, 'quantity' => 1,
            'unit_fiat' => 20, 'unit_tokens' => 16, 'total_fiat' => 20]);

        return Delivery::create(['order_id' => $order->id, 'driver_id' => $driver?->id,
            'status' => $driver ? 'out_for_delivery' : 'ready_for_pickup', 'pickup_store_name' => 'Studio',
            'pickup_address' => 'Store street', 'customer_name' => $customer->name,
            'dropoff_address' => 'Test street', 'amount_due' => 22.5, 'courier_payout' => 4.5]);
    }

    public function test_private_modules_require_the_correct_active_role(): void
    {
        foreach (['seller/dashboard', 'seller/products', 'delivery/tasks', 'delivery/earnings'] as $path) {
            $this->getJson('/api/v1/'.$path)->assertUnauthorized();
        }
        Sanctum::actingAs($this->user('customer'));
        $this->getJson('/api/v1/seller/products')->assertForbidden();
        $this->getJson('/api/v1/delivery/tasks')->assertForbidden();
        $this->postJson('/api/v1/delivery/tasks/1/claim')->assertForbidden();
    }

    public function test_seller_without_store_cannot_fall_back_to_another_store(): void
    {
        $product = $this->product($this->user('seller'));
        $delivery = $this->delivery($this->user('customer'), $product);
        Sanctum::actingAs($this->user('seller'));
        $this->getJson('/api/v1/seller/dashboard')->assertOk()->assertJsonPath('data.store', null);
        $this->getJson('/api/v1/seller/products')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/seller/products/'.$product->id)->assertNotFound();
        $this->putJson('/api/v1/seller/products/'.$product->id, ['price_fiat' => 1])->assertNotFound();
        $this->deleteJson('/api/v1/seller/products/'.$product->id)->assertNotFound();
        $this->getJson('/api/v1/seller/orders/'.$delivery->order_id)->assertNotFound();
        $this->postJson('/api/v1/seller/orders/'.$delivery->order_id.'/refund')->assertNotFound();
        $this->assertEquals(20, $product->fresh()->price_fiat);
    }

    public function test_product_validation_happens_before_creating_a_store(): void
    {
        Sanctum::actingAs($this->user('seller'));
        $this->postJson('/api/v1/seller/products/save', ['name' => 'Bag', 'price_fiat' => -1, 'stock' => -2])
            ->assertUnprocessable();
        $this->assertDatabaseCount('stores', 0);
        $this->postJson('/api/v1/seller/products/save', ['name' => 'Bag', 'price_fiat' => 10, 'stock' => 3])
            ->assertOk()->assertJsonPath('product.stock', 3);
        // Mobile clients often send "" for optional URL fields; that must not 422.
        $this->postJson('/api/v1/seller/products/save', [
            'name' => 'Blank Image',
            'price_fiat' => 12,
            'stock' => 2,
            'image' => '',
            'description' => '',
        ])->assertOk()
            ->assertJsonPath('product.status', 'active')
            ->assertJsonPath('product.gender', 'unisex');
    }

    public function test_couriers_only_see_available_jobs_and_their_own_jobs(): void
    {
        $product = $this->product($this->user('seller'));
        $customer = $this->user('customer');
        $driver = $this->user('delivery');
        $mine = $this->delivery($customer, $product, $driver);
        $other = $this->delivery($customer, $product, $this->user('delivery'));
        $available = $this->delivery($customer, $product);
        Sanctum::actingAs($driver);
        $this->getJson('/api/v1/delivery/tasks')->assertOk()->assertJsonCount(2, 'data')
            ->assertJsonMissing(['id' => $other->id, 'order_id' => $other->order_id]);
        $this->postJson('/api/v1/delivery/tasks/'.$other->id.'/claim')->assertConflict();
        $this->postJson('/api/v1/delivery/tasks/'.$other->id.'/status', ['status' => 'delivered', 'cash_collected' => 22.5])->assertNotFound();
        $this->postJson('/api/v1/delivery/tasks/'.$other->id.'/location', ['lat' => 35, 'lng' => 44])->assertNotFound();
        $this->postJson('/api/v1/delivery/tasks/'.$mine->id.'/location', ['lat' => 91, 'lng' => 44])->assertUnprocessable();
        $this->postJson('/api/v1/delivery/tasks/'.$mine->id.'/location', ['lat' => 35, 'lng' => 44])->assertOk();
        $this->postJson('/api/v1/delivery/tasks/'.$available->id.'/claim')->assertOk();
        $this->assertEquals($driver->id, $available->fresh()->driver_id);
        $this->postJson('/api/v1/delivery/tasks/'.$mine->id.'/claim')->assertOk();
        $this->assertSame('out_for_delivery', $mine->fresh()->status);
    }

    public function test_delivery_completion_cannot_record_cash_twice_or_reopen(): void
    {
        $driver = $this->user('delivery');
        $delivery = $this->delivery($this->user('customer'), $this->product($this->user('seller')), $driver);
        Sanctum::actingAs($driver);
        $url = '/api/v1/delivery/tasks/'.$delivery->id.'/status';
        $this->postJson($url, ['status' => 'delivered', 'cash_collected' => 22.5])->assertOk();
        $this->postJson($url, ['status' => 'delivered', 'cash_collected' => 22.5])->assertUnprocessable();
        $this->postJson($url, ['status' => 'picked_up'])->assertUnprocessable();
        $this->assertDatabaseCount('settlements', 1);
        $this->assertEquals(22.5, Settlement::first()->gross_cash);
        $this->assertEquals(4.5, Settlement::first()->courier_commission);
        $this->assertSame('delivered', $delivery->fresh()->order->status);
    }

    public function test_cash_service_rejects_duplicate_records_even_with_a_stale_model(): void
    {
        $delivery = $this->delivery($this->user('customer'), $this->product($this->user('seller')), $this->user('delivery'));
        CashService::recordCollection($delivery, 22.5);
        try {
            CashService::recordCollection($delivery, 22.5);
            $this->fail('Repeated cash collection must fail.');
        } catch (CheckoutException $e) {
            $this->assertEquals(22.5, Settlement::first()->gross_cash);
        }
    }

    public function test_refund_and_legacy_cash_due_use_the_final_total_once(): void
    {
        $product = $this->product($this->user('seller'));
        $delivery = $this->delivery($this->user('customer'), $product, $this->user('delivery'));
        $delivery->update(['amount_due' => null]);
        CashService::freezeAmountDue($delivery);
        $this->assertEquals(22.5, $delivery->fresh()->amount_due);
        $order = $delivery->order;
        $order->update(['status' => 'delivered']);
        try {
            CashService::refundOrder($order, 27, null);
            $this->fail('Delivery must not be added twice.');
        } catch (CheckoutException $e) {
            $this->assertSame('delivered', $order->fresh()->status);
        }
        CashService::refundOrder($order, 22.5, null);
        try {
            CashService::refundOrder($order, 22.5, null);
            $this->fail('A stale model must not allow a second refund.');
        } catch (CheckoutException $e) {
            $this->assertEquals(6, $product->fresh()->stock);
        }
    }

    public function test_repeated_product_ids_cannot_oversell_and_valid_lines_are_combined(): void
    {
        $product = $this->product($this->user('seller'));
        Sanctum::actingAs($this->user('customer'));
        $payload = ['items' => [['product_id' => $product->id, 'quantity' => 3], ['product_id' => $product->id, 'quantity' => 3]],
            'payment_method' => 'cash', 'shipping_address' => 'Test street'];
        $this->postJson('/api/v1/customer/quote', $payload)->assertUnprocessable();
        $this->postJson('/api/v1/customer/checkout', $payload)->assertUnprocessable();
        $this->assertEquals(5, $product->fresh()->stock);
        $this->assertDatabaseCount('orders', 0);
        $payload['items'][1]['quantity'] = 2;
        $this->postJson('/api/v1/customer/checkout', $payload)->assertCreated()
            ->assertJsonCount(1, 'order.items')->assertJsonPath('order.items.0.quantity', 5);
        $this->assertEquals(0, $product->fresh()->stock);
    }

    public function test_checkout_cannot_assign_another_stores_items_to_one_seller(): void
    {
        $one = $this->product($this->user('seller'));
        $two = $this->product($this->user('seller'));
        Sanctum::actingAs($this->user('customer'));
        $payload = ['items' => [['product_id' => $one->id, 'quantity' => 1], ['product_id' => $two->id, 'quantity' => 1]],
            'payment_method' => 'cash', 'shipping_address' => 'Test street'];
        $this->postJson('/api/v1/customer/quote', $payload)->assertUnprocessable();
        $this->postJson('/api/v1/customer/checkout', $payload)->assertUnprocessable();
        $this->assertDatabaseCount('orders', 0);
        $this->assertEquals(5, $one->fresh()->stock);
        $this->assertEquals(5, $two->fresh()->stock);
    }

    public function test_seller_cannot_bypass_cash_collection_and_cancellation_restores_stock_once(): void
    {
        $seller = $this->user('seller');
        $product = $this->product($seller);
        $delivery = $this->delivery($this->user('customer'), $product);
        Sanctum::actingAs($seller);
        $url = '/api/v1/seller/orders/'.$delivery->order_id.'/status';
        $this->postJson($url, ['status' => 'delivered'])->assertUnprocessable();
        $this->postJson($url, ['status' => 'cancelled'])->assertOk();
        $this->postJson($url, ['status' => 'cancelled'])->assertUnprocessable();
        $this->assertEquals(6, $product->fresh()->stock);
        $this->assertSame('cancelled', $delivery->fresh()->status);
    }

    public function test_suspended_accounts_cannot_login_or_use_existing_tokens(): void
    {
        $user = User::factory()->create(['status' => 'suspended', 'password' => 'password123']);
        $this->postJson('/api/v1/auth/login', ['email' => $user->email, 'password' => 'password123'])->assertForbidden();
        $this->postJson('/api/v1/auth/login', ['email' => $user->email, 'password' => ['bad']])->assertUnprocessable();
        Sanctum::actingAs($user);
        $this->getJson('/api/v1/auth/profile')->assertForbidden();
        $this->getJson('/api/v1/customer/orders')->assertForbidden();
    }

    public function test_catalog_and_marketplace_routes_use_the_clients_api_prefix(): void
    {
        $this->getJson('/api/v1/customer/banners')->assertOk();
        $this->getJson('/api/v1/customer/support')->assertUnauthorized();
        Sanctum::actingAs($this->user('customer'));
        $this->getJson('/api/v1/customer/support')->assertOk();
        $this->getJson('/api/v1/admin/catalog')->assertForbidden();
        Sanctum::actingAs($this->user('admin'));
        $this->getJson('/api/v1/admin/catalog')->assertOk();
    }
}
