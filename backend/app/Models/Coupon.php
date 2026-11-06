<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Coupon extends Model
{
    use HasFactory;

    protected $fillable = [
        'code',
        'type',
        'value',
        'min_spend',
        'expires_at',
        'is_active',
    ];

    protected $casts = [
        'value' => 'float',
        'min_spend' => 'float',
        'expires_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function isValid(): bool
    {
        return $this->is_active
            && ($this->expires_at === null || $this->expires_at->isFuture());
    }

    /**
     * Discount for a given subtotal. Never returns a negative amount, and a
     * free-shipping coupon is reported as 0 here so the caller applies it to
     * the delivery fee instead of the goods total.
     */
    public function discountFor(float $subtotal): float
    {
        if ($subtotal < $this->min_spend) {
            return 0.0;
        }

        return match ($this->type) {
            'percent' => round($subtotal * ($this->value / 100), 2),
            'fixed' => min($this->value, $subtotal),
            'free_shipping' => 0.0,
            default => 0.0,
        };
    }

    public function coversDelivery(): bool
    {
        return $this->type === 'free_shipping';
    }
}
