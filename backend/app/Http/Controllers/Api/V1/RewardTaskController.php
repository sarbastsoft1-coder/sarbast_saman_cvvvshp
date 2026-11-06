<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Challenge;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RewardTaskController extends Controller
{
    private function admin(Request $request): void
    {
        abort_unless($request->user()->role === 'admin' && $request->user()->status === 'active', 403);
    }

    public function index(Request $request)
    {
        $submissions = DB::table('task_submissions')->where('user_id', $request->user()->id)->get()->keyBy('challenge_id');
        $tasks = Challenge::where('category', 'reward_task')->latest()->get()->map(function ($task) use ($submissions) {
            $task->submission_status = $submissions->get($task->id)?->status;
            return $task;
        });
        return response()->json(['status' => 'success', 'data' => $tasks, 'balance' => $request->user()->wallet?->token_balance ?? 0]);
    }

    public function create(Request $request)
    {
        $this->admin($request);
        $data = $request->validate([
            'title' => 'required|string|max:150',
            'description' => 'required|string|max:3000',
            'reward_tokens' => 'required|integer|min:1|max:100000',
        ]);
        $task = Challenge::create($data + ['category' => 'reward_task', 'target_count' => 1, 'icon' => '⭐']);
        return response()->json(['status' => 'success', 'data' => $task], 201);
    }

    public function submit(Request $request, Challenge $task)
    {
        abort_unless($request->user()->role === 'customer' && $request->user()->status === 'active', 403);
        abort_unless($task->category === 'reward_task', 404);
        $data = $request->validate(['proof' => 'required|string|min:5|max:3000']);
        DB::transaction(function () use ($request, $task, $data) {
            User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
            $query = DB::table('task_submissions')->where('user_id', $request->user()->id)->where('challenge_id', $task->id);
            $existing = $query->first();
            abort_if($existing && $existing->status !== 'rejected', 409, 'This task is already submitted or rewarded.');
            if ($existing) {
                $query->update(['proof' => $data['proof'], 'status' => 'pending', 'updated_at' => now()]);
            } else {
                DB::table('task_submissions')->insert(['user_id' => $request->user()->id, 'challenge_id' => $task->id, 'proof' => $data['proof'], 'status' => 'pending', 'created_at' => now(), 'updated_at' => now()]);
            }

            // An admin has to review this, so tell the admins there is a queue.
            foreach (DB::table('users')->where('role', 'admin')->where('status', 'active')->pluck('id') as $adminId) {
                Notification::send(
                    (int) $adminId,
                    'system',
                    'Reward task awaiting review',
                    "{$request->user()->name} submitted '{$task->title}'.",
                    'Review submissions',
                    '/reward-tasks',
                    null,
                );
            }
        });
        return response()->json(['status' => 'success']);
    }

    public function submissions(Request $request)
    {
        $this->admin($request);
        $rows = DB::table('task_submissions')->join('users', 'users.id', '=', 'task_submissions.user_id')->join('challenges', 'challenges.id', '=', 'task_submissions.challenge_id')
            ->where('task_submissions.status', 'pending')->select('task_submissions.*', 'users.name', 'users.email', 'challenges.title', 'challenges.reward_tokens')->orderBy('task_submissions.id')->get();
        return response()->json(['status' => 'success', 'data' => $rows]);
    }

    public function review(Request $request, int $submission)
    {
        $this->admin($request);
        $data = $request->validate(['decision' => 'required|in:approved,rejected']);
        DB::transaction(function () use ($submission, $data) {
            $row = DB::table('task_submissions')->where('id', $submission)->lockForUpdate()->first();
            abort_unless($row, 404);
            abort_unless($row->status === 'pending', 409, 'This submission has already been reviewed.');
            if ($data['decision'] === 'approved') {
                $task = Challenge::findOrFail($row->challenge_id);
                $wallet = DB::table('wallets')->where('user_id', $row->user_id)->lockForUpdate()->first();
                abort_unless($wallet, 422, 'The customer needs a wallet before approval.');
                DB::table('wallets')->where('id', $wallet->id)->increment('token_balance', $task->reward_tokens, ['updated_at' => now()]);
                $balance = DB::table('wallets')->where('id', $wallet->id)->value('token_balance');
                DB::table('wallet_transactions')->insert(['wallet_id' => $wallet->id, 'type' => 'credit', 'currency' => 'TERRA', 'amount' => $task->reward_tokens, 'balance_after' => $balance, 'reference_type' => 'task_reward', 'reference_id' => (string) $row->id, 'description' => $task->title, 'created_at' => now(), 'updated_at' => now()]);

                Notification::send(
                    (int) $row->user_id,
                    'system',
                    'Reward approved',
                    "'{$task->title}' was approved and {$task->reward_tokens} TERRA was added to your wallet.",
                    'Open tasks',
                    '/reward-tasks',
                    null,
                );
            }
            DB::table('task_submissions')->where('id', $row->id)->update(['status' => $data['decision'], 'updated_at' => now()]);
        });
        return response()->json(['status' => 'success']);
    }
}
