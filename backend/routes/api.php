<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CustomerController;
use App\Http\Controllers\Api\V1\SellerController;
use App\Http\Controllers\Api\V1\AdminController;
use App\Http\Controllers\Api\V1\DeliveryController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\RoniController;
use App\Http\Controllers\Api\V1\RonixController;
use App\Http\Controllers\Api\V1\AuctionController;
use App\Http\Controllers\Api\V1\AdminRoniController;

Route::prefix('v1')->group(function () {
    // Notification feed. Clients poll this; no push service or device
    // registration is involved.
    Route::middleware('auth:sanctum')->prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::post('/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::post('/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::delete('/{id}', [NotificationController::class, 'destroy']);
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/product-discounts', [\App\Http\Controllers\Api\V1\ProductDiscountController::class, 'index']);
        Route::post('/product-discounts/{product}', [\App\Http\Controllers\Api\V1\ProductDiscountController::class, 'update']);
        Route::get('/reward-tasks', [\App\Http\Controllers\Api\V1\RewardTaskController::class, 'index']);
        Route::post('/reward-tasks/{task}/submit', [\App\Http\Controllers\Api\V1\RewardTaskController::class, 'submit']);
        Route::post('/admin/reward-tasks', [\App\Http\Controllers\Api\V1\RewardTaskController::class, 'create']);
        Route::get('/admin/task-submissions', [\App\Http\Controllers\Api\V1\RewardTaskController::class, 'submissions']);
        Route::post('/admin/task-submissions/{submission}/review', [\App\Http\Controllers\Api\V1\RewardTaskController::class, 'review']);
    });

    // Auth Routes
    Route::prefix('auth')->group(function () {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);
        Route::middleware('auth:sanctum')->group(function () {
            Route::get('/profile', [AuthController::class, 'profile']);
            Route::post('/logout', [AuthController::class, 'logout']);
        });
    });

    // Customer Module Routes
    Route::prefix('customer')->group(function () {
        Route::get('/home', [CustomerController::class, 'home']);
        Route::get('/products', [CustomerController::class, 'products']);
        Route::get('/products/{id}', [CustomerController::class, 'product']);
        Route::get('/articles', [CustomerController::class, 'articles']);
        Route::get('/currency-market', [CustomerController::class, 'currencyMarket']);
        Route::get('/coupons', [CustomerController::class, 'coupons']);

        // Server-authoritative pricing: the client sends ids and quantities
        // only, and the server returns the real price, discount and delivery
        // fee computed from the database.
        Route::post('/quote', [CustomerController::class, 'quote']);

        // --- RONI panels ---
        // The loop summary, RONI Gives and RONI Plus are readable without a
        // token so the home screens always render; they simply omit anything
        // personal when the caller is a guest.
        Route::get('/roni', [RoniController::class, 'summary']);
        Route::get('/gives', [RoniController::class, 'gives']);
        Route::get('/memberships', [RoniController::class, 'memberships']);

        // Auctions are public so the countdown and prize show on the home
        // screen. Only bidding requires an account.
        Route::get('/auctions', [AuctionController::class, 'index']);
        Route::get('/auctions/{id}', [AuctionController::class, 'show']);

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('/currency-market/trade', [CustomerController::class, 'tradeCurrency']);
            Route::post('/checkout', [CustomerController::class, 'checkout']);
            Route::get('/orders', [CustomerController::class, 'orders']);
            Route::get('/orders/{id}', [CustomerController::class, 'order']);
            Route::post('/orders/{id}/cancel', [CustomerController::class, 'cancelOrder']);
            Route::get('/orders/{id}/refund-preview', [CustomerController::class, 'refundPreview']);
            Route::get('/favorites', [CustomerController::class, 'favorites']);
            Route::post('/favorites/toggle', [CustomerController::class, 'toggleFavorite']);
            Route::post('/profile/update', [CustomerController::class, 'updateProfile']);

            Route::get('/addresses', [CustomerController::class, 'addresses']);
            Route::post('/addresses', [CustomerController::class, 'storeAddress']);
            Route::put('/addresses/{id}', [CustomerController::class, 'updateAddress']);
            Route::delete('/addresses/{id}', [CustomerController::class, 'destroyAddress']);

            // --- RONI actions ---
            Route::get('/ronix', [RonixController::class, 'index']);
            Route::post('/rewards/{id}/redeem', [RonixController::class, 'redeem']);
            Route::post('/auctions/{id}/bid', [AuctionController::class, 'bid']);
            Route::post('/memberships/request', [RoniController::class, 'requestMembership']);
            Route::post('/memberships/cancel', [RoniController::class, 'cancelMembership']);
        });
    });

    // Seller Module Routes
    Route::middleware(['auth:sanctum', 'role:seller'])->prefix('seller')->group(function () {
        Route::get('/dashboard', [SellerController::class, 'dashboard']);
        Route::get('/products', [SellerController::class, 'products']);
        Route::get('/products/{id}', [SellerController::class, 'product']);
        Route::post('/store/update', [SellerController::class, 'updateStore']);
        Route::post('/products/save', [SellerController::class, 'saveProduct']);
        // POST accepted too so mobile clients can send multipart with `_method=PUT`.
        Route::match(['put', 'post'], '/products/{id}', [SellerController::class, 'updateProduct']);
        Route::delete('/products/{id}', [SellerController::class, 'destroyProduct']);

        Route::get('/orders', [SellerController::class, 'orders']);
        Route::get('/orders/{id}', [SellerController::class, 'order']);
        Route::post('/orders/{id}/status', [SellerController::class, 'updateOrderStatus']);
        Route::post('/orders/{id}/refund', [SellerController::class, 'refundOrder']);

        // Cash-on-delivery settlement: what each courier holds for this store.
        Route::get('/settlements', [SellerController::class, 'settlements']);
        Route::post('/settlements/{id}/settle', [SellerController::class, 'settle']);
    });

    // Admin Module Routes
    //
    // These were previously readable by anyone, which published every user
    // account and every system setting on an unauthenticated endpoint. The
    // console is now behind the same role check the rest of the admin
    // surface uses.
    Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {
        Route::get('/kpis', [AdminController::class, 'kpis']);
        Route::get('/users', [AdminController::class, 'users']);
        Route::post('/users/{id}/toggle-status', [AdminController::class, 'toggleUserStatus']);
        Route::get('/articles', [AdminController::class, 'articles']);
        Route::post('/articles/save', [AdminController::class, 'saveArticle']);
        Route::get('/settings', [AdminController::class, 'settings']);

        // --- RONI control plane ---
        Route::get('/roni/overview', [AdminRoniController::class, 'overview']);
        Route::post('/roni/settings', [AdminRoniController::class, 'saveSettings']);
        Route::post('/roni/budget', [AdminRoniController::class, 'saveBudget']);

        Route::get('/roni/plans', [AdminRoniController::class, 'plans']);
        Route::post('/roni/plans/{id}', [AdminRoniController::class, 'savePlan']);
        Route::get('/roni/memberships', [AdminRoniController::class, 'memberships']);
        Route::post('/roni/memberships/{id}/settle', [AdminRoniController::class, 'settleMembership']);
        Route::post('/roni/memberships/{id}/reject', [AdminRoniController::class, 'rejectMembership']);

        Route::get('/roni/fraud-flags', [AdminRoniController::class, 'fraudFlags']);
        Route::post('/roni/fraud-flags/{id}/resolve', [AdminRoniController::class, 'resolveFlag']);

        Route::get('/roni/auctions', [AdminRoniController::class, 'auctions']);
        Route::post('/roni/auctions', [AdminRoniController::class, 'saveAuction']);
        Route::put('/roni/auctions/{id}', [AdminRoniController::class, 'saveAuction']);
        Route::post('/roni/auctions/{id}/publish', [AdminRoniController::class, 'publishAuction']);

        Route::get('/roni/projects', [AdminRoniController::class, 'projects']);
        Route::post('/roni/projects', [AdminRoniController::class, 'saveProject']);
        Route::put('/roni/projects/{id}', [AdminRoniController::class, 'saveProject']);
    });

    // Delivery Module Routes
    Route::middleware(['auth:sanctum', 'role:delivery'])->prefix('delivery')->group(function () {
        Route::get('/tasks', [DeliveryController::class, 'tasks']);
        Route::get('/earnings', [DeliveryController::class, 'earnings']);
        Route::post('/tasks/{id}/claim', [DeliveryController::class, 'claim']);
        Route::post('/tasks/{id}/status', [DeliveryController::class, 'updateStatus']);
        Route::post('/tasks/{id}/location', [DeliveryController::class, 'updateLocation']);
    });
});
