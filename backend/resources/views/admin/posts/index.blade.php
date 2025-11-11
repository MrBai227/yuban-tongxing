@extends('admin.layout')

@section('content')
<div class="card">
    <h2>帖子列表</h2>
    <p>
        <a class="btn btn-primary" href="{{ route('admin.posts.create') }}">新建帖子</a>
    </p>
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>标题</th>
            <th>分类</th>
            <th>操作</th>
        </tr>
        </thead>
        <tbody>
        @foreach($posts as $post)
            <tr>
                <td>{{ $post->id }}</td>
                <td>{{ $post->title }}</td>
                <td>{{ $post->category_key }}</td>
                <td>
                    <a class="btn" href="{{ route('admin.posts.edit', $post) }}">编辑</a>
                    <form style="display:inline" method="POST" action="{{ route('admin.posts.destroy', $post) }}" onsubmit="return confirm('确认删除该帖子？')">
                        @csrf
                        @method('DELETE')
                        <button class="btn btn-danger" type="submit">删除</button>
                    </form>
                </td>
            </tr>
        @endforeach
        </tbody>
    </table>
    <div class="pagination">{{ $posts->links() }}</div>
</div>
@endsection