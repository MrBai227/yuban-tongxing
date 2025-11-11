@extends('admin.layout')

@section('content')
<div class="card">
    <h2>用户列表</h2>
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>名称</th>
            <th>邮箱</th>
            <th>管理员</th>
            <th>操作</th>
        </tr>
        </thead>
        <tbody>
        @foreach($users as $user)
            <tr>
                <td>{{ $user->id }}</td>
                <td>{{ $user->name }}</td>
                <td>{{ $user->email }}</td>
                <td>{{ $user->is_admin ? '是' : '否' }}</td>
                <td>
                    @if(!$user->is_admin)
                        <form style="display:inline" method="POST" action="{{ route('admin.users.make_admin', $user) }}">
                            @csrf
                            <button class="btn btn-primary" type="submit">设为管理员</button>
                        </form>
                    @else
                        <form style="display:inline" method="POST" action="{{ route('admin.users.revoke_admin', $user) }}">
                            @csrf
                            <button class="btn" type="submit">取消管理员</button>
                        </form>
                    @endif
                    <form style="display:inline" method="POST" action="{{ route('admin.users.destroy', $user) }}" onsubmit="return confirm('确认删除该用户？')">
                        @csrf
                        @method('DELETE')
                        <button class="btn btn-danger" type="submit">删除</button>
                    </form>
                </td>
            </tr>
        @endforeach
        </tbody>
    </table>
    <div class="pagination">{{ $users->links() }}</div>
</div>
@endsection