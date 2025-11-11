@extends('admin.layout')

@section('content')
<div class="card">
    <div class="flex items-center justify-between mb-3">
        <h2>系统通知列表</h2>
        <a class="btn btn-primary" href="{{ route('admin.system_notifications.create') }}">新建通知</a>
    </div>
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>用户</th>
                <th>类型</th>
                <th>标题</th>
                <th>创建时间</th>
                <th>操作</th>
            </tr>
        </thead>
        <tbody>
        @foreach($notifications as $n)
            <tr>
                <td>{{ $n->id }}</td>
                <td>{{ $n->user_id }}</td>
                <td>{{ $n->type ?? '-' }}</td>
                <td>{{ $n->title }}</td>
                <td>{{ $n->created_at }}</td>
                <td>
                    <form style="display:inline" method="POST" action="{{ route('admin.system_notifications.destroy', $n) }}" onsubmit="return confirm('确认删除该通知？')">
                        @csrf
                        @method('DELETE')
                        <button class="btn" type="submit">删除</button>
                    </form>
                </td>
            </tr>
        @endforeach
        </tbody>
    </table>
    <div class="mt-3">{{ $notifications->links() }}</div>
</div>
@endsection