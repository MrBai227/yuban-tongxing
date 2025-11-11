<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>后台管理</title>
    
    <link rel="stylesheet" href="{{ mix('css/app.css') }}">
    <script src="{{ mix('js/app.js') }}" defer></script>
</head>
<body>
<header class="sticky top-0 z-20 bg-white border-b border-slate-200">
    <div class="container-narrow flex items-center gap-4 py-3">
      <div class="font-semibold">后台管理</div>
      <nav class="flex items-center gap-2">
          <a href="{{ route('admin.dashboard') }}" class="px-3 py-2 rounded-lg {{ request()->routeIs('admin.dashboard') ? 'bg-slate-200 text-slate-900' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100' }}">仪表盘</a>
          <a href="{{ route('admin.users.index') }}" class="px-3 py-2 rounded-lg {{ request()->routeIs('admin.users.*') ? 'bg-slate-200 text-slate-900' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100' }}">用户管理</a>
          <a href="{{ route('admin.posts.index') }}" class="px-3 py-2 rounded-lg {{ request()->routeIs('admin.posts.*') ? 'bg-slate-200 text-slate-900' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100' }}">帖子管理</a>
          <a href="{{ route('admin.treeholes.index') }}" class="px-3 py-2 rounded-lg {{ request()->routeIs('admin.treeholes.*') ? 'bg-slate-200 text-slate-900' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100' }}">树洞管理</a>
          <a href="{{ route('admin.categories.index') }}" class="px-3 py-2 rounded-lg {{ request()->routeIs('admin.categories.*') ? 'bg-slate-200 text-slate-900' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100' }}">分类管理</a>
          <a href="{{ route('admin.system_notifications.index') }}" class="px-3 py-2 rounded-lg {{ request()->routeIs('admin.system_notifications.*') ? 'bg-slate-200 text-slate-900' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100' }}">系统通知</a>
      @auth
          <form action="{{ route('admin.logout') }}" method="POST" class="inline">
              @csrf
              <button type="submit" class="btn">退出登录</button>
          </form>
          @endauth
      </nav>
    </div>
    @if (session('status'))
        <div class="container-narrow">
            <div class="mt-2 rounded-lg border border-green-300 bg-green-100 text-green-700 px-3 py-2">
                {{ session('status') }}
            </div>
        </div>
    @endif
    @if ($errors->any())
        <div class="container-narrow">
            <div class="mt-2 rounded-lg border border-red-300 bg-red-100 text-red-700 px-3 py-2">
                {{ $errors->first() }}
            </div>
        </div>
    @endif
  </header>
  <div class="container-narrow">
      @yield('content')
  </div>
</body>
</html>