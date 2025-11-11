@extends('admin.layout')

@section('content')
<div class="card">
    <h2>新增练习打卡记录</h2>
    <form method="POST" action="{{ route('admin.practice_logs.store') }}" class="grid gap-3">
        @csrf
        <div>
            <label class="text-sm text-slate-700">用户</label>
            <div class="flex items-center gap-2">
                <select name="user_id" class="input" required>
                    <option value="">请选择用户</option>
                    @foreach($users as $u)
                        <option value="{{ $u->id }}">{{ $u->name }} (#{{ $u->id }})</option>
                    @endforeach
                </select>
                <span class="muted text-xs">注：如未在列表中，可直接填写用户ID。</span>
            </div>
            <input class="input mt-2" type="number" name="user_id" placeholder="或直接输入用户ID" />
        </div>
        <div class="grid grid-cols-2 gap-3">
            <div>
                <label class="text-sm text-slate-700">总时长(秒)</label>
                <input class="input" type="number" name="duration_seconds" value="{{ old('duration_seconds', 180) }}" min="0" max="86400" required />
            </div>
            <div>
                <label class="text-sm text-slate-700">轻声起音(秒)</label>
                <input class="input" type="number" name="soft_onset_seconds" value="{{ old('soft_onset_seconds', 30) }}" min="0" max="86400" />
            </div>
            <div>
                <label class="text-sm text-slate-700">延长发音(秒)</label>
                <input class="input" type="number" name="prolonged_seconds" value="{{ old('prolonged_seconds', 60) }}" min="0" max="86400" />
            </div>
            <div>
                <label class="text-sm text-slate-700">朗读(秒)</label>
                <input class="input" type="number" name="reading_seconds" value="{{ old('reading_seconds', 90) }}" min="0" max="86400" />
            </div>
        </div>
        <div>
            <label class="text-sm text-slate-700">备注</label>
            <input class="input" type="text" name="note" value="{{ old('note') }}" placeholder="可选" />
        </div>
        <div class="flex items-center gap-2">
            <button type="submit" class="btn btn-primary">保存</button>
            <a class="btn" href="{{ route('admin.practice_logs.index') }}">返回列表</a>
        </div>
    </form>
</div>
@endsection