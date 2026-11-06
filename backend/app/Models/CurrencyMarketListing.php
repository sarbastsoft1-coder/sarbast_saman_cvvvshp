<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CurrencyMarketListing extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'token_amount',
        'rate_fiat',
        'filled_amount',
        'status',
    ];

    protected $casts = [
        'token_amount' => 'float',
        'rate_fiat' => 'float',
        'filled_amount' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
