<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminMiddleware
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (!auth()->check()) {
            return redirect()->route('admin.login')->withErrors(['auth' => '请先登录']);
        }

        if (!auth()->user()->is_admin) {
            return redirect()->route('admin.login')->withErrors(['auth' => '您没有管理员权限']);
        }

        return $next($request);
    }
}