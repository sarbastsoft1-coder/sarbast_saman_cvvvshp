<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\RoniEngine;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * The customer's Ronix wallet.
 *
 * Every number here is read from the ledger; nothing is calculated on the
 * phone and nothing is recomputed from a cached client value.
 */
class RonixController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user('sanctum');

        $wallet = RoniEngine::wallet($user->id);

        $transactions = DB::table('ronix_transactions')
            ->where('user_id', $user->id)
            ->latest('id')
            ->limit(50)
            ->get();

        // "Earned" is everything that came in. "Spent" is genuine outflow; a
        // refund clawback is a reversal, not something the customer chose to
        // spend, so it is reported in the ledger but left out of this total.
        $earned = (int) DB::table('ronix_transactions')
            ->where('user_id', $user->id)
            ->where('amount', '>', 0)
            ->sum('amount');

        $spent = (int) DB::table('ronix_transactions')
            ->where('user_id', $user->id)
            ->where('amount', '<', 0)
            ->where('type', '!=', 'refund_reversal')
            ->selectRaw('COALESCE(SUM(ABS(amount)), 0) AS total')
            ->value('total');

        return response()->json([
            'status' => 'success',
            'data' => [
                'balance' => (int) $wallet->balance,
                'earned' => $earned,
                'spent' => $spent,
                'transactions' => $transactions,
                'rewards' => DB::table('roni_rewards')
                    ->where('is_active', true)
                    ->orderBy('ronix_price')
                    ->get(),
                'redemptions' => $this->redemptions($user->id),
                'policy' => RoniEngine::policy(),
            ],
        ]);
    }

    /**
     * Exchange Ronix for a reward. The key makes a double tap safe: the same
     * key returns the original redemption instead of charging twice.
     */
    public function redeem(Request $request, $rewardId)
    {
        $data = $request->validate([
            'idempotency_key' => 'required|string|max:100',
        ]);

        $user = $request->user('sanctum');
        $redemption = RoniEngine::redeem($user->id, (int) $rewardId, $data['idempotency_key']);

        return response()->json([
            'status' => 'success',
            'message' => 'Your reward request is recorded.',
            'data' => [
                'id' => (int) $redemption->id,
                'title' => $redemption->title,
                'ronix_spent' => (int) $redemption->ronix_price,
                'status' => $redemption->status,
                'balance' => (int) RoniEngine::wallet($user->id)->balance,
                'created_at' => $redemption->created_at,
            ],
        ], 201);
    }

    private function redemptions(int $userId)
    {
        return DB::table('roni_redemptions as red')
            ->join('roni_rewards as rw', 'rw.id', '=', 'red.reward_id')
            ->where('red.user_id', $userId)
            ->select('red.*', 'rw.image_url as reward_image', 'rw.description as reward_description')
            ->orderByDesc('red.id')
            ->limit(50)
            ->get()
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'title' => $row->title,
                'status' => $row->status,
                'ronix_spent' => (int) $row->ronix_price,
                'reward' => [
                    'id' => (int) $row->reward_id,
                    'title' => $row->title,
                    'description' => $row->reward_description,
                    'image_url' => $row->reward_image,
                ],
                'fulfillment_reference' => $row->fulfillment_reference,
                'created_at' => $row->created_at,
            ]);
    }
}
