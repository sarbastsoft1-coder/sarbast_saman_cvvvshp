<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Challenge extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'icon',
        'target_count',
        'reward_tokens',
        'category',
    ];

    protected $casts = [
        'reward_tokens' => 'float',
        'target_count' => 'integer',
    ];

    public function userChallenges()
    {
        return $this->hasMany(UserChallenge::class);
    }
}
