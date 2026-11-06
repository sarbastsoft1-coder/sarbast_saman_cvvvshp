<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'title',
        'body',
        'action_label',
        'action_route',
        'action_args',
        'read_at',
    ];

    protected $casts = [
        'action_args' => 'array',
        'read_at' => 'datetime',
    ];

    /** Keeps unread feeds cheap to count. */
    protected $withCount = [];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function isRead(): bool
    {
        return $this->read_at !== null;
    }

    /**
     * Record a notification for a user, skipping duplicates that would say the
     * same thing twice.
     *
     * Named `send` rather than `push` because Eloquent's Model already defines
     * a non-static `push()` for saving a dirty model.
     *
     * @param  array<string, mixed>|null  $args
     */
    public static function send(
        int $userId,
        string $type,
        string $title,
        string $body,
        ?string $actionLabel = null,
        ?string $actionRoute = null,
        ?array $args = null,
    ): ?self {
        // A status can be retried or double-submitted; the recipient should not
        // see the same "your order shipped" message three times.
        $duplicate = self::where('user_id', $userId)
            ->where('type', $type)
            ->where('title', $title)
            ->where('created_at', '>=', now()->subDay())
            ->exists();

        if ($duplicate) {
            return null;
        }

        return self::create([
            'user_id' => $userId,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'action_label' => $actionLabel,
            'action_route' => $actionRoute,
            'action_args' => $args,
        ]);
    }
}
