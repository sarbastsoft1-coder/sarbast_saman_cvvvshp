<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Server-authoritative notification feed.
     *
     * Notifications are rows in this table rather than a push service: clients
     * poll for new rows, which needs no third-party account, no SDK and no
     * device registration. The `data` column carries the route arguments a
     * client needs to open the right screen.
     */
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type')->default('system'); // order, promo, system, new_product
            $table->string('title');
            $table->text('body');
            $table->string('action_label')->nullable();
            $table->string('action_route')->nullable();
            $table->json('action_args')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            // The feed is always read newest-first for one user.
            $table->index(['user_id', 'created_at']);
            // Polling asks for "anything after id X"; this keeps that fast.
            $table->index(['user_id', 'id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
