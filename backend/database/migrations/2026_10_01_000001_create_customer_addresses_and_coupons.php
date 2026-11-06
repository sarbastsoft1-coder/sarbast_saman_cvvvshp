<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Saved customer addresses. The boutique client keeps these server-side
        // so checkout never depends on device-local storage.
        Schema::create('customer_addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('label')->default('home');
            $table->text('address');
            $table->string('phone');
            $table->boolean('is_default')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'is_default']);
        });

        // Server-authoritative coupons. Discounts are validated and applied on
        // the server at checkout; the client never computes its own discount.
        Schema::create('coupons', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('type')->default('percent'); // percent, fixed, free_shipping
            $table->decimal('value', 12, 2)->default(0);
            $table->decimal('min_spend', 12, 2)->default(0);
            $table->timestamp('expires_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Orders need a coupon link and a soft-cancel path so a customer can
        // withdraw an order that has not been picked up yet.
        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('coupon_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('discount_amount', 12, 2)->default(0);
            $table->decimal('delivery_fee', 12, 2)->default(0);
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->string('cancel_reason')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['coupon_id']);
            $table->dropColumn([
                'coupon_id',
                'discount_amount',
                'delivery_fee',
                'cancelled_at',
                'delivered_at',
                'cancel_reason',
            ]);
        });

        Schema::dropIfExists('coupons');
        Schema::dropIfExists('customer_addresses');
    }
};
