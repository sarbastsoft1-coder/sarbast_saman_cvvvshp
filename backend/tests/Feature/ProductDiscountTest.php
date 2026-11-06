<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProductDiscountTest extends TestCase
{
    use RefreshDatabase;

    public function test_permissions_validation_removal_and_checkout_prices(): void
    {
        $seller = User::factory()->create(['role' => 'seller', 'status' => 'active']);
        $other = User::factory()->create(['role' => 'seller', 'status' => 'active']);
        $admin = User::factory()->create(['role' => 'admin', 'status' => 'active']);
        $customer = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $store = Store::create(['user_id' => $seller->id, 'name' => 'Studio', 'slug' => 'studio']);
        $product = Product::create(['store_id' => $store->id, 'name' => 'Bag', 'slug' => 'bag', 'price_fiat' => 99.99, 'price_tokens' => 80]);
        $url = "/api/v1/product-discounts/{$product->id}";
        $this->postJson($url, ['discount_percent' => 20])->assertUnauthorized();
        Sanctum::actingAs($customer);
        $this->postJson($url, ['discount_percent' => 20])->assertForbidden();
        Sanctum::actingAs($other);
        $this->getJson('/api/v1/product-discounts')->assertJsonCount(0, 'data');
        $this->postJson($url, ['discount_percent' => 20])->assertNotFound();
        Sanctum::actingAs($seller);
        $this->getJson('/api/v1/product-discounts')->assertJsonCount(1, 'data');
        foreach ([-1, 100, 2.5, 'bad'] as $invalid) {
            $this->postJson($url, ['discount_percent' => $invalid])->assertUnprocessable();
        }
        $this->postJson($url, ['discount_percent' => 20])->assertOk()->assertJsonPath('data.sale_price_fiat', 79.99);
        $this->assertEquals(99.99, $product->fresh()->price_fiat);
        $this->getJson('/api/v1/customer/products')->assertJsonPath('data.0.discount_percent', 20);
        Sanctum::actingAs($admin);
        $this->postJson($url, ['discount_percent' => 25])->assertOk();
        Sanctum::actingAs($customer);
        $this->postJson('/api/v1/customer/checkout', ['items' => [['product_id' => $product->id, 'quantity' => 2]], 'payment_method' => 'fiat', 'shipping_address' => 'Test address', 'price_fiat' => 1])
            ->assertCreated()->assertJsonPath('order.total_fiat', 154.48)->assertJsonPath('order.total_tokens', 120);
        $this->assertDatabaseHas('order_items', ['product_id' => $product->id, 'unit_fiat' => 74.99, 'unit_tokens' => 60]);
        Sanctum::actingAs($admin);
        $this->postJson($url, ['discount_percent' => 0])->assertOk()->assertJsonPath('data.sale_price_fiat', 99.99);
        $admin->update(['status' => 'suspended']);
        $this->postJson($url, ['discount_percent' => 10])->assertForbidden();
    }
}
