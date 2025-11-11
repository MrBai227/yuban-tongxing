<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>管理员登录</title>
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <link rel="stylesheet" href="{{ mix('css/app.css') }}">
    <script src="{{ mix('js/app.js') }}" defer></script>
    @yield('head')
    </head>
<body>
<div class="min-h-screen grid place-items-center p-6 bg-gradient-to-br from-slate-800 via-slate-900 to-black">
    <div class="w-full max-w-md card shadow-xl shadow-black/20 bg-white text-slate-900">
        @yield('content')
        @if (session('status'))
            <div class="mt-2 rounded-lg border border-green-300 bg-green-100 text-green-700 px-3 py-2">{{ session('status') }}</div>
        @endif
        @if ($errors->any())
            <div class="mt-2 rounded-lg border border-red-300 bg-red-100 text-red-700 px-3 py-2">{{ $errors->first() }}</div>
        @endif
    </div>
    <p class="mt-3 text-slate-300 text-sm">口吃 · 后台登录</p>
 </div>
</body>
</html>