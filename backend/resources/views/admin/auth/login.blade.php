@extends('admin.auth.layout')

@section('content')
<div class="flex items-center gap-3 mb-3">
    <div class="w-10 h-10 rounded-full bg-blue-600/20 grid place-items-center">
    </div>
    <div>
        <h2 class="text-xl font-semibold">管理员登录</h2>
        <p class="mt-1 text-slate-400 text-sm">请输入邮箱与密码登录后台</p>
    </div>
    </div>
<form action="{{ route('admin.login.post') }}" method="POST" class="grid gap-4">
        @csrf
        <div>
            <label class="text-sm text-slate-700">邮箱</label>
            <input class="w-full px-3 py-2 rounded-lg border border-slate-300 bg-white text-slate-900 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20" type="email" name="email" value="{{ old('email') }}" placeholder="admin@example.com" required />
        </div>
        <div>
            <label class="text-sm text-slate-700">密码</label>
            <input class="w-full px-3 py-2 rounded-lg border border-slate-300 bg-white text-slate-900 outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20" type="password" name="password" placeholder="••••••••" required />
        </div>
        <div class="flex items-center justify-between">
            <label class="inline-flex items-center gap-2 text-slate-700 text-sm">
                <input type="checkbox" name="remember" class="rounded" />
                记住我
            </label>
            <button type="submit" class="btn btn-primary">登录</button>
        </div>
        <p class="mt-1 text-slate-600 text-xs">仅限拥有管理员权限的账号登录。</p>
    </form>
@endsection