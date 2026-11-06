<?php

use App\Http\Controllers\Api\V1\AdminCatalogController;
use App\Http\Controllers\Api\V1\AdminController;
use Illuminate\Support\Facades\Route;

Route::get('/customer/banners', [AdminCatalogController::class, 'banners']);
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/seller/apply', [AdminCatalogController::class, 'apply']);
    Route::get('/seller/application', [AdminCatalogController::class, 'application']);
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/catalog', [AdminCatalogController::class, 'index']);
        Route::post('/catalog/products', [AdminCatalogController::class, 'product']);
        Route::post('/catalog/categories', [AdminCatalogController::class, 'category']);
        Route::post('/catalog/stores/{id}', [AdminCatalogController::class, 'store']);
        Route::post('/catalog/banners', [AdminCatalogController::class, 'banner']);
        Route::post('/catalog/coupons', [AdminCatalogController::class, 'coupon']);
        Route::post('/catalog/notifications', [AdminCatalogController::class, 'notify']);
        Route::post('/settings', [AdminController::class, 'saveSettings']);
    });
});
