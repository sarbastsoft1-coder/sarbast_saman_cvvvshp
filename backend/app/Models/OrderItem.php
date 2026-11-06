<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'product_id',
        'quantity',
        'unit_fiat',
        'unit_tokens',
        'total_fiat',
    ];

    protected $casts = [
        'quantity' => 'integer',
        'unit_fiat' => 'float',
        'unit_tokens' => 'float',
        'total_fiat' => 'float',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
