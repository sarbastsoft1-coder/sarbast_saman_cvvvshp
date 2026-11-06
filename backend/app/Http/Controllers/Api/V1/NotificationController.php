<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Notification;

/**
 * The notification feed.
 *
 * Clients poll this rather than registering with a push service, so there is
 * no third-party SDK, no device token and no per-platform setup. `since_id`
 * lets a client ask only for rows it has not seen, which keeps the poll small.
 */
class NotificationController extends Controller
{
    /**
     * Newest-first feed for the signed-in user.
     *
     * Pass `since_id` to get only newer rows (what a polling client wants), or
     * `unread_only=1` for the badge count.
     */
    public function index(Request $request)
    {
        $user = $request->user('sanctum') ?? $request->user();
        $query = Notification::where('user_id', $user->id);

        if ($request->filled('since_id')) {
            $query->where('id', '>', (int) $request->since_id);
        }

        if ($request->boolean('unread_only')) {
            $query->whereNull('read_at');
        }

        $limit = min(max((int) $request->input('limit', 50), 1), 200);

        return response()->json([
            'status' => 'success',
            'data' => $query->latest('id')->take($limit)->get(),
            'unread_count' => Notification::where('user_id', $user->id)
                ->whereNull('read_at')
                ->count(),
            // Lets a polling client remember its cursor between requests.
            'latest_id' => (int) Notification::where('user_id', $user->id)->max('id'),
        ]);
    }

    public function markAsRead(Request $request, $id)
    {
        $user = $request->user('sanctum') ?? $request->user();

        $notification = Notification::where('user_id', $user->id)->find($id);

        if (!$notification) {
            return response()->json(['status' => 'error', 'message' => 'Notification not found.'], 404);
        }

        if ($notification->read_at === null) {
            $notification->update(['read_at' => now()]);
        }

        return response()->json(['status' => 'success', 'notification' => $notification->fresh()]);
    }

    public function markAllAsRead(Request $request)
    {
        $user = $request->user('sanctum') ?? $request->user();

        $count = Notification::where('user_id', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'status' => 'success',
            'message' => 'All notifications marked as read.',
            'updated' => $count,
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $user = $request->user('sanctum') ?? $request->user();

        $deleted = Notification::where('user_id', $user->id)->where('id', $id)->delete();

        if (!$deleted) {
            return response()->json(['status' => 'error', 'message' => 'Notification not found.'], 404);
        }

        return response()->json(['status' => 'success', 'message' => 'Notification removed.']);
    }
}
