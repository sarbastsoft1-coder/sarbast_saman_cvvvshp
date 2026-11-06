<?php
namespace App\Services;

use App\Models\Order;
use Illuminate\Support\Facades\DB;

/** Integer points and minor currency units. Every balance change has a unique ledger reference. */
class RoniEngine
{
    public static function settings(): array
    {
        return json_decode(DB::table('roni_settings')->where('id',1)->value('values'),true);
    }

    public static function month(): string { return now('Asia/Baghdad')->format('Y-m'); }

    public static function budget(?string $month = null, bool $lock = false): object
    {
        $month ??= self::month();
        DB::table('roni_budgets')->insertOrIgnore(['month'=>$month,'created_at'=>now(),'updated_at'=>now()]);
        $q = DB::table('roni_budgets')->where('month',$month);
        return ($lock ? $q->lockForUpdate() : $q)->first();
    }

    public static function wallet(int $userId, bool $lock = false): object
    {
        DB::table('ronix_wallets')->insertOrIgnore(['user_id'=>$userId,'created_at'=>now(),'updated_at'=>now()]);
        $q = DB::table('ronix_wallets')->where('user_id',$userId);
        return ($lock ? $q->lockForUpdate() : $q)->first();
    }

    /** Caller holds a transaction. Negative balances are allowed only for a refund clawback. */
    public static function transact(int $userId, int $amount, string $type, string $reference, string $description, int $cost = 0, bool $allowDebt = false): bool
    {
        $wallet = self::wallet($userId,true);
        if (DB::table('ronix_transactions')->where('reference',$reference)->exists()) return false;
        $balance = (int)$wallet->balance + $amount;
        abort_if($amount < 0 && $balance < 0 && !$allowDebt,422,'Insufficient available Ronix.');
        DB::table('ronix_wallets')->where('id',$wallet->id)->update(['balance'=>$balance,'updated_at'=>now()]);
        DB::table('ronix_transactions')->insert(['user_id'=>$userId,'type'=>$type,'amount'=>$amount,'balance_after'=>$balance,'reference'=>$reference,'description'=>$description,'cost_minor'=>$cost,'created_at'=>now(),'updated_at'=>now()]);
        return true;
    }

    public static function flag(int $userId, string $reason, string $reference): void
    {
        DB::table('roni_fraud_flags')->insertOrIgnore(['user_id'=>$userId,'reason'=>$reason,'reference'=>$reference,'status'=>'open','created_at'=>now(),'updated_at'=>now()]);
    }

    public static function award(int $userId, int $points, string $type, string $reference, string $description): bool
    {
        return DB::transaction(function () use ($userId,$points,$type,$reference,$description) {
            $budget = self::budget(null,true);
            self::wallet($userId,true);
            if (DB::table('ronix_transactions')->where('reference',$reference)->exists()) return false;
            $s = self::settings();
            if (!$s['rewards_enabled'] || $points <= 0) return false;
            $awarded = (int)DB::table('ronix_transactions')->where('user_id',$userId)->whereIn('type',['purchase_reward','task_reward','review_reward','membership_reward'])->where('created_at','>=',now('Asia/Baghdad')->startOfMonth()->utc())->sum('amount');
            $cost = (int)ceil($points * $s['liability_per_1000_minor'] / 1000);
            if ($awarded + $points > $s['monthly_user_cap']) {
                self::flag($userId,'Monthly reward cap reached; review activity before granting further rewards.','cap:'.$reference);
                return false;
            }
            if ($budget->reward_committed_minor + $cost > $budget->reward_limit_minor) return false;
            // Optional tasks and review campaigns stop at the warning threshold.
            if (in_array($type,['task_reward','review_reward']) && $budget->reward_limit_minor > 0 && $budget->reward_committed_minor * 100 >= $budget->reward_limit_minor * $s['yellow_threshold']) return false;
            self::transact($userId,$points,$type,$reference,$description,$cost);
            DB::table('roni_budgets')->where('id',$budget->id)->increment('reward_committed_minor',$cost);
            return true;
        },3);
    }

    public static function grantReview(int $userId, int $reviewId): bool
    {
        return self::award($userId,(int)(self::settings()['review_reward'] ?? 50),'review_reward','review:'.$reviewId,'Verified purchase review');
    }

    public static function membership(int $userId): ?object
    {
        $row = DB::table('roni_membership_requests as m')->join('roni_membership_plans as p','p.id','=','m.plan_id')->where('m.user_id',$userId)->where('m.status','active')->where('m.ends_at','>',now())->select('m.*','p.name')->latest('m.id')->first();
        return $row;
    }

    public static function loyalty(int $userId): array
    {
        $count = Order::where('customer_id',$userId)->where('status','delivered')->count();
        return ['level'=>match(true) { $count>=100=>'Diamond',$count>=40=>'Gold',$count>=15=>'Silver',$count>=5=>'Bronze',default=>'Normal' },'completed_orders'=>$count];
    }

    /** Called only after a delivered order has a recorded, sufficient payment. */
    public static function settleOrder(Order $order): void
    {
        DB::transaction(function () use ($order) {
            self::budget(null,true);
            $locked = Order::with('delivery')->lockForUpdate()->findOrFail($order->id);
            if ($locked->roni_status !== 'pending' || $locked->status !== 'delivered') return;
            $delivery = $locked->delivery;
            if (!$delivery || $delivery->cash_collected === null || $delivery->cash_collected + 0.009 < $locked->total_fiat) return;
            $s = self::settings();
            $granted = self::award($locked->customer_id,min((int)$locked->ronix_pending,(int)$s['purchase_cap']),'purchase_reward','order:'.$locked->id,'Purchase '.$locked->order_number);
            if ($s['rewards_enabled'] && $locked->gives_pending_minor > 0) {
                $budget = self::budget(null,true);
                $project = DB::table('roni_projects')->where('status','active')->orderBy('id')->lockForUpdate()->first();
                $amount = (int)$locked->gives_pending_minor;
                if ($project && $budget->charity_committed_minor + $amount <= $budget->charity_limit_minor) {
                    DB::table('roni_contributions')->insert(['project_id'=>$project->id,'user_id'=>$locked->customer_id,'order_id'=>$locked->id,'amount_minor'=>$amount,'budget_month'=>$budget->month,'status'=>'allocated','created_at'=>now(),'updated_at'=>now()]);
                    DB::table('roni_projects')->where('id',$project->id)->increment('current_minor',$amount);
                    DB::table('roni_budgets')->where('id',$budget->id)->increment('charity_committed_minor',$amount);
                }
            }
            $locked->forceFill(['roni_status'=>$granted ? 'awarded' : 'not_eligible'])->save();
        },3);
    }

    /** Refunds revoke the complete order reward even if already spent; debt blocks further spending. */
    public static function reverseOrder(Order $order): void
    {
        DB::transaction(function () use ($order) {
            $original = DB::table('ronix_transactions')->where('reference','order:'.$order->id)->first();
            if ($original) {
                self::budget(substr($original->created_at,0,7),true);
                if (self::transact($order->customer_id,-(int)$original->amount,'refund_reversal','refund:'.$order->id,'Reward reversal for '.$order->order_number,0,true)) {
                    DB::table('roni_budgets')->where('month',substr($original->created_at,0,7))->decrement('reward_committed_minor',(int)$original->cost_minor);
                    if (self::wallet($order->customer_id)->balance < 0) self::flag($order->customer_id,'Refund reversed points already spent; future earned points repay the balance.','refund-debt:'.$order->id);
                }
            }
            $contribution = DB::table('roni_contributions')->where('order_id',$order->id)->lockForUpdate()->first();
            if ($contribution && $contribution->status === 'allocated') {
                self::budget($contribution->budget_month,true);
                DB::table('roni_projects')->where('id',$contribution->project_id)->decrement('current_minor',$contribution->amount_minor);
                DB::table('roni_budgets')->where('month',$contribution->budget_month)->decrement('charity_committed_minor',$contribution->amount_minor);
                DB::table('roni_contributions')->where('id',$contribution->id)->update(['status'=>'reversed','updated_at'=>now()]);
            }
            $order->forceFill(['roni_status'=>'reversed'])->save();
        },3);
    }

    public static function closeAuctions(): int
    {
        $ids = DB::table('roni_auctions')->where('status','published')->where('ends_at','<=',now())->pluck('id');
        foreach ($ids as $id) DB::transaction(function () use ($id) {
            $auction = DB::table('roni_auctions')->where('id',$id)->lockForUpdate()->first();
            if ($auction->status !== 'published' || $auction->ends_at > now()) return;
            DB::table('roni_auctions')->where('id',$id)->update(['status'=>'closed','winner_id'=>$auction->highest_user_id,'closed_at'=>now(),'updated_at'=>now()]);
            DB::table('roni_bids')->where('auction_id',$id)->where('status','leading')->update(['status'=>'won','updated_at'=>now()]);
            if (!$auction->highest_user_id && $auction->budget_month) {
                self::budget($auction->budget_month,true);
                DB::table('roni_budgets')->where('month',$auction->budget_month)->decrement('auction_committed_minor',$auction->prize_cost_minor);
            }
        },3);
        return $ids->count();
    }

    public static function bid(int $userId, int $auctionId, int $amount): object
    {
        self::closeAuctions();
        return DB::transaction(function () use ($userId,$auctionId,$amount) {
            $a = DB::table('roni_auctions')->where('id',$auctionId)->lockForUpdate()->first();
            abort_unless($a,404);
            abort_unless($a->status === 'published' && now()->gte($a->starts_at) && now()->lt($a->ends_at),422,'This auction is not accepting bids.');
            $minimum = max((int)$a->min_bid,(int)$a->highest_bid + (int)$a->bid_increment);
            abort_if($amount < $minimum,422,'The next bid must be at least '.$minimum.' Ronix.');
            // Lock both wallets in stable order to serialize escrow release and funding.
            $users = array_unique(array_filter([$userId,$a->highest_user_id])); sort($users);
            foreach ($users as $id) self::wallet((int)$id,true);
            $credit = $a->highest_user_id === $userId ? (int)$a->highest_bid : 0;
            abort_if(self::wallet($userId)->balance + $credit < $amount,422,'Insufficient available Ronix.');
            $bidId = DB::table('roni_bids')->insertGetId(['auction_id'=>$a->id,'user_id'=>$userId,'amount'=>$amount,'status'=>'leading','created_at'=>now(),'updated_at'=>now()]);
            if ($a->highest_user_id) {
                self::transact((int)$a->highest_user_id,(int)$a->highest_bid,'auction_release','bid-release:'.$bidId,'Outbid Ronix returned for '.$a->title);
                DB::table('roni_bids')->where('auction_id',$a->id)->where('id','<>',$bidId)->where('status','leading')->update(['status'=>'outbid','updated_at'=>now()]);
            }
            self::transact($userId,-$amount,'auction_bid','bid:'.$bidId,'Bid held for '.$a->title);
            DB::table('roni_auctions')->where('id',$a->id)->update(['highest_bid'=>$amount,'highest_user_id'=>$userId,'updated_at'=>now()]);
            return DB::table('roni_auctions')->where('id',$a->id)->first();
        },3);
    }

    public static function redeem(int $userId, int $rewardId, string $key): object
    {
        return DB::transaction(function () use ($userId,$rewardId,$key) {
            $budget = self::budget(null,true);
            self::wallet($userId,true);
            $existing = DB::table('roni_redemptions')->where('user_id',$userId)->where('idempotency_key',$key)->first();
            if ($existing) { abort_if($existing->reward_id !== $rewardId,409,'This request key was used for another reward.'); return $existing; }
            $reward = DB::table('roni_rewards')->where('id',$rewardId)->lockForUpdate()->first();
            abort_unless($reward && $reward->is_active && $reward->stock > 0,422,'This reward is unavailable.');
            abort_unless(self::settings()['rewards_enabled'],422,'Reward campaigns are currently paused.');
            abort_if($budget->reward_committed_minor + $reward->cost_minor > $budget->reward_limit_minor,422,'This reward campaign has reached its budget.');
            $id = DB::table('roni_redemptions')->insertGetId(['user_id'=>$userId,'reward_id'=>$rewardId,'title'=>$reward->title,'ronix_price'=>$reward->ronix_price,'cost_minor'=>$reward->cost_minor,'idempotency_key'=>$key,'status'=>'pending','created_at'=>now(),'updated_at'=>now()]);
            self::transact($userId,-(int)$reward->ronix_price,'redemption','redeem:'.$id,$reward->title);
            DB::table('roni_rewards')->where('id',$rewardId)->decrement('stock');
            DB::table('roni_budgets')->where('id',$budget->id)->increment('reward_committed_minor',$reward->cost_minor);
            return DB::table('roni_redemptions')->where('id',$id)->first();
        },3);
    }

    public static function policy(): array
    {
        $s = self::settings();
        return ['rewards_enabled'=>(bool)$s['rewards_enabled'],'purchase_cap'=>$s['purchase_cap'],'monthly_user_cap'=>$s['monthly_user_cap'],'task_cap'=>$s['task_cap'],'review_reward'=>$s['review_reward'],'charity_bps'=>$s['charity_bps'],'points_notice'=>'Ronix are promotional points, not cash or tradable currency. Rewards require available campaign budget.','purchase_notice'=>'Purchase rewards and Gives allocations are confirmed after paid delivery. Refunds reverse the complete order allocation.','auction_rules'=>'Highest valid bid wins at the server end time. Ties are rejected. Your bid is held; outbid points return immediately. Winning points are spent.','membership_notice'=>'Membership starts only after an administrator verifies a real payment. There is no automatic payment or renewal. Cancellation keeps benefits through the paid term.','gives_notice'=>'Allocations use eligible RONI profit, after discounts, within the monthly cap. Refunded orders reverse their allocation.'] ;
    }

    public static function audit(int $actorId,string $action,string $subject,?int $id,array $payload): void
    {
        DB::table('roni_admin_actions')->insert(['actor_id'=>$actorId,'action'=>$action,'subject_type'=>$subject,'subject_id'=>$id,'payload'=>json_encode($payload),'created_at'=>now()]);
    }
}
