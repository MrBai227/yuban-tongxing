@extends('admin.layout')

@section('content')
<div class="card">
    <h2>编辑帖子 #{{ $post->id }}</h2>
    <form method="POST" action="{{ route('admin.posts.update', $post) }}">
        @csrf
        @method('PUT')
        <div>
            <label>标题</label>
            <input type="text" name="title" value="{{ old('title', $post->title) }}" required />
        </div>
        <div>
            <label>分类 Key</label>
            <input type="text" name="category_key" value="{{ old('category_key', $post->category_key) }}" required />
        </div>
        <div>
            <label>正文</label>
            <textarea name="body" rows="8" required>{{ old('body', $post->body) }}</textarea>
        </div>
        <button type="submit" class="btn btn-primary">保存</button>
        <a class="btn" href="{{ route('admin.posts.index') }}">返回列表</a>
    </form>
</div>
@endsection