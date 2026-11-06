<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Exceptions\CheckoutException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Article;
use App\Models\Coupon;
use App\Models\CustomerAddress;
use App\Models\Product;
use App\Models\Challenge;
use App\Models\User;
use App\Models\UserChallenge;
use App\Models\CurrencyMarketListing;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Delivery;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Models\Favorite;
use App\Models\SystemSetting;
use App\Models\Notification as AppNotification;
use App\Services\CashService;
use App\Services\RoniEngine;

class CustomerController extends Controller
{
    /** Check stock against the combined quantity, including repeated product IDs. */
    private function combinedItems(Request $request): array
    {
        return collect($request->items)->groupBy('product_id')->map(fn ($rows, $id) => [
            'product_id' => (int) $id,
            'quantity' => (int) $rows->sum('quantity'),
        ])->sortKeys()->values()->all();
    }

    /**
     * Flat delivery fee, denominated in the same currency as `products.price_fiat`
     * so a quote never mixes units (the catalog is stored in fiat, not IQD).
     * Read from the `delivery_base_fee` system setting so an admin can change it
     * without a deploy; falls back to this default when the row is absent.
     */
    public const DELIVERY_FEE = 4.50;

    private static function deliveryFee(): float
    {
        $configured = SystemSetting::where('key', 'delivery_base_fee')->value('value');

        return is_numeric($configured) ? max(0, (float) $configured) : self::DELIVERY_FEE;
    }

    /**
     * Order numbers must be unique; a short random suffix plus a retry keeps
     * collisions from turning into a 500 on a busy shop.
     */
    private static function generateOrderNumber(): string
    {
        do {
            $number = 'ORD-' . now()->format('ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));
        } while (Order::where('order_number', $number)->exists());

        return $number;
    }
    public function home(Request $request)
    {
        $articles = Article::where('is_published', true)->latest()->take(5)->get();
        $featuredProducts = Product::with('store')->where('status', 'active')->where('is_featured', true)->get();
        $challenges = Challenge::take(4)->get();
        $marketSummary = [
            'rate' => 1.25,
            'change_24h' => '+4.2%',
            'volume_24h' => '18,450 TERRA',
        ];

        return response()->json([
            'status' => 'success',
            'data' => [
                'articles' => $articles,
                'featured_products' => $featuredProducts,
                'challenges' => $challenges,
                'market_summary' => $marketSummary,
            ],
        ]);
    }

    public function products(Request $request)
    {
        $query = Product::with(['store', 'category'])->where('status', 'active');
        if ($request->has('category')) {
            $query->whereHas('category', function ($q) use ($request) {
                $q->where('slug', $request->category);
            });
        }
        if ($request->has('gender') && !empty($request->gender)) {
            $query->where('gender', $request->gender);
        }
        return response()->json([
            'status' => 'success',
            'data' => $query->latest()->get(),
        ]);
    }

    /**
     * Single product for the detail screen. Only active products are visible;
     * an archived or missing product is a 404 rather than a blank page.
     */
    public function product(Request $request, $id)
    {
        $product = Product::with(['store', 'category'])
            ->where('status', 'active')
            ->find($id);

        if (!$product) {
            return response()->json(['status' => 'error', 'message' => 'Product not found.'], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $product,
            'product' => $product,
        ]);
    }

    public function articles(Request $request)
    {
        return response()->json([
            'status' => 'success',
            'data' => Article::where('is_published', true)->latest()->get(),
        ]);
    }

    public function currencyMarket(Request $request)
    {
        $listings = CurrencyMarketListing::with('user:id,name,role')->where('status', 'open')->latest()->get();
        return response()->json([
            'status' => 'success',
            'data' => [
                'current_rate' => 1.25,
                'change_24h' => '+4.2%',
                'volume_24h' => '18,450 TERRA',
                'order_book' => $listings,
            ],
        ]);
    }

    public function tradeCurrency(Request $request)
    {
        $request->validate([
            'type' => 'required|in:buy,sell',
            'amount' => 'required|numeric|min:1',
        ]);

        $user = $request->user();
        return DB::transaction(function () use ($request, $user) {
        User::whereKey($user->id)->lockForUpdate()->firstOrFail();
        $wallet = Wallet::firstOrCreate(['user_id' => $user->id]);
        $wallet = Wallet::whereKey($wallet->id)->lockForUpdate()->firstOrFail();
        $rate = 1.25;
        $totalFiat = $request->amount * $rate;

        if ($request->type === 'buy') {
            if ($wallet->fiat_balance < $totalFiat) {
                return response()->json(['status' => 'error', 'message' => 'Insufficient USD balance.'], 422);
            }
            $wallet->fiat_balance -= $totalFiat;
            $wallet->token_balance += $request->amount;
            $wallet->save();

            WalletTransaction::create([
                'wallet_id' => $wallet->id,
                'type' => 'credit',
                'currency' => 'TERRA',
                'amount' => $request->amount,
                'balance_after' => $wallet->token_balance,
                'reference_type' => 'market_trade',
                'description' => "Purchased {$request->amount} TERRA tokens for \${$totalFiat}",
            ]);
        } else {
            if ($wallet->token_balance < $request->amount) {
                return response()->json(['status' => 'error', 'message' => 'Insufficient TERRA balance.'], 422);
            }
            $wallet->token_balance -= $request->amount;
            $wallet->fiat_balance += $totalFiat;
            $wallet->save();

            WalletTransaction::create([
                'wallet_id' => $wallet->id,
                'type' => 'credit',
                'currency' => 'USD',
                'amount' => $totalFiat,
                'balance_after' => $wallet->fiat_balance,
                'reference_type' => 'market_trade',
                'description' => "Sold {$request->amount} TERRA tokens for \${$totalFiat}",
            ]);
        }

        return response()->json([
            'status' => 'success',
            'message' => "Successfully executed {$request->type} trade.",
            'wallet' => $wallet,
        ]);
        });
    }

    /**
     * Server-authoritative price quote for a cart.
     *
     * The client sends only product ids and quantities. Every price, discount
     * and delivery fee is computed here from the database, so a modified client
     * cannot change what is charged. Stock is validated at quote time so the
     * cart fails fast rather than at payment.
     */
    public function quote(Request $request)
    {
        $request->validate([
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer',
            'items.*.quantity' => 'required|integer|min:1|max:99',
            'coupon_code' => 'nullable|string|max:64',
        ]);

        $user = $request->user('sanctum') ?? $request->user();
        $lines = [];
        $subtotalFiat = 0.0;
        $subtotalTokens = 0.0;
        $errors = [];
        $storeIds = [];

        foreach ($this->combinedItems($request) as $row) {
            $product = Product::with('store')->find($row['product_id']);

            if (!$product || $product->status !== 'active') {
                $errors[] = "Product #{$row['product_id']} is no longer available.";
                continue;
            }

            $quantity = (int) $row['quantity'];
            if ($product->stock < $quantity) {
                $errors[] = "Only {$product->stock} left of {$product->name}.";
                continue;
            }

            $lineFiat = $product->sale_price_fiat * $quantity;
            $lineTokens = $product->sale_price_tokens * $quantity;

            $subtotalFiat += $lineFiat;
            $subtotalTokens += $lineTokens;
            $storeIds[$product->store_id] = true;

            $lines[] = [
                'product_id' => $product->id,
                'name' => $product->name,
                'image' => $product->image,
                'quantity' => $quantity,
                'unit_fiat' => $product->sale_price_fiat,
                'unit_tokens' => $product->sale_price_tokens,
                'total_fiat' => round($lineFiat, 2),
                'total_tokens' => round($lineTokens, 2),
                'stock' => $product->stock,
            ];
        }

        if ($lines === []) {
            return response()->json([
                'status' => 'error',
                'message' => 'None of the requested items are available.',
                'errors' => $errors,
            ], 422);
        }

        if (count($storeIds) > 1) {
            return response()->json(['status' => 'error', 'message' => 'Please place a separate order for each store.'], 422);
        }

        $coupon = null;
        $discount = 0.0;
        $couponError = null;

        if ($request->filled('coupon_code')) {
            $coupon = Coupon::whereRaw('upper(code) = ?', [strtoupper($request->coupon_code)])->first();

            if (!$coupon || !$coupon->isValid()) {
                $couponError = 'This coupon is invalid or has expired.';
                $coupon = null;
            } elseif ($subtotalFiat < $coupon->min_spend) {
                $couponError = "This coupon requires a minimum spend of {$coupon->min_spend}.";
                $coupon = null;
            } else {
                $discount = $coupon->discountFor($subtotalFiat);
            }
        }

        $freeShipping = $coupon && $coupon->coversDelivery();
        $deliveryFee = $freeShipping ? 0.0 : self::deliveryFee();
        $discount = min($discount, $subtotalFiat);
        $total = max(0.0, $subtotalFiat - $discount) + $deliveryFee;

        return response()->json([
            'status' => 'success',
            'data' => [
                'lines' => $lines,
                'store_ids' => array_map('intval', array_keys($storeIds)),
                'subtotal_fiat' => round($subtotalFiat, 2),
                'subtotal_tokens' => round($subtotalTokens, 2),
                'discount_amount' => round($discount, 2),
                'delivery_fee' => round($deliveryFee, 2),
                'total_fiat' => round($total, 2),
                'coupon' => $coupon ? ['code' => $coupon->code, 'type' => $coupon->type] : null,
                'coupon_error' => $couponError,
                'warnings' => $errors,
            ],
        ]);
    }

    /**
     * Server-authoritative checkout.
     *
     * Totals are recomputed from the database inside a transaction; any price
     * the client sends is ignored. Stock is decremented atomically with a
     * row-level guard so two simultaneous checkouts cannot oversell.
     */
    public function checkout(Request $request)
    {
        $request->validate([
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer',
            'items.*.quantity' => 'required|integer|min:1|max:99',
            'payment_method' => 'required|in:fiat,token,split,cash',
            'shipping_address' => 'required|string|max:1000',
            'phone' => 'nullable|string|max:32',
            'coupon_code' => 'nullable|string|max:64',
            'address_id' => 'nullable|integer|exists:customer_addresses,id',
        ]);

        $user = $request->user('sanctum') ?? $request->user();

        if ($request->filled('address_id')) {
            $address = CustomerAddress::where('user_id', $user->id)
                ->find($request->address_id);
            if (!$address) {
                return response()->json(['status' => 'error', 'message' => 'Address not found.'], 404);
            }
        }

        try {
            $order = DB::transaction(function () use ($request, $user) {
                $subtotalFiat = 0.0;
                $subtotalTokens = 0.0;
                $storeId = null;
                $prepared = [];
                $firstProduct = null;

                foreach ($this->combinedItems($request) as $row) {
                    $product = Product::with('store')->lockForUpdate()->find($row['product_id']);

                    if (!$product || $product->status !== 'active') {
                        throw new CheckoutException("Product #{$row['product_id']} is no longer available.");
                    }

                    if ($storeId !== null && $storeId !== $product->store_id) {
                        throw new CheckoutException('Please place a separate order for each store.');
                    }
                    $quantity = (int) $row['quantity'];
                    if ($product->stock < $quantity) {
                        throw new CheckoutException("Only {$product->stock} left of {$product->name}.");
                    }

                    $prepared[] = compact('product', 'quantity');
                    $subtotalFiat += $product->sale_price_fiat * $quantity;
                    $subtotalTokens += $product->sale_price_tokens * $quantity;
                    $storeId ??= $product->store_id;
                    $firstProduct ??= $product;
                }

                $coupon = null;
                if ($request->filled('coupon_code')) {
                    $candidate = Coupon::whereRaw('upper(code) = ?', [strtoupper($request->coupon_code)])->first();
                    if ($candidate && $candidate->isValid() && $subtotalFiat >= $candidate->min_spend) {
                        $coupon = $candidate;
                    }
                }

                $discount = $coupon ? $coupon->discountFor($subtotalFiat) : 0.0;
                $discount = min($discount, $subtotalFiat);
                $deliveryFee = ($coupon && $coupon->coversDelivery()) ? 0.0 : self::deliveryFee();
                $total = max(0.0, $subtotalFiat - $discount) + $deliveryFee;

                // Freeze what this order will eventually earn and give. Nothing
                // is granted here: the amounts are only committed once the
                // order is delivered and the cash is recorded, and a refund
                // reverses exactly these figures.
                $roniSettings = RoniEngine::settings();
                $membership = RoniEngine::membership($user->id);
                $bonusBps = (int) ($membership->bonus_bps ?? 0);
                $ronixPending = 0;
                $givesPending = 0;

                foreach ($prepared as ['product' => $product, 'quantity' => $quantity]) {
                    $ronixPending += (int) $product->ronix_reward * $quantity;
                    $givesPending += (int) $product->eligible_profit_minor * $quantity;
                }

                // RONI Plus pays for itself in extra points on what was already
                // bought, never as a discount on the order itself.
                $ronixPending = (int) round($ronixPending * (1 + $bonusBps / 10000));
                // Charity is a share of RONI's eligible profit, not of the
                // customer's money.
                $givesPending = (int) round($givesPending * ((int) $roniSettings['charity_bps'] / 10000));

                $order = Order::create([
                    'order_number' => self::generateOrderNumber(),
                    'customer_id' => $user->id,
                    'store_id' => $storeId,
                    'coupon_id' => $coupon?->id,
                    'discount_amount' => $discount,
                    'delivery_fee' => $deliveryFee,
                    'total_fiat' => $total,
                    'total_tokens' => $subtotalTokens,
                    'payment_method' => $request->payment_method,
                    'shipping_address' => $request->shipping_address,
                    'status' => 'pending',
                    'ronix_pending' => $ronixPending,
                    'gives_pending_minor' => $givesPending,
                    'roni_status' => 'pending',
                ]);

                foreach ($prepared as ['product' => $product, 'quantity' => $quantity]) {
                    OrderItem::create([
                        'order_id' => $order->id,
                        'product_id' => $product->id,
                        'quantity' => $quantity,
                        'unit_fiat' => $product->sale_price_fiat,
                        'unit_tokens' => $product->sale_price_tokens,
                        'total_fiat' => $product->sale_price_fiat * $quantity,
                    ]);

                    $product->decrement('stock', $quantity);
                }

                $delivery = Delivery::create([
                    'order_id' => $order->id,
                    'status' => 'ready_for_pickup',
                    'pickup_store_name' => $firstProduct?->store?->name ?? 'Store',
                    'pickup_address' => $firstProduct?->store?->tagline ?? 'Main store',
                    'customer_name' => $user->name,
                    'dropoff_address' => $request->shipping_address,
                    // Freeze the cash the courier must collect now, while the
                    // price is still known-good.
                    'amount_due' => $total,
                    // `estimated_payout` is a legacy display string and is
                    // hidden on the model, so no screen can show it as money.
                    'courier_payout' => CashService::courierPayoutFor($total),
                ]);

                return $order;
            });
        } catch (CheckoutException $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 422);
        }

        // Tell the customer their order landed, and the seller there is work to
        // do. Both are ordinary rows the clients poll for.
        $order->loadMissing('items');

        AppNotification::send(
            $user->id,
            'order',
            'Order received',
            "Order {$order->order_number} was placed and is being prepared.",
            'Track order',
            '/order-tracking',
            ['orderId' => $order->order_number],
        );

        $store = $order->store;
        if ($store?->user_id) {
            AppNotification::send(
                $store->user_id,
                'order',
                'New order to prepare',
                "{$user->name} placed order {$order->order_number}.",
                'Open orders',
                '/orders',
                null,
            );
        }

        // A courier job now exists, so tell the active couriers there is
        // something to collect.
        $courierIds = User::where('role', 'delivery')
            ->where('status', 'active')
            ->pluck('id');

        foreach ($courierIds as $courierId) {
            AppNotification::send(
                (int) $courierId,
                'order',
                'New delivery available',
                "Order {$order->order_number} is ready for pickup at "
                    .($store?->name ?? 'the store').'.',
                'Open tasks',
                '/',
                null,
            );
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Order placed successfully.',
            'order' => $order->load(['items.product', 'delivery', 'coupon', 'store']),
        ], 201);
    }

    /**
     * Withdraw an order that has not been handed to a courier yet. Stock is
     * returned and any coupon discount is simply dropped with the order.
     */
    public function cancelOrder(Request $request, $id)
    {
        $user = $request->user('sanctum') ?? $request->user();
        $order = Order::with('items')->where('customer_id', $user->id)->find($id);

        if (!$order) {
            return response()->json(['status' => 'error', 'message' => 'Order not found.'], 404);
        }

        if (!$order->isCancellable()) {
            return response()->json([
                'status' => 'error',
                'message' => "An order that is already {$order->status} cannot be cancelled.",
            ], 422);
        }

        DB::transaction(function () use ($order, $request) {
            $order = Order::with('items')->lockForUpdate()->findOrFail($order->id);
            abort_unless($order->isCancellable(), 422, 'This order can no longer be cancelled.');
            foreach ($order->items as $item) {
                $item->product?->increment('stock', $item->quantity);
            }

            $order->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
                'cancel_reason' => $request->input('reason'),
            ]);

            $order->delivery?->update(['status' => 'cancelled']);

            // The seller needs to know the order is off their list.
            $store = $order->store;
            if ($store?->user_id) {
                AppNotification::send(
                    $store->user_id,
                    'order',
                    'Order cancelled',
                    "Order {$order->order_number} was cancelled by the customer.",
                    'Open orders',
                    '/orders',
                    null,
                );
            }
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Order cancelled.',
            'order' => $order->fresh(),
        ]);
    }

    /**
     * Ask for a refund on an order that was delivered or failed to deliver.
     *
     * The seller approves it from their side; this endpoint records the
     * customer's intent and surfaces the amount that would be returned so the
     * UI can show it before the seller acts.
     */
    public function refundPreview(Request $request, $id)
    {
        $user = $request->user('sanctum') ?? $request->user();
        $order = Order::with('delivery')->where('customer_id', $user->id)->find($id);

        if (!$order) {
            return response()->json(['status' => 'error', 'message' => 'Order not found.'], 404);
        }

        if (!$order->isRefundable()) {
            return response()->json([
                'status' => 'error',
                'message' => "An order that is {$order->status} cannot be refunded.",
            ], 422);
        }

        $collected = $order->delivery?->cash_collected;
        $refundable = $collected ?? $order->total_fiat;

        return response()->json([
            'status' => 'success',
            'data' => [
                'order_number' => $order->order_number,
                'order_status' => $order->status,
                'refundable_amount' => round($refundable, 2),
                'cash_recorded' => $collected !== null,
                'delivered' => $order->status === 'delivered',
            ],
        ]);
    }

    public function addresses(Request $request)
    {
        $user = $request->user('sanctum') ?? $request->user();
        return response()->json([
            'status' => 'success',
            'data' => CustomerAddress::where('user_id', $user->id)
                ->orderByDesc('is_default')
                ->latest()
                ->get(),
        ]);
    }

    public function storeAddress(Request $request)
    {
        $user = $request->user('sanctum') ?? $request->user();
        $validated = $request->validate([
            'label' => 'nullable|string|max:64',
            'address' => 'required|string|max:1000',
            'phone' => 'required|string|max:32',
            'is_default' => 'nullable|boolean',
        ]);

        $address = DB::transaction(function () use ($user, $validated) {
            $isFirst = !CustomerAddress::where('user_id', $user->id)->exists();
            $makeDefault = (bool) ($validated['is_default'] ?? false) || $isFirst;

            if ($makeDefault) {
                CustomerAddress::where('user_id', $user->id)->update(['is_default' => false]);
            }

            return CustomerAddress::create([
                'user_id' => $user->id,
                'label' => $validated['label'] ?? 'home',
                'address' => $validated['address'],
                'phone' => $validated['phone'],
                'is_default' => $makeDefault,
            ]);
        });

        return response()->json(['status' => 'success', 'address' => $address], 201);
    }

    public function updateAddress(Request $request, $id)
    {
        $user = $request->user('sanctum') ?? $request->user();
        $address = CustomerAddress::where('user_id', $user->id)->find($id);

        if (!$address) {
            return response()->json(['status' => 'error', 'message' => 'Address not found.'], 404);
        }

        $validated = $request->validate([
            'label' => 'sometimes|required|string|max:64',
            'address' => 'sometimes|required|string|max:1000',
            'phone' => 'sometimes|required|string|max:32',
            'is_default' => 'sometimes|boolean',
        ]);

        DB::transaction(function () use ($address, $user, $validated) {
            if (!empty($validated['is_default'])) {
                CustomerAddress::where('user_id', $user->id)->update(['is_default' => false]);
            }
            $address->update($validated);
        });

        return response()->json(['status' => 'success', 'address' => $address->fresh()]);
    }

    public function destroyAddress(Request $request, $id)
    {
        $user = $request->user('sanctum') ?? $request->user();
        $address = CustomerAddress::where('user_id', $user->id)->find($id);

        if (!$address) {
            return response()->json(['status' => 'error', 'message' => 'Address not found.'], 404);
        }

        $wasDefault = $address->is_default;
        $address->delete();

        // Promote another address to default so checkout always has a choice.
        if ($wasDefault) {
            CustomerAddress::where('user_id', $user->id)
                ->latest()
                ->first()
                ?->update(['is_default' => true]);
        }

        return response()->json(['status' => 'success', 'message' => 'Address removed.']);
    }

    /** Coupons the customer may currently apply, for the offers sheet. */
    public function coupons(Request $request)
    {
        $coupons = Coupon::where('is_active', true)
            ->where(fn ($q) => $q->whereNull('expires_at')->orWhere('expires_at', '>', now()))
            ->orderBy('min_spend')
            ->get();

        return response()->json(['status' => 'success', 'data' => $coupons]);
    }

    public function orders(Request $request)
    {
        $orders = Order::with(['items.product', 'store', 'delivery', 'coupon'])
            ->where('customer_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $orders,
        ]);
    }

    public function order(Request $request, $id)
    {
        $order = Order::with(['items.product', 'store', 'delivery', 'coupon'])
            ->where('customer_id', $request->user()->id)
            ->find($id);

        if (!$order) {
            return response()->json(['status' => 'error', 'message' => 'Order not found.'], 404);
        }

        return response()->json(['status' => 'success', 'order' => $order]);
    }

    public function favorites(Request $request)
    {
        $favorites = Favorite::with('product.store', 'product.category')
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $favorites->pluck('product'),
        ]);
    }

    public function toggleFavorite(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
        ]);

        $user = $request->user();
        $favorite = Favorite::where('user_id', $user->id)
            ->where('product_id', $request->product_id)
            ->first();

        if ($favorite) {
            $favorite->delete();
            return response()->json([
                'status' => 'success',
                'message' => 'Removed from favorites.',
                'action' => 'removed'
            ]);
        } else {
            Favorite::create([
                'user_id' => $user->id,
                'product_id' => $request->product_id,
            ]);
            return response()->json([
                'status' => 'success',
                'message' => 'Added to favorites.',
                'action' => 'added'
            ]);
        }
    }

    public function updateProfile(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email,' . $request->user()->id,
            'default_shipping_address' => 'nullable|string|max:1000',
        ]);

        $user = $request->user();
        $user->name = $request->name;
        $user->email = $request->email;
        // The default_shipping_address column doesn't exist on User table by default, 
        // we can save it in a user_profiles table or just skip it if it's not in the User model.
        // For now, since the schema has no address, we skip or add it.
        // Let's assume we just update name and email for the basic profile.
        $user->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Profile updated successfully.',
            'user' => $user,
        ]);
    }
}
