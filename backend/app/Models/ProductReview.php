<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProductReview extends Model
{
    protected $guarded = ['id'];

    protected $casts = ['photos' => 'array', 'verified_purchase' => 'boolean', 'rating' => 'integer', 'seller_rating' => 'integer', 'moderated_at' => 'datetime'];

    public function customer() { return $this->belongsTo(User::class, 'customer_id')->select('id', 'name'); }
    public function product() { return $this->belongsTo(Product::class); }
    public function votes() { return $this->hasMany(ReviewHelpfulVote::class, 'review_id'); }
}
