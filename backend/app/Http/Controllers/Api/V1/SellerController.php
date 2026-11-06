<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Store;
use App\Models\Product;
use App\Models\Order;
use App\Models\Notification;
use App\Models\Settlement;
use App\Services\CashService;
use App\Services\ProductMediaService;
use App\Exceptions\CheckoutException;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

class SellerController extends Controller
{
    private function resolveStore(Request $request): ?Store
    {
        return $request->user()?->store;
    }

    public function dashboard(Request $request)
    {
        $store = $this->resolveStore($request);
        if (!$store) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'store' => null,
                    'kpis' => [
                        'gross_sales' => '0.00',
                        'token_earnings' => '0.0 TERRA',
                        'orders_count' => 0,
                        'rating' => '0.00',
                        'cash_collected' => '0.00',
                        'cash_outstanding' => '0.00',
                    ],
                    'recent_orders' => [],
                ],
            ]);
        }

        $recentOrders = Order::with(['items.product', 'customer'])
            ->where('store_id', $store->id)
            ->latest()
            ->take(10)
            ->get();

        // Real totals only. These used to fall back to invented demo figures
        // ($4,820 / 1,240 TERRA / 48 orders) whenever the real value was zero,
        // which made an empty store look like it had made thousands. With
        // cash on delivery this screen is the seller's only record, so it has
        // to be truthful.
        $orders = $store->orders();
        $grossSales = round((float) $orders->sum('total_fiat'), 2);
        $tokenEarnings = round((float) $orders->sum('total_tokens'), 1);
        $ordersCount = $orders->count();

        // Cash the couriers are currently holding for this store, and what has
        // already been handed over.
        $settlements = Settlement::where('store_id', $store->id)->get();
        $cashCollected = round((float) $settlements->sum('gross_cash'), 2);
        $cashOutstanding = round(
            $settlements->where('status', 'pending')
                ->sum(fn ($s) => $s->outstanding()),
            2,
        );

        return response()->json([
            'status' => 'success',
            'data' => [
                'store' => $store,
                'kpis' => [
                    'gross_sales' => number_format($grossSales, 2),
                    'token_earnings' => number_format($tokenEarnings, 1) . ' TERRA',
                    'orders_count' => $ordersCount,
                    'rating' => number_format((float) $store->rating, 2),
                    'cash_collected' => number_format($cashCollected, 2),
                    'cash_outstanding' => number_format($cashOutstanding, 2),
                ],
                'recent_orders' => $recentOrders,
            ],
        ]);
    }

    /**
     * What each courier is holding for this store, newest first.
     */
    public function settlements(Request $request)
    {
        $store = $this->resolveStore($request);

        if (!$store) {
            return response()->json(['status' => 'success', 'data' => []]);
        }

        $rows = Settlement::with('courier:id,name')
            ->where('store_id', $store->id)
            ->latest()
            ->get()
            ->map(fn (Settlement $settlement) => [
                'id' => $settlement->id,
                'courier_id' => $settlement->courier_id,
                'courier_name' => $settlement->courier?->name,
                'gross_cash' => $settlement->gross_cash,
                'courier_commission' => $settlement->courier_commission,
                'net_to_store' => $settlement->net_to_store,
                'refunded_cash' => $settlement->refunded_cash,
                'outstanding' => $settlement->outstanding(),
                'refund_surplus' => $settlement->refundSurplus(),
                'status' => $settlement->status,
                'settled_at' => $settlement->settled_at,
                'deliveries_count' => $settlement->deliveries()->count(),
            ]);

        return response()->json(['status' => 'success', 'data' => $rows]);
    }

    /**
     * Confirm a courier handed over the cash they were holding.
     */
    public function settle(Request $request, $id)
    {
        $request->validate(['notes' => 'nullable|string|max:1000']);

        $store = $this->resolveStore($request);
        $settlement = Settlement::findOrFail($id);

        if (!$store || $settlement->store_id !== $store->id) {
            return response()->json(['status' => 'error', 'message' => 'Settlement not found.'], 404);
        }

        if ($settlement->status !== 'pending') {
            return response()->json([
                'status' => 'error',
                'message' => "This settlement is already {$settlement->status}.",
            ], 422);
        }

        if ($settlement->hasRefundSurplus()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Refunds of ' . number_format($settlement->refundSurplus(), 2)
                    . ' exceed the cash this courier collected. Reconcile before settling.',
            ], 422);
        }

        if ($settlement->outstanding() > 0.009 && !$request->boolean('accept_shortfall')) {
            return response()->json([
                'status' => 'error',
                'message' => 'The courier still holds '
                    .number_format($settlement->outstanding(), 2)
                    . '. Record their handover, or pass accept_shortfall=true if the'
                    . ' difference was already accounted for.',
            ], 422);
        }

        $outstanding = $settlement->outstanding();

        $settlement->update([
            'status' => 'paid',
            'settled_at' => now(),
            'notes' => trim(($request->input('notes') ?? '')
                . ($outstanding > 0.009
                    ? ' Settled short by ' . number_format($outstanding, 2) . '.'
                    : '')),
        ]);

        Notification::send(
            $settlement->courier_id,
            'system',
            'Settlement paid',
            'Your balance of ' . number_format($settlement->courier_commission, 2)
                . ' commission has been settled with the store.',
            null,
            null,
            null,
        );

        return response()->json(['status' => 'success', 'settlement' => $settlement->fresh()]);
    }

    /**
     * Refund an order. Restores stock and takes the cash back off the courier's
     * balance when they are still holding it.
     */
    public function refundOrder(Request $request, $id)
    {
        $store = $this->resolveStore($request);
        $order = Order::with(['delivery', 'items', 'store'])->find($id);

        if (!$order) {
            return response()->json(['status' => 'error', 'message' => 'Order not found.'], 404);
        }

        if (!$store || $order->store_id !== $store->id) {
            return response()->json(['status' => 'error', 'message' => 'Order not found.'], 404);
        }

        $data = $request->validate([
            // Omit `amount` to refund everything that was collected. Sending an
            // explicit 0 means "refund nothing", which CashService rejects.
            'amount' => 'nullable|numeric|min:0',
            'reason' => 'nullable|string|max:500',
        ]);

        $collected = $order->delivery?->cash_collected;
        $default = $collected ?? $order->total_fiat;
        $amount = $data['amount'] ?? $default;

        try {
            $refunded = CashService::refundOrder($order, (float) $amount, $data['reason'] ?? null);
        } catch (CheckoutException $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 422);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Order refunded.',
            'order' => $refunded,
        ]);
    }

    public function updateStore(Request $request)
    {
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'tagline' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:10000',
            'craft_category' => 'nullable|string|max:255',
        ]);
        $user = $request->user('sanctum') ?? $request->user();
        $store = $this->resolveStore($request);
        if (!$store) {
            $store = Store::create([
                'user_id' => $user->id,
                'name' => $request->name ?? 'Artisan Studio',
                'slug' => Str::slug($request->name ?? 'Artisan Studio') . '-' . Str::uuid(),
            ]);
        }

        $store->update($request->only(['name', 'tagline', 'description', 'craft_category']));
        return response()->json(['status' => 'success', 'store' => $store]);
    }

    public function products(Request $request)
    {
        $store = $this->resolveStore($request);
        return response()->json([
            'status' => 'success',
            'data' => $store ? Product::where('store_id', $store->id)->latest()->get() : [],
        ]);
    }

    /**
     * Single product for the edit screen. Scoped to the seller's own store so
     * one seller cannot read or modify another seller's listing.
     */
    public function product(Request $request, $id)
    {
        $store = $this->resolveStore($request);
        $product = Product::with(['store', 'category'])->find($id);

        if (!$product) {
            return response()->json(['status' => 'error', 'message' => 'Product not found.'], 404);
        }

        if (!$store || $product->store_id !== $store->id) {
            return response()->json(['status' => 'error', 'message' => 'Product not found.'], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $product,
            'product' => $product,
        ]);
    }

    public function saveProduct(Request $request)
    {
        // Empty strings from mobile clients must become null before `url` rules.
        $request->merge([
            'image' => filled($request->input('image')) ? $request->input('image') : null,
            'video' => filled($request->input('video')) ? $request->input('video') : null,
            'description' => filled($request->input('description')) ? $request->input('description') : null,
            'material_provenance' => filled($request->input('material_provenance'))
                ? $request->input('material_provenance')
                : null,
            'category_id' => filled($request->input('category_id')) ? $request->input('category_id') : null,
            'gender' => filled($request->input('gender')) ? $request->input('gender') : 'unisex',
        ]);

        $request->validate([
            'name' => 'required|string|max:255',
            'price_fiat' => 'required|numeric|min:0|max:9999999',
            'price_tokens' => 'nullable|numeric|min:0|max:9999999',
            'stock' => 'nullable|integer|min:0|max:1000000',
            'image' => 'nullable|string|max:2048',
            'video' => 'nullable|string|max:2048',
            'gallery' => 'nullable|array|max:' . ProductMediaService::MAX_IMAGES,
            'gallery.*' => 'nullable|string|max:2048',
            'images' => 'nullable|array|max:' . ProductMediaService::MAX_IMAGES,
            'images.*' => 'nullable|file|image|max:8192',
            'video_file' => 'nullable|file|mimetypes:video/mp4,video/quicktime,video/webm,video/x-m4v|max:40960',
            'description' => 'nullable|string|max:10000',
            'material_provenance' => 'nullable|string|max:1000',
            'category_id' => 'nullable|exists:categories,id',
            'gender' => 'nullable|in:unisex,male,female',
            'status' => 'nullable|in:active,draft,archived',
        ]);
        $user = $request->user('sanctum') ?? $request->user();
        $store = $this->resolveStore($request);
        if (!$store) {
            $store = Store::create([
                'user_id' => $user->id,
                'name' => 'Artisan Studio',
                'slug' => 'artisan-studio-' . Str::uuid(),
            ]);
        }

        $media = $this->resolveProductMedia($request);

        $product = Product::create([
            'store_id' => $store->id,
            'category_id' => $request->category_id,
            'name' => $request->name,
            'slug' => Str::slug($request->name) . '-' . Str::uuid(),
            'price_fiat' => $request->price_fiat,
            'price_tokens' => $request->price_tokens ?? ($request->price_fiat * 0.8),
            'stock' => $request->stock ?? 10,
            'image' => $media['image']
                ?? 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=700&q=80',
            'gallery' => $media['gallery'],
            'video' => $media['video'],
            'material_provenance' => $request->material_provenance ?? 'Certified sustainable artisan origin',
            'description' => $request->description ?? 'Masterwork crafted with artisanal care.',
            'gender' => $request->gender ?? 'unisex',
            'status' => $request->status ?? 'active',
        ]);

        return response()->json(['status' => 'success', 'product' => $product]);
    }

    /**
     * Update an existing listing. Price changes re-derive the token price so the
     * two never drift apart, and the slug is only regenerated from the name.
     */
    public function updateProduct(Request $request, $id)
    {
        $store = $this->resolveStore($request);
        $product = Product::find($id);

        if (!$product) {
            return response()->json(['status' => 'error', 'message' => 'Product not found.'], 404);
        }

        if (!$store || $product->store_id !== $store->id) {
            return response()->json(['status' => 'error', 'message' => 'Product not found.'], 404);
        }

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'price_fiat' => 'sometimes|required|numeric|min:0',
            'price_tokens' => 'sometimes|nullable|numeric|min:0',
            'stock' => 'sometimes|required|integer|min:0',
            'description' => 'sometimes|nullable|string',
            'image' => 'sometimes|nullable|string|max:2048',
            'video' => 'sometimes|nullable|string|max:2048',
            'gallery' => 'sometimes|nullable|array|max:' . ProductMediaService::MAX_IMAGES,
            'gallery.*' => 'nullable|string|max:2048',
            'images' => 'nullable|array|max:' . ProductMediaService::MAX_IMAGES,
            'images.*' => 'nullable|file|image|max:8192',
            'video_file' => 'nullable|file|mimetypes:video/mp4,video/quicktime,video/webm,video/x-m4v|max:40960',
            'clear_video' => 'sometimes|boolean',
            'material_provenance' => 'sometimes|nullable|string',
            'category_id' => 'sometimes|nullable|exists:categories,id',
            'status' => 'sometimes|in:active,draft,archived',
            'is_featured' => 'sometimes|boolean',
            'gender' => 'sometimes|nullable|in:unisex,male,female',
        ]);

        if (array_key_exists('price_fiat', $validated) && !array_key_exists('price_tokens', $validated)) {
            $validated['price_tokens'] = $validated['price_fiat'] * 0.8;
        }

        if (!empty($validated['name'])) {
            $validated['slug'] = Str::slug($validated['name']) . '-' . $product->id;
        }

        $media = $this->resolveProductMedia(
            $request,
            existingGallery: is_array($product->gallery) ? $product->gallery : [],
            existingImage: $product->getAttributes()['image'] ?? null,
            existingVideo: $product->getAttributes()['video'] ?? null,
        );

        $validated['image'] = $media['image'] ?? ($validated['image'] ?? $product->getAttributes()['image']);
        $validated['gallery'] = $media['gallery'];
        if ($request->boolean('clear_video')) {
            $validated['video'] = null;
        } elseif ($media['video'] !== null) {
            $validated['video'] = $media['video'];
        }

        unset($validated['images'], $validated['video_file'], $validated['clear_video']);

        $product->update($validated);

        return response()->json([
            'status' => 'success',
            'message' => 'Product updated.',
            'product' => $product->fresh(),
        ]);
    }

    /**
     * Merge uploaded files + URL gallery into image / gallery / video paths.
     *
     * @param  list<string>  $existingGallery
     * @return array{image: ?string, gallery: list<string>, video: ?string}
     */
    private function resolveProductMedia(
        Request $request,
        array $existingGallery = [],
        ?string $existingImage = null,
        ?string $existingVideo = null,
    ): array {
        $gallery = [];

        // Keep URLs the seller already had (edit screen sends remaining ones).
        $incomingUrls = $request->input('gallery');
        if (is_string($incomingUrls)) {
            $decoded = json_decode($incomingUrls, true);
            $incomingUrls = is_array($decoded) ? $decoded : [];
        }
        if (is_array($incomingUrls)) {
            foreach ($incomingUrls as $url) {
                if (is_string($url) && trim($url) !== '') {
                    $gallery[] = trim($url);
                }
            }
        } elseif ($existingGallery !== []) {
            $gallery = $existingGallery;
        }

        if ($request->hasFile('images')) {
            foreach ((array) $request->file('images') as $file) {
                if ($file && $file->isValid()) {
                    $gallery[] = ProductMediaService::storeImage($file);
                }
            }
        }

        $gallery = array_values(array_unique(array_slice($gallery, 0, ProductMediaService::MAX_IMAGES)));

        $cover = filled($request->input('image'))
            ? (string) $request->input('image')
            : ($gallery[0] ?? $existingImage);

        $video = $existingVideo;
        if ($request->hasFile('video_file') && $request->file('video_file')->isValid()) {
            $video = ProductMediaService::storeVideo($request->file('video_file'));
        } elseif (filled($request->input('video'))) {
            $video = (string) $request->input('video');
        }

        return [
            'image' => $cover,
            'gallery' => $gallery,
            'video' => $video,
        ];
    }

    /**
     * Soft-archive a listing. Orders keep their order items, so historical
     * orders stay readable; the product simply leaves the active catalog.
     */
    public function destroyProduct(Request $request, $id)
    {
        $store = $this->resolveStore($request);
        $product = Product::find($id);

        if (!$product) {
            return response()->json(['status' => 'error', 'message' => 'Product not found.'], 404);
        }

        if (!$store || $product->store_id !== $store->id) {
            return response()->json(['status' => 'error', 'message' => 'Product not found.'], 404);
        }

        $product->update(['status' => 'archived', 'stock' => 0]);

        return response()->json([
            'status' => 'success',
            'message' => 'Listing removed.',
            'product' => $product->fresh(),
        ]);
    }

    /**
     * Orders for the seller's store, newest first, with an optional status
     * filter so the orders screen can show a single column at a time.
     */
    public function orders(Request $request)
    {
        $store = $this->resolveStore($request);

        if (!$store) {
            return response()->json(['status' => 'success', 'data' => []]);
        }

        $query = Order::with(['items.product', 'customer', 'delivery'])
            ->where('store_id', $store->id)
            ->latest();

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        return response()->json([
            'status' => 'success',
            'data' => $query->get(),
        ]);
    }

    /**
     * A single order with its items and courier task, scoped to this store.
     */
    public function order(Request $request, $id)
    {
        $store = $this->resolveStore($request);
        $order = Order::with(['items.product', 'customer', 'delivery', 'store'])
            ->find($id);

        if (!$order) {
            return response()->json(['status' => 'error', 'message' => 'Order not found.'], 404);
        }

        if (!$store || $order->store_id !== $store->id) {
            return response()->json(['status' => 'error', 'message' => 'Order not found.'], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $order,
            'order' => $order,
        ]);
    }

    public function updateOrderStatus(Request $request, $orderId)
    {
        $request->validate([
            'status' => 'required|string|in:preparing,ready_for_pickup,cancelled',
        ]);

        return DB::transaction(function () use ($request, $orderId) {
            $store = $this->resolveStore($request);
            abort_unless($store, 404);
            $order = Order::where('store_id', $store->id)->lockForUpdate()->findOrFail($orderId);
            $transitions = [
                'pending' => ['preparing', 'ready_for_pickup', 'cancelled'],
                'preparing' => ['ready_for_pickup', 'cancelled'],
                'ready_for_pickup' => ['cancelled'],
            ];
            abort_unless(in_array($request->status, $transitions[$order->status] ?? [], true),
                422, 'This order cannot move to the requested status.');

            if ($request->status === 'cancelled') {
                foreach ($order->items as $item) {
                    $item->product?->increment('stock', $item->quantity);
                }
                $order->cancelled_at = now();
            }
            $order->status = $request->status;
            $order->save();
            $order->delivery?->update(['status' => $request->status]);

            Notification::send(
                $order->customer_id, 'order',
                "Order {$order->order_number} is now ".str_replace('_', ' ', $request->status),
                'Your order status changed to '.str_replace('_', ' ', $request->status).'.',
                'Track order', '/order-tracking', ['orderId' => $order->order_number],
            );
            return response()->json(['status' => 'success', 'order' => $order->fresh()]);
        });
    }
}
