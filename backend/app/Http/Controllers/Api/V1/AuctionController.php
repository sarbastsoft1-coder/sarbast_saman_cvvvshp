<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Services\RoniEngine;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * RONI Auction.
 *
 * The clock and the winner are decided here, on the server, at the published
 * end time. The client only ever renders a countdown it was handed.
 */
class AuctionController extends Controller
{
    public function index()
    {
        // Closing first means a lot that ended while nobody was looking is
        // already settled by the time anyone reads the list.
        RoniEngine::closeAuctions();

        return response()->json([
            'status' => 'success',
            'data' => $this->list(),
            'policy' => ['auction_rules' => RoniEngine::policy()['auction_rules']],
        ]);
    }

    public function show(Request $request, $id)
    {
        RoniEngine::closeAuctions();

        $auction = $this->present(DB::table('roni_auctions as a')
            ->leftJoin('users as w', 'w.id', '=', 'a.winner_id')
            ->select('a.*', 'w.name as winner_name')
            ->where('a.id', $id)
            ->first());

        abort_if(!$auction, 404, 'Auction not found.');

        $user = $request->user('sanctum');

        $bids = DB::table('roni_bids as b')
            ->join('users as u', 'u.id', '=', 'b.user_id')
            ->select('b.id', 'b.amount', 'b.status', 'b.created_at', 'u.name as bidder_name')
            ->where('b.auction_id', $id)
            ->orderByDesc('b.amount')
            ->limit(50)
            ->get();

        $myBids = $user
            ? DB::table('roni_bids as b')
                ->select('b.id', 'b.amount', 'b.status', 'b.created_at')
                ->where('b.auction_id', $id)
                ->where('b.user_id', $user->id)
                ->orderByDesc('b.id')
                ->get()
            : collect();

        return response()->json([
            'status' => 'success',
            // Both the nested and the top-level shape are returned: the
            // bundled client reads `data.auction` but falls back to `data`,
            // and reads bids from the top level.
            'data' => ['auction' => $auction, 'bids' => $bids, 'my_bids' => $myBids],
            'auction' => $auction,
            'bids' => $bids,
            'my_bids' => $myBids,
        ]);
    }

    public function bid(Request $request, $id)
    {
        $data = $request->validate([
            'amount' => 'required|integer|min:1|max:100000000',
        ]);

        $user = $request->user('sanctum');
        $auction = RoniEngine::bid($user->id, (int) $id, (int) $data['amount']);

        Notification::send(
            $user->id,
            'auction',
            'Bid recorded',
            'Your bid of ' . $data['amount'] . ' Ronix on ' . $auction->title . ' is recorded.',
            'Open auction',
            '/auction',
            ['auctionId' => (int) $auction->id],
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Your bid is recorded and your Ronix are held until you are outbid.',
            'data' => $this->present($auction),
        ], 201);
    }

    /** Newest and soonest-ending lots, live ones first. */
    private function list(): array
    {
        return DB::table('roni_auctions as a')
            ->leftJoin('users as w', 'w.id', '=', 'a.winner_id')
            ->select('a.*', 'w.name as winner_name')
            ->whereIn('a.status', ['published', 'closed'])
            ->orderByRaw("CASE WHEN a.status = 'published' THEN 0 ELSE 1 END")
            ->orderBy('a.ends_at')
            ->get()
            ->map(fn ($row) => $this->present($row))
            ->all();
    }

    /**
     * Turns a stored lot into what the screen needs. The stored status is
     * draft/published/closed; the customer sees live/upcoming/ended/closed.
     */
    private function present(?object $row): ?array
    {
        if (!$row) {
            return null;
        }

        $status = $row->status;
        if ($status === 'published') {
            $status = now()->lt($row->starts_at)
                ? 'upcoming'
                : (now()->gte($row->ends_at) ? 'ended' : 'live');
        }

        $auction = (array) $row;
        $auction['id'] = (int) $auction['id'];
        $auction['status'] = $status;
        $auction['prize_value_minor'] = (int) $auction['prize_value_minor'];
        $auction['prize_cost_minor'] = (int) $auction['prize_cost_minor'];
        $auction['min_bid'] = (int) $auction['min_bid'];
        $auction['bid_increment'] = (int) $auction['bid_increment'];
        $auction['highest_bid'] = (int) $auction['highest_bid'];
        $auction['participant_count'] = (int) DB::table('roni_bids')
            ->where('auction_id', $auction['id'])
            ->distinct()
            ->count('user_id');

        return $auction;
    }
}
