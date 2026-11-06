<?php

use App\Http\Controllers\Api\V1\MarketplaceController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('customer/products/{id}/reviews', [MarketplaceController::class, 'productReviews']);
    Route::middleware(['auth:sanctum', 'role:customer', 'throttle:60,1'])->prefix('customer')->group(function () {
        Route::get('reviews', [MarketplaceController::class, 'myReviews']);
        Route::post('reviews', [MarketplaceController::class, 'createReview']);
        Route::post('reviews/{id}/helpful', [MarketplaceController::class, 'helpful']);
        Route::get('returns', [MarketplaceController::class, 'myReturns']);
        Route::post('returns', [MarketplaceController::class, 'requestReturn']);
        Route::get('support', [MarketplaceController::class, 'myTickets']);
        Route::post('support', [MarketplaceController::class, 'createTicket']);
        Route::post('support/{id}/messages', [MarketplaceController::class, 'reply']);
    });
    Route::middleware(['auth:sanctum', 'role:seller', 'throttle:60,1'])->prefix('seller')->group(function () {
        Route::get('reviews', [MarketplaceController::class, 'sellerReviews']);
        Route::get('returns', [MarketplaceController::class, 'sellerReturns']);
        Route::get('support', [MarketplaceController::class, 'myTickets']);
        Route::post('support', [MarketplaceController::class, 'createTicket']);
        Route::post('support/{id}/messages', [MarketplaceController::class, 'reply']);
    });
    Route::middleware(['auth:sanctum', 'role:admin', 'throttle:120,1'])->prefix('admin')->group(function () {
        Route::get('reviews', [MarketplaceController::class, 'adminReviews']);
        Route::post('reviews/{id}/moderate', [MarketplaceController::class, 'moderate']);
        Route::get('returns', [MarketplaceController::class, 'adminReturns']);
        Route::post('returns/{id}/decision', [MarketplaceController::class, 'decideReturn']);
        Route::get('support', [MarketplaceController::class, 'adminTickets']);
        Route::post('support/{id}/messages', [MarketplaceController::class, 'reply']);
        Route::post('support/{id}/status', [MarketplaceController::class, 'ticketStatus']);
    });
});
