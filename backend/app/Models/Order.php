<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_number',
        'customer_id',
        'store_id',
        'coupon_id',
        'total_fiat',
        'total_tokens',
        'discount_amount',
        'delivery_fee',
        'payment_method',
        'status',
        'shipping_address',
        'shipping_lat',
        'shipping_lng',
        'cancelled_at',
        'delivered_at',
        'cancel_reason',
        'refunded_amount',
        'refunded_at',
        'refund_reason',
        // Ronix and RONI Gives are frozen at checkout and only settled after
        // the order is delivered and paid, so a refund can reverse exactly
        // what was committed.
        'ronix_pending',
        'gives_pending_minor',
        'roni_status',
    ];

    protected $casts = [
        'total_fiat' => 'float',
        'total_tokens' => 'float',
        'discount_amount' => 'float',
        'delivery_fee' => 'float',
        'refunded_amount' => 'float',
        'shipping_lat' => 'float',
        'shipping_lng' => 'float',
        'cancelled_at' => 'datetime',
        'delivered_at' => 'datetime',
        'refunded_at' => 'datetime',
    ];

    /** Statuses that may no longer be modified or cancelled. */
    public const LOCKED_STATUSES = [
        'out_for_delivery',
        'picked_up',
        'delivered',
        'cancelled',
        'refunded',
        'delivery_failed',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function coupon()
    {
        return $this->belongsTo(Coupon::class);
    }

    public function isCancellable(): bool
    {
        return !in_array($this->status, self::LOCKED_STATUSES, true)
            && $this->cancelled_at === null;
    }

    /** Cash actually taken on this order, once a courier has recorded it. */
    public function cashCollected(): ?float
    {
        return $this->delivery?->cash_collected;
    }

    /** True while the order can still be refunded to the customer. */
    public function isRefundable(): bool
    {
        if (in_array($this->status, ['refunded', 'cancelled'], true)) {
            return false;
        }

        // Only a completed or failed delivery leaves anything to refund. An
        // order still in the warehouse has not been paid for yet.
        return in_array($this->status, ['delivered', 'delivery_failed'], true);
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function delivery()
    {
        return $this->hasOne(Delivery::class);
    }
}
