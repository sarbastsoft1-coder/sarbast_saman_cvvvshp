<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Coupon;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminCatalogController extends Controller
{
    private function admin(Request $request): void
    {
        abort_unless($request->user()?->role === 'admin' && $request->user()?->status === 'active', 403);
    }

    public function index(Request $request)
    {
        $this->admin($request);
        return response()->json(['status' => 'success', 'data' => [
            'products' => Product::with('store:id,name', 'category:id,name')->latest()->get(),
            'categories' => Category::withCount('products')->orderBy('name')->get(),
            'stores' => Store::with('user:id,name,email')->latest()->get(),
            'banners' => DB::table('marketplace_banners')->orderBy('position')->get(),
            'coupons' => Coupon::latest()->get(),
            'orders' => Order::with('customer:id,name,email', 'store:id,name', 'delivery', 'items.product:id,name')->latest()->limit(200)->get(),
        ]]);
    }

    public function product(Request $request)
    {
        $this->admin($request);
        $data = $request->validate([
            'id' => 'nullable|integer|exists:products,id', 'store_id' => 'required|integer|exists:stores,id',
            'category_id' => 'nullable|integer|exists:categories,id', 'name' => 'required|string|max:180',
            'description' => 'nullable|string|max:10000', 'price_fiat' => 'required|numeric|min:0|max:9999999',
            'price_tokens' => 'nullable|numeric|min:0|max:9999999', 'stock' => 'required|integer|min:0|max:1000000',
            'discount_percent' => 'required|integer|min:0|max:99', 'image' => 'nullable|url:http,https|max:2048',
            'gallery' => 'nullable|array|max:15', 'gallery.*' => 'url:http,https|max:2048',
            'status' => 'required|in:active,draft,archived', 'is_featured' => 'required|boolean',
        ]);
        return DB::transaction(function () use ($request, $data) {
            $product = isset($data['id']) ? Product::findOrFail($data['id']) : new Product();
            unset($data['id']);
            if (!$product->exists) {
                $data['slug'] = Str::slug($data['name']).'-'.Str::lower(Str::random(8));
                $data['price_tokens'] = $data['price_tokens'] ?? 0;
            }
            $product->fill($data)->save();
            $this->audit($request, 'catalog.product.saved', 'product', $product->id, $data);
            return response()->json(['status' => 'success', 'data' => $product]);
        });
    }

    public function category(Request $request)
    {
        $this->admin($request);
        $data = $request->validate([
            'id' => 'nullable|integer|exists:categories,id', 'name' => 'required|string|max:120',
            'slug' => ['required', 'alpha_dash', 'max:120', Rule::unique('categories')->ignore($request->integer('id'))],
            'description' => 'nullable|string|max:2000', 'icon' => 'nullable|string|max:40',
        ]);
        return DB::transaction(function () use ($request, $data) {
            $category = isset($data['id']) ? Category::findOrFail($data['id']) : new Category();
            unset($data['id']);
            $category->fill($data)->save();
            $this->audit($request, 'catalog.category.saved', 'category', $category->id, $data);
            return response()->json(['status' => 'success', 'data' => $category]);
        });
    }

    public function store(Request $request, int $id)
    {
        $this->admin($request);
        $data = $request->validate(['is_verified' => 'required|boolean', 'status' => 'required|in:pending,active,suspended']);
        return DB::transaction(function () use ($request, $id, $data) {
            $store = Store::whereKey($id)->lockForUpdate()->firstOrFail();
            abort_if($data['status'] === 'active' && !$data['is_verified'], 422, 'Verify the seller before activating their store.');
            $store->update($data);
            if ($data['is_verified'] && $data['status'] === 'active') {
                User::whereKey($store->user_id)->where('role', 'customer')->update(['role' => 'seller']);
            }
            $this->audit($request, 'catalog.store.reviewed', 'store', $id, $data);
            return response()->json(['status' => 'success', 'data' => $store]);
        });
    }

    public function banner(Request $request)
    {
        $this->admin($request);
        $data = $request->validate([
            'id' => 'nullable|integer|exists:marketplace_banners,id', 'title' => 'required|string|max:180',
            'description' => 'nullable|string|max:1000', 'image_url' => 'nullable|url:http,https|max:2048',
            'action_route' => 'required|in:/products,/auction,/coins,/coin-shop,/gives,/membership,/deals',
            'is_active' => 'required|boolean', 'position' => 'required|integer|min:0|max:1000',
            'starts_at' => 'nullable|date', 'ends_at' => 'nullable|date|after:starts_at',
        ]);
        return DB::transaction(function () use ($request, $data) {
            $id = $data['id'] ?? null;
            unset($data['id']);
            $data['updated_at'] = now();
            if ($id) {
                DB::table('marketplace_banners')->where('id', $id)->update($data);
            } else {
                $id = DB::table('marketplace_banners')->insertGetId($data + ['created_at' => now()]);
            }
            $this->audit($request, 'catalog.banner.saved', 'banner', $id, $data);
            return response()->json(['status' => 'success', 'data' => DB::table('marketplace_banners')->find($id)]);
        });
    }

    public function banners()
    {
        return response()->json(['status' => 'success', 'data' => DB::table('marketplace_banners')
            ->where('is_active', true)
            ->where(fn ($q) => $q->whereNull('starts_at')->orWhere('starts_at', '<=', now()))
            ->where(fn ($q) => $q->whereNull('ends_at')->orWhere('ends_at', '>', now()))
            ->orderBy('position')->get()]);
    }

    public function coupon(Request $request)
    {
        $this->admin($request);
        $data = $request->validate([
            'id' => 'nullable|integer|exists:coupons,id',
            'code' => ['required', 'alpha_dash', 'max:40', Rule::unique('coupons')->ignore($request->integer('id'))],
            'type' => 'required|in:percent,fixed,free_shipping', 'value' => 'required|numeric|min:0|max:999999',
            'min_spend' => 'required|numeric|min:0|max:9999999', 'is_active' => 'required|boolean', 'expires_at' => 'nullable|date',
        ]);
        abort_if($data['type'] === 'percent' && $data['value'] > 100, 422, 'Percentage discounts cannot exceed 100.');
        return DB::transaction(function () use ($request, $data) {
            $coupon = isset($data['id']) ? Coupon::findOrFail($data['id']) : new Coupon();
            unset($data['id']);
            $coupon->fill($data)->save();
            $this->audit($request, 'catalog.coupon.saved', 'coupon', $coupon->id, $data);
            return response()->json(['status' => 'success', 'data' => $coupon]);
        });
    }

    public function notify(Request $request)
    {
        $this->admin($request);
        $data = $request->validate([
            'user_id' => 'required|integer|exists:users,id', 'title' => 'required|string|max:150',
            'body' => 'required|string|max:3000',
            'action_route' => 'nullable|in:/orders,/coins,/auction,/gives,/membership,/coin-shop,/products',
        ]);
        return DB::transaction(function () use ($request, $data) {
            $notification = Notification::create($data + ['type' => 'system', 'action_label' => isset($data['action_route']) ? 'View' : null]);
            $this->audit($request, 'catalog.notification.created', 'notification', $notification->id, $data);
            return response()->json(['status' => 'success', 'data' => $notification]);
        });
    }

    public function application(Request $request)
    {
        abort_unless($request->user()->status === 'active', 403);
        return response()->json(['status' => 'success', 'data' => $request->user()->store]);
    }

    public function apply(Request $request)
    {
        abort_unless($request->user()->status === 'active' && in_array($request->user()->role, ['customer', 'seller'], true), 403);
        $data = $request->validate(['name' => 'required|string|max:150', 'description' => 'required|string|max:3000', 'craft_category' => 'required|string|max:100']);
        return DB::transaction(function () use ($request, $data) {
            User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
            abort_if(Store::where('user_id', $request->user()->id)->exists(), 422, 'You already have a store application.');
            $store = Store::create($data + ['user_id' => $request->user()->id, 'slug' => Str::slug($data['name']).'-'.Str::lower(Str::random(8)), 'status' => 'pending', 'is_verified' => false]);
            return response()->json(['status' => 'success', 'data' => $store], 201);
        });
    }

    private function audit(Request $request, string $action, string $type, int $id, array $payload): void
    {
        DB::table('roni_admin_actions')->insert([
            'actor_id' => $request->user()->id, 'action' => $action, 'subject_type' => $type,
            'subject_id' => $id, 'payload' => json_encode($payload), 'created_at' => now(),
        ]);
    }
}
