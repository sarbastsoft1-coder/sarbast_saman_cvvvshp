<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Article;
use App\Models\Order;
use App\Models\SystemSetting;
use App\Models\Wallet;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AdminController extends Controller
{
    public function kpis()
    {
        return response()->json([
            'status' => 'success',
            'data' => [
                'gross_volume' => '$' . number_format(Order::where('status', 'delivered')->sum('total_fiat'), 2),
                'active_users' => User::where('status', 'active')->count(),
                'total_tokens_circulating' => number_format(Wallet::sum('token_balance'), 2).' TERRA',
                'completed_deliveries_today' => Order::whereDate('delivered_at', today())->where('status', 'delivered')->count(),
                'recent_registrations' => User::latest()->take(6)->get(['id', 'name', 'email', 'role', 'status', 'created_at']),
            ],
        ]);
    }

    public function users()
    {
        return response()->json([
            'status' => 'success',
            'data' => User::latest()->get(['id', 'name', 'email', 'role', 'status', 'created_at']),
        ]);
    }

    public function toggleUserStatus(Request $request, $userId)
    {
        abort_if((int) $userId === $request->user()->id, 422, 'You cannot suspend your own administrator account.');
        return DB::transaction(function () use ($request, $userId) {
            $user = User::whereKey($userId)->lockForUpdate()->firstOrFail();
            $user->status = $user->status === 'active' ? 'suspended' : 'active';
            $user->save();
            DB::table('roni_admin_actions')->insert(['actor_id' => $request->user()->id, 'action' => 'user.status.changed', 'subject_type' => 'user', 'subject_id' => $user->id, 'payload' => json_encode(['status' => $user->status]), 'created_at' => now()]);
            return response()->json(['status' => 'success', 'user' => $user]);
        });
    }

    public function articles()
    {
        return response()->json([
            'status' => 'success',
            'data' => Article::latest()->get(),
        ]);
    }

    public function saveArticle(Request $request)
    {
        $request->validate([
            'id' => 'nullable|integer|exists:articles,id', 'title' => 'required|string|max:180',
            'summary' => 'required|string|max:1000', 'content' => 'required|string|max:50000',
            'category' => 'nullable|string|max:100', 'read_time' => 'nullable|string|max:40',
            'cover_image' => 'nullable|url:http,https|max:2048', 'is_published' => 'sometimes|boolean',
        ]);
        $article = Article::updateOrCreate(
            ['id' => $request->id],
            [
                'title' => $request->title,
                'slug' => Str::slug($request->title).'-'.($request->id ?? Str::lower(Str::random(8))),
                'category' => $request->category ?? 'RONI News',
                'read_time' => $request->read_time ?? '4 min read',
                'summary' => $request->summary,
                'content' => $request->content,
                'cover_image' => $request->cover_image,
                'is_published' => $request->boolean('is_published', true),
                'published_at' => now(),
            ]
        );

        return response()->json(['status' => 'success', 'article' => $article]);
    }

    public function settings()
    {
        return response()->json([
            'status' => 'success',
            'data' => SystemSetting::all(),
        ]);
    }

    public function saveSettings(Request $request)
    {
        abort_unless($request->user()?->role === 'admin' && $request->user()?->status === 'active', 403);
        $data = $request->validate([
            'delivery_base_fee' => 'sometimes|required|numeric|min:0|max:100000',
            'courier_payout_per_delivery' => 'sometimes|required|numeric|min:0|max:100000',
            'delivery_fee' => 'sometimes|required|numeric|min:0|max:100000',
            'token_peg' => 'sometimes|required|numeric|min:0|max:100000',
            'platform_fee' => 'sometimes|required|numeric|min:0|max:100',
        ]);
        // Admin UI historically used `delivery_fee`; keep both keys in sync.
        if (isset($data['delivery_fee']) && !isset($data['delivery_base_fee'])) {
            $data['delivery_base_fee'] = $data['delivery_fee'];
        }
        return DB::transaction(function () use ($request, $data) {
            foreach ($data as $key => $value) {
                $group = in_array($key, ['token_peg', 'platform_fee'], true)
                    ? 'commerce'
                    : 'delivery';
                SystemSetting::updateOrCreate(
                    ['key' => $key],
                    ['value' => (string) $value, 'group' => $group],
                );
            }
            DB::table('roni_admin_actions')->insert([
                'actor_id' => $request->user()->id,
                'action' => 'settings.changed',
                'subject_type' => 'settings',
                'subject_id' => 0,
                'payload' => json_encode($data),
                'created_at' => now(),
            ]);
            return response()->json(['status' => 'success', 'data' => $data]);
        });
    }
}
