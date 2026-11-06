<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * A batch of cash one courier collected on behalf of one store, pending
 * handover. With cash on delivery the courier holds the store's money between
 * collection and settlement, so both sides need a running figure.
 */
class Settlement extends Model
{
    use HasFactory;

    protected $fillable = [
        'courier_id',
        'store_id',
        'gross_cash',
        'courier_commission',
        'net_to_store',
        'refunded_cash',
        'status',
        'settled_at',
        'notes',
    ];

    protected $casts = [
        'gross_cash' => 'float',
        'courier_commission' => 'float',
        'net_to_store' => 'float',
        'refunded_cash' => 'float',
        'settled_at' => 'datetime',
    ];

    /**
     * Money the courier still owes this store.
     *
     * Never negative: when refunds exceed the cash actually collected (for
     * example an order was collected in part and then fully refunded), the
     * store owes the courier the difference rather than the reverse.
     */
    public function outstanding(): float
    {
        if ($this->status !== 'pending') {
            return 0.0;
        }

        return round(max($this->net_to_store - $this->refunded_cash, 0), 2);
    }

    /** True when refunds exceeded what the courier collected. */
    public function hasRefundSurplus(): bool
    {
        return $this->status === 'pending'
            && $this->refunded_cash - $this->net_to_store > 0.009;
    }

    /** Money the store owes back to the courier. */
    public function refundSurplus(): float
    {
        return $this->hasRefundSurplus()
            ? round($this->refunded_cash - $this->net_to_store, 2)
            : 0.0;
    }

    public function courier()
    {
        return $this->belongsTo(User::class, 'courier_id');
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function deliveries()
    {
        return $this->hasMany(Delivery::class);
    }

    /**
     * Find the open settlement a courier should be paid into for a store,
     * creating it on first use so there is always exactly one bucket per pair.
     */
    public static function openFor(int $courierId, int $storeId): self
    {
        return self::firstOrCreate(
            ['courier_id' => $courierId, 'store_id' => $storeId, 'status' => 'pending'],
            ['gross_cash' => 0, 'courier_commission' => 0, 'net_to_store' => 0, 'refunded_cash' => 0],
        );
    }
}