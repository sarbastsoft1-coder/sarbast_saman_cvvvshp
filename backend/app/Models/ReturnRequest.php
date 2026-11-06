<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReturnRequest extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['evidence_urls' => 'array', 'refund_amount' => 'float', 'decided_at' => 'datetime'];
    public function order() { return $this->belongsTo(Order::class); }
    public function customer() { return $this->belongsTo(User::class, 'customer_id')->select('id', 'name', 'email'); }
}
