@extends('admin.layout')

@section('content')
<div class="card">
    <h2>仪表盘</h2>
    <p>欢迎，{{ auth()->user()->name ?? '访客' }}。</p>
    <p>
        快捷入口：
        <a class="btn" href="{{ route('admin.users.index') }}">用户管理</a>
        <a class="btn" href="{{ route('admin.posts.index') }}">帖子管理</a>
        <a class="btn" href="{{ route('admin.categories.posts') }}">分类帖子管理</a>
        <a class="btn" href="{{ route('admin.system_notifications.index') }}">系统通知</a>
    </p>
</div>
@endsection