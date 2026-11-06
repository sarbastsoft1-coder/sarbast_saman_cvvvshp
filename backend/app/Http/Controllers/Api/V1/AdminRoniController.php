<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Services\RoniEngine;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * The RONI control plane.
 *
 * Caps, budgets, plans, prizes and charity projects are all changed here at
 * runtime. Nothing in this file is a reward: it is the machinery that decides
 * whether rewards may be issued at all, and every change is audited.
 */
class AdminRoniController extends Controller
{
    private function requireAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'admin' && $request->user()?->status === 'active', 403);
    }

    /**
     * Financial safety dashboard: what is committed this month against what
     * was allowed, and how much liability the outstanding points represent.
     */
    public function overview()
    {
        $budget = RoniEngine::budget();
        $settings = RoniEngine::settings();

        $outstanding = (int) DB::table('ronix_wallets')->sum('balance');
        $redemptionCost = (int) DB::table('roni_redemptions')
            ->where('status', 'pending')
            ->sum('cost_minor');

        return response()->json([
            'status' => 'success',
            'data' => [
                'month' => $budget->month,
                'settings' => $settings,
                'rewards_enabled' => (bool) $settings['rewards_enabled'],
                'reward' => $this->line($budget->reward_limit_minor, $budget->reward_committed_minor, $settings['yellow_threshold']),
                'charity' => $this->line($budget->charity_limit_minor, $budget->charity_committed_minor, $settings['yellow_threshold']),
                'auction' => $this->line($budget->auction_limit_minor, $budget->auction_committed_minor, $settings['yellow_threshold']),
                'ronix_outstanding' => $outstanding,
                'pending_redemption_cost_minor' => $redemptionCost,
                'open_fraud_flags' => DB::table('roni_fraud_flags')->where('status', 'open')->count(),
                'policy' => RoniEngine::policy(),
            ],
        ]);
    }

    /**
     * Rewrite the reward policy. Values are clamped and merged, so a partial
     * update never silently resets the keys it did not mention.
     */
    public function saveSettings(Request $request)
    {
        $this->requireAdmin($request);

        $data = $request->validate([
            'rewards_enabled' => 'sometimes|boolean',
            'purchase_cap' => 'sometimes|integer|min:0|max:1000000',
            'monthly_user_cap' => 'sometimes|integer|min:0|max:100000000',
            'task_cap' => 'sometimes|integer|min:0|max:1000000',
            'review_reward' => 'sometimes|integer|min:0|max:1000000',
            'charity_bps' => 'sometimes|integer|min:0|max:10000',
            'liability_per_1000_minor' => 'sometimes|integer|min:0|max:10000000',
            'yellow_threshold' => 'sometimes|integer|min:1|max:100',
        ]);

        return DB::transaction(function () use ($request, $data) {
            $merged = array_merge(RoniEngine::settings(), $data);

            // Points that can no longer be granted must not become unbounded.
            abort_if(
                (int) $merged['purchase_cap'] > (int) $merged['monthly_user_cap'],
                422,
                'The per-order purchase cap cannot exceed the monthly user cap.',
            );

            DB::table('roni_settings')->where('id', 1)->update([
                'values' => json_encode($merged),
                'updated_at' => now(),
            ]);

            RoniEngine::audit($request->user()->id, 'roni.settings.changed', 'settings', 1, $data);

            return response()->json(['status' => 'success', 'data' => $merged]);
        });
    }

    /** Set the ceiling for one month. Committed amounts are never lowered silently. */
    public function saveBudget(Request $request)
    {
        $this->requireAdmin($request);

        $data = $request->validate([
            'month' => 'nullable|string|size:7',
            'reward_limit_minor' => 'sometimes|integer|min:0|max:100000000000',
            'charity_limit_minor' => 'sometimes|integer|min:0|max:100000000000',
            'auction_limit_minor' => 'sometimes|integer|min:0|max:100000000000',
        ]);

        $month = $data['month'] ?? RoniEngine::month();
        unset($data['month']);

        return DB::transaction(function () use ($request, $data, $month) {
            $budget = RoniEngine::budget($month, true);

            abort_if(
                $budget->reward_committed_minor > (int) ($data['reward_limit_minor'] ?? $budget->reward_limit_minor),
                422,
                'The reward limit is already below what this month has committed.',
            );

            DB::table('roni_budgets')->where('id', $budget->id)->update($data + ['month' => $month, 'updated_at' => now()]);
            RoniEngine::audit($request->user()->id, 'roni.budget.changed', 'budget', $budget->id, $data + ['month' => $month]);

            return response()->json([
                'status' => 'success',
                'data' => RoniEngine::budget($month),
            ]);
        });
    }

    public function plans()
    {
        return response()->json([
            'status' => 'success',
            'data' => DB::table('roni_membership_plans')->orderBy('monthly_price_minor')->get(),
        ]);
    }

    /** Publish a tier, or change its price and benefits. */
    public function savePlan(Request $request, $id)
    {
        $this->requireAdmin($request);

        $data = $request->validate([
            'is_active' => 'sometimes|boolean',
            'monthly_price_minor' => 'sometimes|integer|min:0|max:10000000',
            'yearly_price_minor' => 'sometimes|integer|min:0|max:100000000',
            'bonus_bps' => 'sometimes|integer|min:0|max:10000',
            'monthly_ronix' => 'sometimes|integer|min:0|max:1000000',
            'benefits' => 'sometimes|array|max:30',
            'benefits.*' => 'required|string|max:400',
        ]);

        return DB::transaction(function () use ($request, $data, $id) {
            $plan = DB::table('roni_membership_plans')->where('id', $id)->first();
            abort_unless($plan, 404, 'Plan not found.');

            if (isset($data['is_active'])) {
                $data['is_active'] = $request->boolean('is_active');
            }

            if (array_key_exists('benefits', $data)) {
                $data['benefits'] = json_encode($data['benefits']);
            }

            DB::table('roni_membership_plans')->where('id', $id)->update($data + ['updated_at' => now()]);
            RoniEngine::audit($request->user()->id, 'roni.plan.saved', 'plan', (int) $id, $data);

            return response()->json([
                'status' => 'success',
                'data' => DB::table('roni_membership_plans')->where('id', $id)->first(),
            ]);
        });
    }

    public function memberships()
    {
        return response()->json([
            'status' => 'success',
            'data' => DB::table('roni_membership_requests as m')
                ->join('users as u', 'u.id', '=', 'm.user_id')
                ->join('roni_membership_plans as p', 'p.id', '=', 'm.plan_id')
                ->select('m.*', 'p.name as plan_name', 'u.name as customer_name', 'u.email as customer_email')
                ->orderByDesc('m.id')
                ->limit(200)
                ->get(),
        ]);
    }

    /**
     * Confirm that money actually arrived, then start the paid term. Until
     * this is called a request is only an expression of interest.
     */
    public function settleMembership(Request $request, $id)
    {
        $this->requireAdmin($request);

        $data = $request->validate([
            'payment_reference' => 'required|string|max:120',
        ]);

        return DB::transaction(function () use ($request, $data, $id) {
            $row = DB::table('roni_membership_requests')->where('id', $id)->lockForUpdate()->first();
            abort_unless($row, 404, 'Request not found.');
            abort_unless($row->status === 'pending', 409, 'Only a pending request can be settled.');

            $starts = now();
            $ends = $row->interval === 'yearly'
                ? now()->addYear()
                : now()->addMonth();

            DB::table('roni_membership_requests')->where('id', $id)->update([
                'status' => 'active',
                'payment_reference' => $data['payment_reference'],
                'settled_by' => $request->user()->id,
                'starts_at' => $starts,
                'ends_at' => $ends,
                'updated_at' => now(),
            ]);

            RoniEngine::audit($request->user()->id, 'roni.membership.settled', 'membership', (int) $id, $data);

            Notification::send(
                (int) $row->user_id,
                'membership',
                'RONI Plus is active',
                'Your membership is confirmed until ' . $ends . '.',
                'Open membership',
                '/membership',
                null,
            );

            return response()->json([
                'status' => 'success',
                'data' => DB::table('roni_membership_requests')->where('id', $id)->first(),
            ]);
        });
    }

    public function rejectMembership(Request $request, $id)
    {
        $this->requireAdmin($request);
        $request->validate(['reason' => 'nullable|string|max:500']);

        $row = DB::table('roni_membership_requests')->where('id', $id)->first();
        abort_unless($row, 404, 'Request not found.');
        abort_unless($row->status === 'pending', 409, 'Only a pending request can be rejected.');

        DB::table('roni_membership_requests')->where('id', $id)
            ->update(['status' => 'rejected', 'updated_at' => now()]);

        RoniEngine::audit($request->user()->id, 'roni.membership.rejected', 'membership', (int) $id, ['reason' => $request->input('reason')]);

        return response()->json(['status' => 'success', 'data' => DB::table('roni_membership_requests')->where('id', $id)->first()]);
    }

    public function fraudFlags(Request $request)
    {
        $status = $request->query('status', 'open');

        return response()->json([
            'status' => 'success',
            'data' => DB::table('roni_fraud_flags as f')
                ->join('users as u', 'u.id', '=', 'f.user_id')
                ->select('f.*', 'u.name as customer_name', 'u.email as customer_email')
                ->when($status !== 'all', fn ($q) => $q->where('f.status', $status))
                ->orderByDesc('f.id')
                ->limit(200)
                ->get(),
        ]);
    }

    /** A flag is a review signal, never an automatic punishment. */
    public function resolveFlag(Request $request, $id)
    {
        $this->requireAdmin($request);

        $data = $request->validate([
            'status' => 'required|in:open,dismissed,actioned',
            'resolution' => 'nullable|string|max:2000',
        ]);

        DB::table('roni_fraud_flags')->where('id', $id)
            ->update(['status' => $data['status'], 'resolution' => $data['resolution'] ?? null, 'updated_at' => now()]);

        RoniEngine::audit($request->user()->id, 'roni.flag.resolved', 'fraud_flag', (int) $id, $data);

        return response()->json(['status' => 'success', 'data' => DB::table('roni_fraud_flags')->where('id', $id)->first()]);
    }

    public function auctions()
    {
        return response()->json([
            'status' => 'success',
            'data' => DB::table('roni_auctions as a')
                ->leftJoin('users as w', 'w.id', '=', 'a.winner_id')
                ->select('a.*', 'w.name as winner_name')
                ->orderByDesc('a.id')
                ->get(),
        ]);
    }

    public function saveAuction(Request $request, $id = null)
    {
        $this->requireAdmin($request);

        $data = $request->validate([
            'id' => 'nullable|integer|exists:roni_auctions,id',
            'title' => 'required|string|max:180',
            'description' => 'nullable|string|max:4000',
            'prize_name' => 'required|string|max:180',
            'image_url' => 'nullable|url:http,https|max:2048',
            'prize_value_minor' => 'required|integer|min:0|max:100000000000',
            // What this prize costs RONI. A sponsored prize costs far less,
            // which is how the weekly auction stays affordable.
            'prize_cost_minor' => 'required|integer|min:0|max:100000000000',
            'sponsor' => 'nullable|string|max:180',
            'starts_at' => 'required|date',
            'ends_at' => 'required|date|after:starts_at',
            'min_bid' => 'required|integer|min:1|max:1000000',
            'bid_increment' => 'required|integer|min:1|max:1000000',
            'budget_month' => 'nullable|string|size:7',
        ]);

        unset($data['id']);

        return DB::transaction(function () use ($request, $data, $id) {
            $row = $id
                ? DB::table('roni_auctions')->where('id', $id)->first()
                : null;

            if ($row && $row->status !== 'draft') {
                $data['status'] = $row->status;
            }

            if ($id) {
                DB::table('roni_auctions')->where('id', $id)->update($data + ['updated_at' => now()]);
                $id = (int) $id;
            } else {
                $id = DB::table('roni_auctions')->insertGetId($data + ['status' => 'draft', 'created_at' => now(), 'updated_at' => now()]);
            }

            RoniEngine::audit($request->user()->id, 'roni.auction.saved', 'auction', $id, $data);

            return response()->json([
                'status' => 'success',
                'data' => DB::table('roni_auctions')->where('id', $id)->first(),
            ]);
        });
    }

    /**
     * Open bidding. The prize cost is charged to the auction budget at the
     * moment it is published, and returned only if the lot closes with no
     * bids at all.
     */
    public function publishAuction(Request $request, $id)
    {
        $this->requireAdmin($request);

        return DB::transaction(function () use ($request, $id) {
            $auction = DB::table('roni_auctions')->where('id', $id)->lockForUpdate()->first();
            abort_unless($auction, 404, 'Auction not found.');
            abort_unless($auction->status === 'draft', 409, 'Only a draft auction can be published.');

            $month = $auction->budget_month ?: RoniEngine::month();
            $budget = RoniEngine::budget($month, true);

            abort_if(
                $budget->auction_committed_minor + $auction->prize_cost_minor > $budget->auction_limit_minor,
                422,
                'This prize does not fit in the remaining auction budget.',
            );

            DB::table('roni_auctions')->where('id', $id)->update([
                'status' => 'published',
                'budget_month' => $month,
                'updated_at' => now(),
            ]);

            DB::table('roni_budgets')->where('id', $budget->id)
                ->increment('auction_committed_minor', $auction->prize_cost_minor);

            RoniEngine::audit($request->user()->id, 'roni.auction.published', 'auction', (int) $id, [
                'budget_month' => $month, 'prize_cost_minor' => (int) $auction->prize_cost_minor,
            ]);

            return response()->json([
                'status' => 'success',
                'data' => DB::table('roni_auctions')->where('id', $id)->first(),
            ]);
        });
    }

    public function projects()
    {
        return response()->json([
            'status' => 'success',
            'data' => DB::table('roni_projects as p')
                ->select('p.*', DB::raw('(select COALESCE(sum(amount_minor),0) from roni_contributions c where c.project_id = p.id and c.status = \'allocated\') as allocated_minor'))
                ->orderByDesc('p.id')
                ->get(),
        ]);
    }

    public function saveProject(Request $request, $id = null)
    {
        $this->requireAdmin($request);

        $data = $request->validate([
            'id' => 'nullable|integer|exists:roni_projects,id',
            'title' => 'required|string|max:180',
            'description' => 'required|string|max:4000',
            'organization' => 'required|string|max:180',
            'image_url' => 'nullable|url:http,https|max:2048',
            'target_minor' => 'required|integer|min:1|max:100000000000',
            'status' => 'required|in:draft,active,completed',
        ]);

        unset($data['id']);

        return DB::transaction(function () use ($request, $data, $id) {
            if ($id) {
                DB::table('roni_projects')->where('id', $id)->update($data + ['updated_at' => now()]);
                $id = (int) $id;
            } else {
                $id = DB::table('roni_projects')->insertGetId($data + ['current_minor' => 0, 'created_at' => now(), 'updated_at' => now()]);
            }

            RoniEngine::audit($request->user()->id, 'roni.project.saved', 'project', $id, $data);

            return response()->json([
                'status' => 'success',
                'data' => DB::table('roni_projects')->where('id', $id)->first(),
            ]);
        });
    }

    /**
     * One budget line rendered for the dashboard: limit, committed, remaining
     * and the traffic light the engine's own thresholds imply.
     */
    private function line($limit, $committed, $yellow): array
    {
        $limit = (int) $limit;
        $committed = (int) $committed;

        $level = match (true) {
            $limit <= 0 => 'red',
            $committed >= $limit => 'red',
            $committed * 100 >= $limit * (int) $yellow => 'yellow',
            default => 'green',
        };

        return [
            'limit_minor' => $limit,
            'committed_minor' => $committed,
            'remaining_minor' => max(0, $limit - $committed),
            'used_percent' => $limit > 0 ? round($committed * 100 / $limit, 1) : 100.0,
            'level' => $level,
        ];
    }
}
