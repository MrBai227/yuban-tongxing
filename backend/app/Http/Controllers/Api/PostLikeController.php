<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\PostLike;
use Illuminate\Http\Request;

class PostLikeController extends Controller
{
    public function like(Post $post, Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        PostLike::firstOrCreate(['post_id' => $post->id, 'user_id' => $user->id]);
        $count = PostLike::where('post_id', $post->id)->count();
        return response()->json(['likes' => $count, 'liked_by_me' => true]);
    }

    public function unlike(Post $post, Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        PostLike::where('post_id', $post->id)->where('user_id', $user->id)->delete();
        $count = PostLike::where('post_id', $post->id)->count();
        return response()->json(['likes' => $count, 'liked_by_me' => false]);
    }
}