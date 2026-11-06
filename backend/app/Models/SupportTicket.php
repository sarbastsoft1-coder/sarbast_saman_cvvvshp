<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupportTicket extends Model
{
    protected $guarded = ['id'];
    public function user() { return $this->belongsTo(User::class)->select('id', 'name', 'email'); }
    public function messages() { return $this->hasMany(SupportMessage::class, 'ticket_id')->orderBy('id'); }
    public function order() { return $this->belongsTo(Order::class); }
}
