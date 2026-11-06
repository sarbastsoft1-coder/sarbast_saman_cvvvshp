<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\CheckoutException;
use App\Http\Controllers\Controller;
use App\Models\{Notification, Order, Product, ProductReview, ReturnRequest, ReviewHelpfulVote, Store, SupportMessage, SupportTicket, User};
use App\Services\{CashService, RoniEngine};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MarketplaceController extends Controller
{
    private function reviews()
    {
        return ProductReview::with('customer:id,name,avatar', 'product')->withCount(['votes as helpful_count']);
    }

    public function productReviews(int $id)
    {
        Product::where('status', 'active')->findOrFail($id);
        $query = $this->reviews()->where('product_id', $id)->where('status', 'published');
        return response()->json(['status' => 'success', 'data' => (clone $query)->latest()->limit(100)->get(), 'summary' => [
            'average' => round((float) (clone $query)->avg('rating'), 2), 'count' => (clone $query)->count(),
        ]]);
    }

    public function myReviews(Request $request)
    {
        return $this->ok($this->reviews()->where('customer_id', $request->user()->id)->latest()->get());
    }

    public function sellerReviews(Request $request)
    {
        $store = Store::where('user_id', $request->user()->id)->firstOrFail();
        return $this->ok($this->reviews()->where('store_id', $store->id)->where('status', 'published')->latest()->get());
    }

    public function adminReviews()
    {
        return $this->ok($this->reviews()->latest()->limit(500)->get());
    }

    public function createReview(Request $request)
    {
        $data = $request->validate([
            'order_id' => 'required|integer', 'product_id' => 'required|integer',
            'rating' => 'required|integer|min:1|max:5', 'seller_rating' => 'nullable|integer|min:1|max:5',
            'body' => 'required|string|min:5|max:4000', 'photos' => 'nullable|array|max:5',
            'photos.*' => 'required|url:https|max:2048',
        ]);
        return DB::transaction(function () use ($request, $data) {
            // A customer lock serializes duplicate submissions and reward issuance.
            User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
            $order = Order::where('customer_id', $request->user()->id)->lockForUpdate()->findOrFail($data['order_id']);
            abort_unless($order->status === 'delivered', 422, 'Only delivered purchases can be reviewed.');
            abort_unless($order->items()->where('product_id', $data['product_id'])->exists(), 422, 'This product is not part of that order.');
            abort_if(ProductReview::where('customer_id', $request->user()->id)->where('product_id', $data['product_id'])->exists(), 409, 'You have already reviewed this product.');
            $review = ProductReview::create($data + ['customer_id' => $request->user()->id, 'store_id' => $order->store_id, 'verified_purchase' => true]);
            $this->refreshRatings($review);
            $rewarded = app(RoniEngine::class)->grantReview($request->user()->id, $review->id);
            return response()->json(['status' => 'success', 'data' => $this->reviews()->findOrFail($review->id), 'reward_granted' => $rewarded], 201);
        });
    }

    public function helpful(Request $request, int $id)
    {
        $review = ProductReview::where('status', 'published')->findOrFail($id);
        abort_if($review->customer_id === $request->user()->id, 422, 'You cannot vote for your own review.');
        ReviewHelpfulVote::firstOrCreate(['review_id' => $review->id, 'user_id' => $request->user()->id]);
        return $this->ok(['helpful_count' => $review->votes()->count()]);
    }

    public function moderate(Request $request, int $id)
    {
        $data = $request->validate(['status' => 'required|in:published,hidden']);
        return DB::transaction(function () use ($request, $data, $id) {
            $review = ProductReview::lockForUpdate()->findOrFail($id);
            $review->update($data + ['moderated_by' => $request->user()->id, 'moderated_at' => now()]);
            $this->refreshRatings($review);
            return $this->ok($review);
        });
    }

    private function refreshRatings(ProductReview $review): void
    {
        Product::whereKey($review->product_id)->update(['rating' => round((float) ProductReview::where('product_id', $review->product_id)->where('status', 'published')->avg('rating'), 2)]);
        Store::whereKey($review->store_id)->update(['rating' => round((float) ProductReview::where('store_id', $review->store_id)->where('status', 'published')->whereNotNull('seller_rating')->avg('seller_rating'), 2)]);
    }

    private function returns()
    {
        return ReturnRequest::with('order.items.product', 'order.delivery', 'customer');
    }

    public function myReturns(Request $request)
    {
        return $this->ok($this->returns()->where('customer_id', $request->user()->id)->latest()->get());
    }

    public function sellerReturns(Request $request)
    {
        return $this->ok($this->returns()->whereHas('order.store', fn ($query) => $query->where('user_id', $request->user()->id))->latest()->get());
    }

    public function adminReturns()
    {
        return $this->ok($this->returns()->latest()->limit(500)->get());
    }

    public function requestReturn(Request $request)
    {
        $data = $request->validate([
            'order_id' => 'required|integer', 'reason' => 'required|string|min:3|max:150',
            'details' => 'nullable|string|max:4000', 'evidence_urls' => 'nullable|array|max:5',
            'evidence_urls.*' => 'required|url:https|max:2048',
        ]);
        return DB::transaction(function () use ($request, $data) {
            $order = Order::where('customer_id', $request->user()->id)->lockForUpdate()->findOrFail($data['order_id']);
            abort_unless($order->isRefundable(), 422, 'Returns are available after delivery or failed delivery.');
            abort_if(ReturnRequest::where('order_id', $order->id)->exists(), 409, 'A return request already exists for this order.');
            $return = ReturnRequest::create($data + ['customer_id' => $request->user()->id]);
            Notification::send($request->user()->id, 'order', "Return request #{$return->id} received", "We are reviewing your return for {$order->order_number}.");
            if ($order->store?->user_id) {
                Notification::send($order->store->user_id, 'order', "Return request #{$return->id}", "A return was requested for {$order->order_number}: {$data['reason']}");
            }
            return response()->json(['status' => 'success', 'data' => $return->load('order.items.product')], 201);
        });
    }

    public function decideReturn(Request $request, int $id)
    {
        $data = $request->validate([
            'decision' => 'required|in:approved,rejected,refunded', 'note' => 'nullable|string|max:4000',
            'refund_amount' => 'required_if:decision,refunded|nullable|numeric|min:0.01',
        ]);
        try {
            return DB::transaction(function () use ($request, $data, $id) {
                $return = ReturnRequest::lockForUpdate()->findOrFail($id);
                $next = $data['decision'];
                $valid = $return->status === 'pending' && in_array($next, ['approved', 'rejected'], true)
                    || $return->status === 'approved' && $next === 'refunded';
                abort_unless($valid, 409, 'This return has already been decided or is not approved for a refund.');
                $amount = null;
                if ($next === 'refunded') {
                    $order = Order::lockForUpdate()->findOrFail($return->order_id);
                    $refunded = CashService::refundOrder($order, (float) $data['refund_amount'], $data['note'] ?? $return->reason);
                    $amount = $refunded->refunded_amount;
                }
                $return->update(['status' => $next, 'decision_note' => $data['note'] ?? null,
                    'refund_amount' => $amount, 'decided_by' => $request->user()->id, 'decided_at' => now()]);
                Notification::send($return->customer_id, 'order', "Return #{$return->id} {$next}", $data['note'] ?? "Your return request is now {$next}.");
                return $this->ok($return->load('order.items.product', 'customer'));
            });
        } catch (CheckoutException $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 422);
        }
    }

    private function tickets()
    {
        return SupportTicket::with('user', 'messages.author')->orderByDesc('updated_at');
    }

    public function myTickets(Request $request)
    {
        return $this->ok($this->tickets()->where('user_id', $request->user()->id)->get());
    }

    public function adminTickets()
    {
        return $this->ok($this->tickets()->limit(500)->get());
    }

    public function createTicket(Request $request)
    {
        $data = $request->validate([
            'subject' => 'required|string|min:3|max:150', 'category' => 'required|in:order,return,payment,delivery,account,other',
            'order_id' => 'nullable|integer', 'message' => 'required|string|min:3|max:4000',
        ]);
        if (!empty($data['order_id'])) {
            $query = Order::whereKey($data['order_id']);
            if ($request->user()->role === 'seller') {
                $query->whereHas('store', fn ($q) => $q->where('user_id', $request->user()->id));
            } else {
                $query->where('customer_id', $request->user()->id);
            }
            $query->firstOrFail();
        }
        return DB::transaction(function () use ($request, $data) {
            $ticket = SupportTicket::create(['user_id' => $request->user()->id, 'order_id' => $data['order_id'] ?? null,
                'subject' => $data['subject'], 'category' => $data['category'], 'status' => 'open']);
            $ticket->messages()->create(['author_id' => $request->user()->id, 'body' => $data['message'], 'is_staff' => false]);
            return response()->json(['status' => 'success', 'data' => $ticket->load('messages.author', 'user')], 201);
        });
    }

    public function reply(Request $request, int $id)
    {
        $data = $request->validate(['message' => 'required|string|min:1|max:4000', 'status' => 'nullable|in:open,resolved']);
        return DB::transaction(function () use ($request, $data, $id) {
            $ticket = SupportTicket::lockForUpdate()->findOrFail($id);
            $staff = $request->user()->role === 'admin';
            abort_unless($staff || $ticket->user_id === $request->user()->id, 404);
            $ticket->messages()->create(['author_id' => $request->user()->id, 'body' => $data['message'], 'is_staff' => $staff]);
            $ticket->update(['status' => $staff ? ($data['status'] ?? 'open') : 'open', 'updated_at' => now()]);
            if ($staff) {
                Notification::send($ticket->user_id, 'support', "Support replied to #{$ticket->id}", "You have a new reply about {$ticket->subject}.");
            }
            return $this->ok($ticket->load('messages.author', 'user'));
        });
    }

    public function ticketStatus(Request $request, int $id)
    {
        $data = $request->validate(['status' => 'required|in:open,resolved']);
        $ticket = SupportTicket::findOrFail($id);
        $ticket->update($data);
        return $this->ok($ticket->load('messages.author', 'user'));
    }

    private function ok($data)
    {
        return response()->json(['status' => 'success', 'data' => $data]);
    }
}
