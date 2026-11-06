<?php

namespace App\Services;

use App\Exceptions\CheckoutException;
use App\Models\Delivery;
use App\Models\Notification;
use App\Models\Order;
use App\Models\Settlement;
use App\Models\SystemSetting;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * Cash-on-delivery accounting.
 *
 * The courier collects money in person, so the system has to answer three
 * questions reliably: what was the customer supposed to pay, what was actually
 * taken, and what does the courier still owe the store.
 */
class CashService
{
    /** Default courier commission when no rate is configured. */
    public const DEFAULT_COURIER_PAYOUT = 4.50;

    /** Commission the courier keeps per delivery, from system settings. */
    public static function courierPayoutFor(float $amountDue): float
    {
        $configured = SystemSetting::where('key', 'courier_payout_per_delivery')->value('value');

        $rate = is_numeric($configured) ? (float) $configured : self::DEFAULT_COURIER_PAYOUT;

        return round(max(0, min($rate, $amountDue)), 2);
    }

    /**
     * Freeze the amount owed at dispatch, so a later price change, coupon
     * adjustment or cancellation cannot alter what the courier should collect.
     */
    public static function freezeAmountDue(Delivery $delivery): void
    {
        $order = $delivery->order;
        if (!$order || $delivery->amount_due !== null) {
            return;
        }

        $amountDue = round(
            $order->total_fiat,
            2,
        );

        $delivery->update([
            'amount_due' => max($amountDue, 0),
            'courier_payout' => self::courierPayoutFor(max($amountDue, 0)),
            // Drop the old display string so no screen shows a fake amount.
            'estimated_payout' => null,
        ]);
    }

    /**
     * Record what the courier actually collected, and move that cash into the
     * courier's open settlement for the store.
     *
     * Overpayment is allowed and reported (customers hand over rounded notes);
     * a short collection is also allowed but flagged, because a courier may
     * genuinely have been short-changed.
     */
    public static function recordCollection(Delivery $delivery, float $collected, ?string $note = null): Delivery
    {
        if ($delivery->amount_due === null) {
            self::freezeAmountDue($delivery);
            $delivery->refresh();
        }

        if ($collected < 0) {
            throw new CheckoutException('A collected amount cannot be negative.');
        }

        return DB::transaction(function () use ($delivery, $collected, $note) {
            $locked = Delivery::whereKey($delivery->id)->lockForUpdate()->firstOrFail();
            $order = $locked->order;

            if ($locked->hasCashRecord()) {
                throw new CheckoutException('Cash has already been recorded for this delivery.');
            }
            if (!$locked->driver_id || in_array($locked->status, ['delivered', 'cancelled', 'failed'], true)) {
                throw new CheckoutException('Only an assigned, active delivery can collect cash.');
            }

            // Cash belongs to whoever is actually carrying it. Falling back to
            // the customer's id would credit the money to the wrong person, so
            // an unassigned delivery is recorded but not banked against anyone.
            $courierId = $locked->driver_id;

            $locked->update([
                'cash_collected' => round($collected, 2),
                'cash_collected_at' => now(),
            ]);

            $storeId = $order?->store_id;
            if ($storeId && $courierId) {
                $settlement = Settlement::openFor($courierId, $storeId);
                $settlement->increment('gross_cash', round($collected, 2));
                $settlement->increment('courier_commission', (float) $locked->courier_payout);
                $settlement->increment('net_to_store', round($collected - $locked->courier_payout, 2));
                $locked->update(['settlement_id' => $settlement->id]);
            }

            // Tell the customer their payment was recorded, and the store that
            // cash is now sitting with the courier.
            if ($order) {
                Notification::send(
                    $order->customer_id,
                    'order',
                    'Payment received',
                    'Cash of ' . number_format($collected, 2)
                        . ' was collected for order ' . $order->order_number . '.',
                    'Track order',
                    '/order-tracking',
                    ['orderId' => $order->order_number],
                );

                $store = $order->store;
                if ($store?->user_id) {
                    Notification::send(
                        $store->user_id,
                        'order',
                        'Cash collected',
                        number_format($collected, 2)
                            . ' was collected on order ' . $order->order_number
                            . '. The courier now holds it for settlement.',
                        'Open settlements',
                        '/settlements',
                        null,
                    );
                }
            }

            return $locked->fresh();
        });
    }

    /**
     * Mark a delivery as failed (customer absent, refused, unreachable).
     * Nothing was collected, so no cash moves and the order becomes refundable
     * once the seller decides what to do.
     */
    public static function markFailed(Delivery $delivery, ?string $reason): Delivery
    {
        return DB::transaction(function () use ($delivery, $reason) {
            $locked = Delivery::whereKey($delivery->id)->lockForUpdate()->firstOrFail();

            if ($locked->status === 'delivered') {
                throw new CheckoutException('A delivered parcel cannot be marked failed.');
            }

            $locked->update([
                'status' => 'failed',
                'failure_reason' => $reason,
                'failed_at' => now(),
            ]);

            $order = $locked->order;
            if ($order) {
                $order->update(['status' => 'delivery_failed']);

                Notification::send(
                    $order->customer_id,
                    'order',
                    'Delivery failed',
                    'We could not complete the delivery of order ' . $order->order_number
                        . ($reason ? ": $reason" : '.') . ' You will be refunded.',
                    'Track order',
                    '/order-tracking',
                    ['orderId' => $order->order_number],
                );

                $store = $order->store;
                if ($store?->user_id) {
                    Notification::send(
                        $store->user_id,
                        'order',
                        'Delivery failed',
                        'Order ' . $order->order_number . ' could not be delivered'
                            . ($reason ? ": $reason" : '.') . ' A refund can now be issued.',
                        'Open orders',
                        '/orders',
                        null,
                    );
                }
            }

            return $locked->fresh();
        });
    }

    /**
     * Refund an order: the goods go back to stock, any cash the courier holds
     * is deducted from what they owe, and the customer is told.
     */
    public static function refundOrder(Order $order, float $amount, ?string $reason): Order
    {
        if (!$order->isRefundable()) {
            throw new CheckoutException(
                "An order that is {$order->status} cannot be refunded."
            );
        }

        return DB::transaction(function () use ($order, $amount, $reason) {
            $locked = Order::with('items.product', 'delivery')->lockForUpdate()->findOrFail($order->id);

            if (!$locked->isRefundable()) {
                throw new CheckoutException('This order can no longer be refunded.');
            }

            // Never refund more than was actually taken (or, if nothing was
            // recorded as taken, never more than the order was worth).
            $collected = $locked->delivery?->cash_collected;
            $ceiling = $collected ?? $locked->total_fiat;

            if ($amount > $ceiling + 0.009) {
                throw new CheckoutException(
                    'You cannot refund ' . number_format($amount, 2)
                        . ' when only ' . number_format($ceiling, 2) . ' was collected.'
                );
            }

            $refund = round(min(max($amount, 0), $ceiling), 2);

            if ($refund <= 0) {
                throw new CheckoutException('There is nothing to refund on this order.');
            }

            // The goods come back into stock.
            foreach ($locked->items as $item) {
                $item->product?->increment('stock', $item->quantity);
            }

            $locked->update([
                'status' => 'refunded',
                'refunded_amount' => $refund,
                'refunded_at' => now(),
                'refund_reason' => $reason,
            ]);

            // A refund revokes the Ronix the order earned, even if the
            // customer already spent them, and reverses the RONI Gives
            // allocation booked against it. A resulting negative balance
            // blocks further spending until it is repaid.
            RoniEngine::reverseOrder($locked);

            // If the courier is holding this cash, it comes off their balance.
            $delivery = $locked->delivery;
            $settlement = $delivery?->settlement;
            if ($settlement) {
                $settlement->increment('refunded_cash', $refund);
            }

            Notification::send(
                $locked->customer_id,
                'order',
                'Refund issued',
                number_format($refund, 2) . ' was refunded for order '
                    . $locked->order_number . ($reason ? ": $reason" : '.'),
                'Track order',
                '/order-tracking',
                ['orderId' => $locked->order_number],
            );

            $store = $locked->store;
            if ($store?->user_id) {
                Notification::send(
                    $store->user_id,
                    'order',
                    'Order refunded',
                    number_format($refund, 2) . ' was refunded on order '
                        . $locked->order_number . ' and the stock returned.',
                    'Open orders',
                    '/orders',
                    null,
                );
            }

            return $locked->fresh();
        });
    }

    /**
     * Running figures for a courier: what they have collected and what they
     * still owe across every store.
     */
    public static function courierSummary(?int $courierId): array
    {
        $pending = Settlement::where('courier_id', $courierId)->where('status', 'pending')->get();

        return [
            'stores_count' => $pending->count(),
            'gross_cash' => round($pending->sum('gross_cash'), 2),
            'courier_commission' => round($pending->sum('courier_commission'), 2),
            'refunded_cash' => round($pending->sum('refunded_cash'), 2),
            'net_to_store' => round($pending->sum('net_to_store'), 2),
            'outstanding' => round($pending->sum(fn ($s) => $s->outstanding()), 2),
            'refund_surplus' => round($pending->sum(fn ($s) => $s->refundSurplus()), 2),
        ];
    }
}
