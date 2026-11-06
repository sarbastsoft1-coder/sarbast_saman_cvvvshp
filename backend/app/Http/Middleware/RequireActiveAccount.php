<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RequireActiveAccount
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user('sanctum');
        abort_if($user && $user->status !== 'active', 403, 'This account is not active.');

        return $next($request);
    }
}
