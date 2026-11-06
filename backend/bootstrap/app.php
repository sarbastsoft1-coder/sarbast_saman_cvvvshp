<?php

use App\Http\Middleware\RequireRole;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Support\Facades\Route;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        then: function () {
            // Both files are versioned with their own `v1` prefix so every
            // client keeps talking to /api/v1, exactly like routes/api.php.
            Route::middleware('api')->prefix('api')->group(base_path('routes/marketplace.php'));
            Route::middleware('api')->prefix('api/v1')->group(base_path('routes/admin_catalog.php'));
        },
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->api(append: [\App\Http\Middleware\RequireActiveAccount::class]);
        // routes/marketplace.php guards its customer, seller and admin groups
        // with `role:`, which had no alias registered, so the whole file
        // failed to resolve the moment it was loaded.
        $middleware->alias([
            'role' => RequireRole::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
