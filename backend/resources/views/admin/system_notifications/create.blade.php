@extends('admin.layout')

@section('content')
<div class="card">
    <h2>新建系统通知</h2>
    <form method="POST" action="{{ route('admin.system_notifications.store') }}" class="grid gap-4">
        @csrf
        <div>
            <label class="text-sm text-slate-700">通知类型（可选）</label>
            <input class="input" type="text" name="type" value="{{ old('type') }}" placeholder="如 announcement" />
        </div>
        <div>
            <label class="text-sm text-slate-700">标题</label>
            <input class="input" type="text" name="title" value="{{ old('title') }}" required />
        </div>
        <div>
            <label class="text-sm text-slate-700">内容</label>
            <textarea class="input" name="content" rows="4" placeholder="通知正文（可选）">{{ old('content') }}</textarea>
        </div>
        <div>
            <label class="text-sm text-slate-700">发送对象</label>
            <div class="flex items-center gap-4">
                <label class="inline-flex items-center gap-2">
                    <input type="radio" name="target" value="all" {{ old('target','all')==='all' ? 'checked' : '' }} />
                    所有用户
                </label>
                <label class="inline-flex items-center gap-2">
                    <input type="radio" name="target" value="one" {{ old('target')==='one' ? 'checked' : '' }} />
                    指定用户
                </label>
            </div>
        </div>
        <div>
            <label class="text-sm text-slate-700">指定用户（仅当选择“指定用户”时生效）</label>
            <select name="user_id" class="input">
                <option value="">请选择用户</option>
                @foreach($users as $u)
                    <option value="{{ $u->id }}">#{{ $u->id }} {{ $u->name }} ({{ $u->email }})</option>
                @endforeach
            </select>
            <p class="text-xs text-slate-500 mt-1">为避免下拉过长，此处只显示部分用户；也可手动填写用户ID。</p>
            <input class="input mt-2" type="number" name="user_id" placeholder="或手动填写用户ID" />
        </div>
        <div class="flex gap-2">
            <button type="submit" class="btn btn-primary">发送</button>
            <a class="btn" href="{{ route('admin.system_notifications.index') }}">返回列表</a>
        </div>
    </form>
</div>
@endsection