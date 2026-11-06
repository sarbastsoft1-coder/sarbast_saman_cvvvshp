<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupportMessage extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['is_staff' => 'boolean'];
    public function author() { return $this->belongsTo(User::class, 'author_id')->select('id', 'name'); }
}
