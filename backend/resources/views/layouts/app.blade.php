<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? '口吃社区' }}</title>
    <link rel="stylesheet" href="{{ mix('css/app.css') }}">
    <script src="{{ mix('js/app.js') }}" defer></script>
    @yield('head')
 </head>
<body>
    <header class="bg-white border-b border-slate-200 text-slate-900">
        <div class="container-narrow">
            <nav class="flex items-center gap-3 py-3">
                <a class="px-3 py-2 rounded-lg text-slate-700 hover:text-slate-900 hover:bg-slate-100" href="{{ url('/') }}">首页</a>
                <a class="px-3 py-2 rounded-lg text-slate-700 hover:text-slate-900 hover:bg-slate-100" href="{{ url('/categories') }}">分类</a>
            </nav>
        </div>
    </header>
    <main class="container-narrow my-6">
        @yield('content')
    </main>
</body>
</html>