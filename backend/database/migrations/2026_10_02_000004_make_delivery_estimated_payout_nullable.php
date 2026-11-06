<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Let `deliveries.estimated_payout` be null.
 *
 * The cash-on-delivery work replaced that column's formatted "$9.50 + 4 TERRA"
 * display string with the real `amount_due` / `courier_payout` numbers, and
 * `CashService::freezeAmountDue()` nulls the old string so no screen can show
 * it. The column was still declared NOT NULL, so every delivery status update
 * that froze the amount died on a NOT NULL constraint — a 500 on the courier's
 * "delivered" button, which in turn meant no cash was ever collected and no
 * settlement was ever created.
 *
 * Kept as its own migration so existing databases pick up the fix without
 * having to replay the cash-on-delivery migration.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            $table->string('estimated_payout')->nullable()->default(null)->change();
        });
    }

    public function down(): void
    {
        // Backfill before restoring NOT NULL, or any row already nulled by a
        // real cash collection would block the rollback.
        DB::table('deliveries')
            ->whereNull('estimated_payout')
            ->update(['estimated_payout' => '']);

        Schema::table('deliveries', function (Blueprint $table) {
            $table->string('estimated_payout')->default('')->change();
        });
    }
};
