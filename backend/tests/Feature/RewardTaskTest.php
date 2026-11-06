<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RewardTaskTest extends TestCase
{
    use RefreshDatabase;

    public function test_task_rewards_require_admin_approval_and_are_only_paid_once(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'status' => 'active']);
        $customer = User::factory()->create(['role' => 'customer', 'status' => 'active']);
        $wallet = Wallet::create(['user_id' => $customer->id, 'token_balance' => 0, 'fiat_balance' => 0]);
        $this->getJson('/api/v1/reward-tasks')->assertUnauthorized();
        Sanctum::actingAs($customer);
        $payload = ['title' => 'Invite a friend', 'description' => 'Submit the invited account email.', 'reward_tokens' => 25];
        $this->postJson('/api/v1/admin/reward-tasks', $payload)->assertForbidden();
        Sanctum::actingAs($admin);
        $this->postJson('/api/v1/admin/reward-tasks', $payload + [])->assertCreated();
        $task = \App\Models\Challenge::firstOrFail();
        Sanctum::actingAs($customer);
        $this->postJson("/api/v1/reward-tasks/{$task->id}/submit", ['proof' => 'friend@example.com'])->assertOk();
        $this->postJson("/api/v1/reward-tasks/{$task->id}/submit", ['proof' => 'friend@example.com'])->assertStatus(409);
        $this->assertEquals(0, $wallet->fresh()->token_balance);
        $id = \Illuminate\Support\Facades\DB::table('task_submissions')->value('id');
        $this->postJson("/api/v1/admin/task-submissions/$id/review", ['decision' => 'approved'])->assertForbidden();
        Sanctum::actingAs($admin);
        $this->postJson("/api/v1/admin/task-submissions/$id/review", ['decision' => 'rejected'])->assertOk();
        $this->assertEquals(0, $wallet->fresh()->token_balance);
        Sanctum::actingAs($customer);
        $this->postJson("/api/v1/reward-tasks/{$task->id}/submit", ['proof' => 'corrected@example.com'])->assertOk();
        Sanctum::actingAs($admin);
        $this->postJson("/api/v1/admin/task-submissions/$id/review", ['decision' => 'approved'])->assertOk();
        $this->postJson("/api/v1/admin/task-submissions/$id/review", ['decision' => 'approved'])->assertStatus(409);
        $this->assertEquals(25, $wallet->fresh()->token_balance);
        $this->assertDatabaseCount('wallet_transactions', 1);
        Sanctum::actingAs($customer);
        $this->getJson('/api/v1/reward-tasks')->assertJsonPath('data.0.submission_status', 'approved')->assertJsonPath('balance', 25);
    }
}
