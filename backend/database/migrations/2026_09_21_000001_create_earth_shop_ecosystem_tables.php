<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Stores (for Sellers)
        Schema::create('stores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('tagline')->nullable();
            $table->text('description')->nullable();
            $table->string('craft_category')->default('Ceramics');
            $table->string('logo')->nullable();
            $table->string('banner')->nullable();
            $table->decimal('rating', 3, 2)->default(5.00);
            $table->integer('total_sales')->default(0);
            $table->boolean('is_verified')->default(true);
            $table->string('status')->default('active');
            $table->timestamps();
        });

        // 2. Categories
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('icon')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();
        });

        // 3. Products
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('store_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->decimal('price_fiat', 10, 2);
            $table->decimal('price_tokens', 10, 2); // Terra token price
            $table->integer('stock')->default(10);
            $table->string('image')->nullable();
            $table->json('gallery')->nullable();
            $table->string('material_provenance')->nullable();
            $table->decimal('rating', 3, 2)->default(5.00);
            $table->boolean('is_featured')->default(false);
            $table->string('status')->default('active');
            $table->timestamps();
        });

        // 4. Wallets
        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->decimal('fiat_balance', 12, 2)->default(100.00);
            $table->decimal('token_balance', 12, 2)->default(50.00); // Terra tokens
            $table->timestamps();
        });

        // 5. Wallet Transactions
        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // credit, debit
            $table->string('currency'); // USD, TERRA
            $table->decimal('amount', 12, 2);
            $table->decimal('balance_after', 12, 2);
            $table->string('reference_type')->nullable(); // market_trade, order_payment, challenge_reward
            $table->string('reference_id')->nullable();
            $table->string('description');
            $table->timestamps();
        });

        // 6. Currency Market Listings (Peer-to-Peer Terra Token Exchange)
        Schema::create('currency_market_listings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['buy', 'sell']);
            $table->decimal('token_amount', 12, 2);
            $table->decimal('rate_fiat', 8, 4); // Exchange rate per token
            $table->decimal('filled_amount', 12, 2)->default(0);
            $table->string('status')->default('open'); // open, completed, cancelled
            $table->timestamps();
        });

        // 7. Challenges (Sustainability Quests)
        Schema::create('challenges', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description');
            $table->string('icon')->default('🌱');
            $table->integer('target_count')->default(1);
            $table->decimal('reward_tokens', 8, 2)->default(10.00);
            $table->string('category')->default('eco');
            $table->timestamps();
        });

        Schema::create('user_challenges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('challenge_id')->constrained()->cascadeOnDelete();
            $table->integer('progress')->default(0);
            $table->string('status')->default('in_progress'); // in_progress, completed, claimed
            $table->timestamps();
        });

        // 8. Articles (Articashin Marketing & Educational Content)
        Schema::create('articles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('title');
            $table->string('slug')->unique();
            $table->string('category')->default('Ecosystem Economy');
            $table->string('read_time')->default('4 min read');
            $table->text('summary')->nullable();
            $table->longText('content');
            $table->string('cover_image')->nullable();
            $table->boolean('is_published')->default(true);
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
        });

        // 9. Orders & Order Items
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_number')->unique();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('store_id')->constrained()->cascadeOnDelete();
            $table->decimal('total_fiat', 10, 2)->default(0);
            $table->decimal('total_tokens', 10, 2)->default(0);
            $table->string('payment_method')->default('fiat'); // fiat, token, split
            $table->string('status')->default('pending'); // pending, preparing, ready_for_pickup, out_for_delivery, delivered, cancelled
            $table->text('shipping_address');
            $table->decimal('shipping_lat', 10, 7)->nullable();
            $table->decimal('shipping_lng', 10, 7)->nullable();
            $table->timestamps();
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->integer('quantity')->default(1);
            $table->decimal('unit_fiat', 10, 2);
            $table->decimal('unit_tokens', 10, 2);
            $table->decimal('total_fiat', 10, 2);
            $table->timestamps();
        });

        // 10. Deliveries (Logistics & Live Route Tracking)
        Schema::create('deliveries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('driver_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status')->default('ready_for_pickup'); // ready_for_pickup, assigned, picked_up, out_for_delivery, delivered
            $table->string('pickup_store_name');
            $table->text('pickup_address');
            $table->string('estimated_pickup_time')->nullable();
            $table->string('customer_name');
            $table->text('dropoff_address');
            $table->string('estimated_delivery_time')->nullable();
            $table->string('distance')->default('2.4 miles');
            $table->string('estimated_payout')->default('$9.50 + 4 TERRA');
            $table->decimal('pickup_lat', 10, 7)->default(37.7749000);
            $table->decimal('pickup_lng', 10, 7)->default(-122.4194000);
            $table->decimal('dropoff_lat', 10, 7)->default(37.7833000);
            $table->decimal('dropoff_lng', 10, 7)->default(-122.4167000);
            $table->decimal('current_lat', 10, 7)->default(37.7710000);
            $table->decimal('current_lng', 10, 7)->default(-122.4210000);
            $table->json('waypoints')->nullable();
            $table->timestamps();
        });

        // 11. System Settings
        Schema::create('system_settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value');
            $table->string('group')->default('general');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('system_settings');
        Schema::dropIfExists('deliveries');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('articles');
        Schema::dropIfExists('user_challenges');
        Schema::dropIfExists('challenges');
        Schema::dropIfExists('currency_market_listings');
        Schema::dropIfExists('wallet_transactions');
        Schema::dropIfExists('wallets');
        Schema::dropIfExists('products');
        Schema::dropIfExists('categories');
        Schema::dropIfExists('stores');
    }
};
