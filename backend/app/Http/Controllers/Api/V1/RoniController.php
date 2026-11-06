<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Services\RoniEngine;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * The three RONI panels that are read without signing in: the loop summary,
 * RONI Gives, and RONI Plus. Each one degrades to public-only content when
 * the caller is a guest, so the home screens never need a token to render.
 */
class RoniController extends Controller
{
    /**
     * The whole loop in one payload: what you have earned, what level you
     * reached, the live auction, and how much the community has raised.
     */
    public function summary(Request $request)
    {
        $user = $request->user('sanctum');

        $auction = DB::table('roni_auctions as a')
            ->where('a.status', 'published')
            ->where('a.starts_at', '<=', now())
            ->where('a.ends_at', '>', now())
            ->select('a.id', 'a.title', 'a.prize_name', 'a.image_url', 'a.prize_value_minor', 'a.ends_at')
            ->orderBy('a.ends_at')
            ->first();

        $project = DB::table('roni_projects')->where('status', 'active')->orderBy('id')->first();

        $membership = $user ? RoniEngine::membership($user->id) : null;

        return response()->json([
            'status' => 'success',
            'data' => [
                'balance' => $user ? (int) RoniEngine::wallet($user->id)->balance : 0,
                'loyalty' => $user ? RoniEngine::loyalty($user->id) : null,
                'membership' => $membership ? [
                    'plan' => ['name' => $membership->name],
                    'plan_name' => $membership->name,
                    'status' => $membership->status,
                    'ends_at' => $membership->ends_at,
                ] : null,
                'auction' => $auction,
                'gives' => $project ? [
                    'project_id' => (int) $project->id,
                    'title' => $project->title,
                    'target_minor' => (int) $project->target_minor,
                    'current_minor' => (int) $project->current_minor,
                ] : null,
                'policy' => RoniEngine::policy(),
            ],
        ]);
    }

    /**
     * RONI Gives. Projects are public; the customer's own confirmed
     * allocations only exist once they are signed in.
     */
    public function gives(Request $request)
    {
        $user = $request->user('sanctum');

        $projects = DB::table('roni_projects')
            ->whereIn('status', ['active', 'completed'])
            ->orderByRaw("CASE WHEN status = 'active' THEN 0 ELSE 1 END")
            ->orderByDesc('id')
            ->get()
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'title' => $row->title,
                'description' => $row->description,
                'organization' => $row->organization,
                'image_url' => $row->image_url,
                'status' => $row->status,
                'target_minor' => (int) $row->target_minor,
                'current_minor' => (int) $row->current_minor,
                'progress' => $row->target_minor > 0
                    ? round($row->current_minor / $row->target_minor, 4)
                    : 0.0,
            ]);

        $contributions = $user
            ? DB::table('roni_contributions as c')
                ->join('roni_projects as p', 'p.id', '=', 'c.project_id')
                ->join('orders as o', 'o.id', '=', 'c.order_id')
                ->select('c.id', 'c.order_id', 'c.amount_minor', 'c.status', 'c.created_at',
                    'p.title as project_title', 'o.order_number')
                ->where('c.user_id', $user->id)
                ->orderByDesc('c.id')
                ->limit(50)
                ->get()
            : collect();

        $total = (int) $contributions
            ->where('status', 'allocated')
            ->sum('amount_minor');

        return response()->json([
            'status' => 'success',
            'data' => [
                'projects' => $projects,
                'contributions' => $contributions,
                'total_minor' => $total,
                'policy' => ['gives_notice' => RoniEngine::policy()['gives_notice']],
            ],
        ]);
    }

    /**
     * RONI Plus. A customer's loyalty LEVEL comes from completed orders; a
     * paid MEMBERSHIP is a separate, separately verified thing.
     */
    public function memberships(Request $request)
    {
        $user = $request->user('sanctum');

        $plans = DB::table('roni_membership_plans')
            ->where('is_active', true)
            ->orderBy('monthly_price_minor')
            ->get()
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'name' => $row->name,
                'monthly_price_minor' => (int) $row->monthly_price_minor,
                'yearly_price_minor' => (int) $row->yearly_price_minor,
                'bonus_bps' => (int) $row->bonus_bps,
                'monthly_ronix' => (int) $row->monthly_ronix,
                'benefits' => json_decode($row->benefits, true) ?: [],
            ]);

        if (!$user) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'plans' => $plans,
                    'membership' => null,
                    'loyalty' => null,
                    'requests' => [],
                    'policy' => ['membership_notice' => RoniEngine::policy()['membership_notice']],
                ],
            ]);
        }

        $membership = RoniEngine::membership($user->id);

        $requests = DB::table('roni_membership_requests as m')
            ->join('roni_membership_plans as p', 'p.id', '=', 'm.plan_id')
            ->where('m.user_id', $user->id)
            ->select('m.*', 'p.name as plan_name')
            ->orderByDesc('m.id')
            ->limit(20)
            ->get()
            ->map(fn ($row) => [
                'id' => (int) $row->id,
                'plan' => ['id' => (int) $row->plan_id, 'name' => $row->plan_name],
                'interval' => $row->interval,
                'status' => $row->status,
                'price_minor' => (int) $row->price_minor,
                'bonus_bps' => (int) $row->bonus_bps,
                'cancel_at_period_end' => (bool) $row->cancel_at_period_end,
                'created_at' => $row->created_at,
            ]);

        return response()->json([
            'status' => 'success',
            'data' => [
                'plans' => $plans,
                'membership' => $membership ? [
                    'id' => (int) $membership->id,
                    'plan' => ['id' => (int) $membership->plan_id, 'name' => $membership->name],
                    'plan_name' => $membership->name,
                    'status' => $membership->status,
                    'interval' => $membership->interval,
                    'starts_at' => $membership->starts_at,
                    'ends_at' => $membership->ends_at,
                    'expires_at' => $membership->ends_at,
                    'cancel_at_period_end' => (bool) $membership->cancel_at_period_end,
                    'bonus_bps' => (int) $membership->bonus_bps,
                ] : null,
                'loyalty' => RoniEngine::loyalty($user->id),
                'requests' => $requests,
                'policy' => ['membership_notice' => RoniEngine::policy()['membership_notice']],
            ],
        ]);
    }

    /**
     * Record interest in a plan. No money moves here: the row stays pending
     * until an administrator confirms a payment actually arrived.
     */
    public function requestMembership(Request $request)
    {
        $data = $request->validate([
            'plan_id' => 'required|integer|exists:roni_membership_plans,id',
            'interval' => 'required|in:monthly,yearly',
        ]);

        $user = $request->user('sanctum');

        $plan = DB::table('roni_membership_plans')->where('id', $data['plan_id'])->first();
        abort_unless($plan && $plan->is_active, 422, 'This plan is not available right now.');

        abort_if(
            DB::table('roni_membership_requests')
                ->where('user_id', $user->id)
                ->whereIn('status', ['pending', 'active'])
                ->exists(),
            409,
            'You already have a membership request in progress.',
        );

        $price = $data['interval'] === 'yearly'
            ? $plan->yearly_price_minor
            : $plan->monthly_price_minor;

        $id = DB::table('roni_membership_requests')->insertGetId([
            'user_id' => $user->id,
            'plan_id' => $plan->id,
            'interval' => $data['interval'],
            'price_minor' => $price,
            'bonus_bps' => $plan->bonus_bps,
            'monthly_ronix' => $plan->monthly_ronix,
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Request recorded. Membership begins once payment is verified.',
            'data' => ['id' => $id, 'status' => 'pending'],
        ], 201);
    }

    /**
     * Ask to end a membership. Benefits already paid for keep running until
     * the end of the paid term; nothing is refunded early.
     */
    public function cancelMembership(Request $request)
    {
        $user = $request->user('sanctum');

        $membership = DB::table('roni_membership_requests')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->orderByDesc('id')
            ->first();

        if ($membership) {
            DB::table('roni_membership_requests')
                ->where('id', $membership->id)
                ->update(['cancel_at_period_end' => true, 'updated_at' => now()]);

            Notification::send(
                $user->id,
                'membership',
                'Membership will end',
                'Your RONI Plus benefits continue until ' . $membership->ends_at . '.',
                'Open membership',
                '/membership',
                null,
            );

            return response()->json([
                'status' => 'success',
                'message' => 'Membership will end at the close of the paid period.',
                'data' => ['id' => (int) $membership->id, 'cancel_at_period_end' => true],
            ]);
        }

        $pending = DB::table('roni_membership_requests')
            ->where('user_id', $user->id)
            ->where('status', 'pending')
            ->orderByDesc('id')
            ->first();

        abort_if(!$pending, 422, 'There is no membership to cancel.');

        DB::table('roni_membership_requests')
            ->where('id', $pending->id)
            ->update(['status' => 'cancelled', 'updated_at' => now()]);

        return response()->json([
            'status' => 'success',
            'message' => 'Your membership request was withdrawn.',
            'data' => ['id' => (int) $pending->id, 'status' => 'cancelled'],
        ]);
    }
}
