@extends('layouts.app')

@section('content')
<h1>{{ $post->title }}</h1>
<div class="muted">分类：{{ $post->category_key ?? '未分类' }}　发表于：{{ $post->created_at }}</div>

<div class="card">
  {!! nl2br(e($post->body)) !!}
  <div class="muted" style="margin-top:8px;">👍 {{ $post->likes_count }}　⭐ {{ $post->favorites_count }}　💬 {{ $post->comments_count }}</div>
  <div class="actions" style="margin-top:8px;">
    <a href="{{ url('/categories/'.$post->category_key) }}">返回分类</a>
  </div>
  </div>

<h3>评论</h3>
@forelse($post->comments as $c)
  <div class="card">
    <div><strong>{{ $c->user->name ?? '匿名' }}</strong> <span class="muted">{{ $c->created_at }}</span></div>
    <div>{{ $c->content }}</div>
  </div>
@empty
  <div class="muted">暂无评论</div>
@endforelse
@endsection