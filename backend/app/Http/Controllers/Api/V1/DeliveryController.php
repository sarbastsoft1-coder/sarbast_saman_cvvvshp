<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Notification;
use App\Services\CashService;
use App\Services\RoniEngine;
use App\Exceptions\CheckoutException;
use Illuminate\Support\Facades\DB;

class DeliveryController extends Controller
{
    public function tasks(Request $request)
    {
        $deliveries = Delivery::with('order.items.product', 'settlement')
            ->where(function ($query) use ($request) {
                $query->where('driver_id', $request->user()->id)
                    ->orWhere(fn ($available) => $available->whereNull('driver_id')->where('status', 'ready_for_pickup'));
            })->latest()->get();
        return response()->json([
            'status' => 'success',
            'data' => $deliveries,
        ]);
    }

    /**
     * Take responsibility for a job. Cash collected after this belongs to the
     * courier who claimed it, so the settlement is attributed correctly.
     */
    public function claim(Request $request, $id)
    {
        return DB::transaction(function () use ($request, $id) {
        $user = $request->user();
        $delivery = Delivery::with('order')->lockForUpdate()->findOrFail($id);

        if ($delivery->driver_id && $delivery->driver_id !== $user->id) {
            return response()->json([
                'status' => 'error',
                'message' => 'This job is already assigned to another courier.',
            ], 409);
        }

        if (in_array($delivery->status, ['delivered', 'cancelled', 'failed'], true)) {
            return response()->json([
                'status' => 'error',
                'message' => "A {$delivery->status} job cannot be claimed.",
            ], 422);
        }

        if ($delivery->driver_id === $user->id) {
            return response()->json(['status' => 'success', 'delivery' => $delivery->load('settlement')]);
        }
        abort_unless($delivery->status === 'ready_for_pickup', 422, 'This job is not ready to claim.');
        $delivery->update(['driver_id' => $user->id, 'status' => 'assigned']);

        if ($delivery->order) {
            $delivery->order->update(['status' => 'assigned']);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Job assigned to you.',
            'delivery' => $delivery->fresh(['order', 'settlement']),
        ]);
        });
    }

    /**
     * What the signed-in courier has collected and what they still owe across
     * every store.
     */
    public function earnings(Request $request)
    {
        $user = $request->user('sanctum') ?? $request->user();

        return response()->json([
            'status' => 'success',
            'data' => CashService::courierSummary($user->id),
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|string|in:picked_up,out_for_delivery,delivered,failed',
            'reason' => 'nullable|string|max:500',
            // What the customer actually handed over. Required when delivering,
            // because unrecorded cash is the one thing COD cannot recover later.
            'cash_collected' => 'nullable|numeric|min:0',
        ]);

        return DB::transaction(function () use ($request, $id) {
        $delivery = Delivery::with('order')->lockForUpdate()->findOrFail($id);
        abort_unless($delivery->driver_id === $request->user()->id, 404);
        $transitions = [
            'assigned' => ['picked_up', 'failed'],
            'picked_up' => ['out_for_delivery', 'failed'],
            'out_for_delivery' => ['delivered', 'failed'],
        ];
        abort_unless(in_array($request->status, $transitions[$delivery->status] ?? [], true), 422,
            'This delivery cannot move to the requested status.');

        if ($request->status === 'delivered') {
            if ($request->cash_collected === null) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Record how much cash the customer paid before marking delivered.',
                ], 422);
            }

            // Freeze the amount owed first, so the variance check compares like
            // with like even for a delivery dispatched before this existed.
            CashService::freezeAmountDue($delivery);

            try {
                $delivery = CashService::recordCollection(
                    $delivery,
                    (float) $request->cash_collected,
                    $request->input('reason'),
                );
            } catch (CheckoutException $e) {
                return response()->json(['status' => 'error', 'message' => $e->getMessage()], 422);
            }

            $delivery->update(['status' => 'delivered']);

            if ($delivery->order) {
                $delivery->order->update([
                    'status' => 'delivered',
                    'delivered_at' => now(),
                ]);

                Notification::send(
                    $delivery->order->customer_id,
                    'order',
                    'Order delivered',
                    'Order ' . $delivery->order->order_number . ' was delivered and paid for in cash.',
                    'Track order',
                    '/order-tracking',
                    ['orderId' => $delivery->order->order_number],
                );

                // Only now, with the order delivered and the cash actually
                // recorded, do the RONI commitments become real: Ronix are
                // granted and the RONI Gives allocation is booked.
                RoniEngine::settleOrder($delivery->order);

                $settled = $delivery->order->fresh();

                if ($settled->roni_status === 'awarded') {
                    Notification::send(
                        $settled->customer_id,
                        'ronix',
                        'Ronix earned',
                        'You earned ' . $settled->ronix_pending . ' Ronix from order '
                            . $settled->order_number . '.',
                        'Open Ronix',
                        '/coins',
                        null,
                    );
                }

                $contribution = DB::table('roni_contributions')
                    ->where('order_id', $settled->id)
                    ->where('status', 'allocated')
                    ->first();

                if ($contribution) {
                    Notification::send(
                        $settled->customer_id,
                        'gives',
                        'RONI Gives',
                        'Your purchase contributed to RONI Gives: '
                            . number_format($contribution->amount_minor / 100, 2) . '.',
                        'View project',
                        '/gives',
                        null,
                    );
                }
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Delivery completed and cash recorded.',
                'delivery' => $delivery->fresh(['order', 'settlement']),
                'cash_due' => $delivery->amount_due,
                'cash_variance' => $delivery->cashVariance(),
            ]);
        }

        if ($request->status === 'failed') {
            try {
                $delivery = CashService::markFailed($delivery, $request->input('reason'));
            } catch (CheckoutException $e) {
                return response()->json(['status' => 'error', 'message' => $e->getMessage()], 422);
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Delivery marked as failed.',
                'delivery' => $delivery->fresh(['order']),
            ]);
        }

        $delivery->update(['status' => $request->status]);

        if ($delivery->order) {
            $delivery->order->update(['status' => $request->status]);

            // Delivery progress is the thing a waiting customer cares about.
            Notification::send(
                $delivery->order->customer_id,
                'order',
                'Delivery update',
                'Your order ' . $delivery->order->order_number . ' is now '
                    .str_replace('_', ' ', $request->status).'.',
                'Track order',
                '/order-tracking',
                ['orderId' => $delivery->order->order_number],
            );
        }

        return response()->json([
            'status' => 'success',
            'message' => "Delivery status updated to {$request->status}",
            'delivery' => $delivery->fresh(),
        ]);
        });
    }

    public function updateLocation(Request $request, $id)
    {
        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);
        $delivery = Delivery::where('driver_id', $request->user()->id)->findOrFail($id);
        $delivery->update([
            'current_lat' => $request->lat,
            'current_lng' => $request->lng,
        ]);

        return response()->json([
            'status' => 'success',
            'delivery' => $delivery,
        ]);
    }
}
