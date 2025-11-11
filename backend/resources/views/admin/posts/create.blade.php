@extends('admin.layout')

@section('content')
<div class="card">
    <h2>新建帖子</h2>
    <form method="POST" action="{{ route('admin.posts.store') }}">
        @csrf
        <div>
            <label>标题</label>
            <input type="text" name="title" value="{{ old('title') }}" required />
        </div>
        <div>
            <label>分类 Key</label>
            <input type="text" name="category_key" value="{{ old('category_key') }}" required />
        </div>
        <div>
            <label>正文</label>
            <textarea name="body" rows="8" required>{{ old('body') }}</textarea>
        </div>
        <button type="submit" class="btn btn-primary">创建</button>
        <a class="btn" href="{{ route('admin.posts.index') }}">返回列表</a>
    </form>
</div>
@endsection