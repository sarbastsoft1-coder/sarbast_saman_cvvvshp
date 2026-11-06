<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ProductDiscountController extends Controller
{
    private function products(Request $request)
    {
        $user = $request->user();
        abort_unless($user->status === 'active' && in_array($user->role, ['seller', 'admin'], true), 403);
        $query = Product::with('store');
        if ($user->role === 'seller') {
            $query->whereHas('store', fn ($store) => $store->where('user_id', $user->id));
        }
        return $query;
    }

    public function index(Request $request)
    {
        return response()->json(['status' => 'success', 'data' => $this->products($request)->latest()->get()]);
    }

    public function update(Request $request, int $product)
    {
        $item = $this->products($request)->findOrFail($product);
        $data = $request->validate(['discount_percent' => 'required|integer|min:0|max:99']);
        $item->update($data);
        return response()->json(['status' => 'success', 'data' => $item]);
    }
}
