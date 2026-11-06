<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Cash-on-delivery accounting.
 *
 * With COD the courier takes the money in person, so the system has to record
 * what was actually collected, what the courier keeps, and what the store is
 * owed. `estimated_payout` was a display string ("$9.50 + 4 TERRA") and is
 * left in place for older rows; the real figures are the new columns.
 */
return new class extends Migration
{
    public function up(): void
    {
        // `settlements` is created first because `deliveries` points at it.
        Schema::create('settlements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('courier_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('store_id')->constrained()->cascadeOnDelete();

            // Cash the courier took on this store's behalf.
            $table->decimal('gross_cash', 12, 2)->default(0);
            // Commission the courier earned from those deliveries.
            $table->decimal('courier_commission', 12, 2)->default(0);
            // What the courier must hand over: gross minus commission.
            $table->decimal('net_to_store', 12, 2)->default(0);
            $table->decimal('refunded_cash', 12, 2)->default(0);

            // pending = courier still holds the money; paid = store has it.
            $table->string('status')->default('pending');
            $table->timestamp('settled_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['courier_id', 'store_id', 'status']);
        });

        Schema::table('deliveries', function (Blueprint $table) {
            // What the customer owed, frozen at dispatch so a later price change
            // or coupon cannot alter the amount the courier should collect.
            $table->decimal('amount_due', 12, 2)->nullable();

            // What the courier actually took. Null means "not recorded yet";
            // 0 means the customer genuinely paid nothing.
            $table->decimal('cash_collected', 12, 2)->nullable();
            $table->timestamp('cash_collected_at')->nullable();

            // Courier commission, as real numbers rather than a formatted string.
            $table->decimal('courier_payout', 12, 2)->default(0);
            $table->decimal('courier_payout_tokens', 12, 2)->default(0);

            // A delivery can fail: customer absent, refused, unreachable.
            $table->string('failure_reason')->nullable();
            $table->timestamp('failed_at')->nullable();

            $table->foreignId('settlement_id')
                ->nullable()
                ->constrained('settlements')
                ->nullOnDelete();
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->decimal('refunded_amount', 12, 2)->default(0);
            $table->timestamp('refunded_at')->nullable();
            $table->text('refund_reason')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['refunded_amount', 'refunded_at', 'refund_reason']);
        });

        Schema::table('deliveries', function (Blueprint $table) {
            $table->dropForeign(['settlement_id']);
            $table->dropColumn([
                'amount_due',
                'cash_collected',
                'cash_collected_at',
                'courier_payout',
                'courier_payout_tokens',
                'failure_reason',
                'failed_at',
                'settlement_id',
            ]);
        });

        Schema::dropIfExists('settlements');
    }
};