<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Delivery extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'driver_id',
        'settlement_id',
        'status',
        'pickup_store_name',
        'pickup_address',
        'estimated_pickup_time',
        'customer_name',
        'dropoff_address',
        'estimated_delivery_time',
        'distance',
        'estimated_payout',
        'pickup_lat',
        'pickup_lng',
        'dropoff_lat',
        'dropoff_lng',
        'current_lat',
        'current_lng',
        'waypoints',
        'amount_due',
        'cash_collected',
        'cash_collected_at',
        'courier_payout',
        'courier_payout_tokens',
        'failure_reason',
        'failed_at',
    ];

    protected $casts = [
        'pickup_lat' => 'float',
        'pickup_lng' => 'float',
        'dropoff_lat' => 'float',
        'dropoff_lng' => 'float',
        'current_lat' => 'float',
        'current_lng' => 'float',
        'waypoints' => 'array',
        'amount_due' => 'float',
        'cash_collected' => 'float',
        'courier_payout' => 'float',
        'courier_payout_tokens' => 'float',
        'cash_collected_at' => 'datetime',
        'failed_at' => 'datetime',
    ];

    /**
     * Legacy display string from before cash was tracked ("$9.50 + 4 TERRA").
     * It was never a real figure, so it is hidden rather than shown as if it
     * were money. Use `courier_payout` or `amount_due` instead.
     */
    protected $hidden = ['estimated_payout'];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function settlement()
    {
        return $this->belongsTo(Settlement::class);
    }

    /** True once someone has recorded what the customer actually paid. */
    public function hasCashRecord(): bool
    {
        return $this->cash_collected !== null;
    }

    /**
     * Cash still unaccounted for on this delivery: what was due minus what was
     * taken. Positive means the courier is short; negative means overpaid.
     */
    public function cashVariance(): ?float
    {
        if ($this->amount_due === null || $this->cash_collected === null) {
            return null;
        }

        return round($this->cash_collected - $this->amount_due, 2);
    }
}
