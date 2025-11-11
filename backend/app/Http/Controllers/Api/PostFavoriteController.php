<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\PostFavorite;
use Illuminate\Http\Request;

class PostFavoriteController extends Controller
{
    public function favorite(Post $post, Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        PostFavorite::firstOrCreate(['post_id' => $post->id, 'user_id' => $user->id]);
        $count = PostFavorite::where('post_id', $post->id)->count();
        return response()->json(['favorites' => $count, 'favorited_by_me' => true]);
    }

    public function unfavorite(Post $post, Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        PostFavorite::where('post_id', $post->id)->where('user_id', $user->id)->delete();
        $count = PostFavorite::where('post_id', $post->id)->count();
        return response()->json(['favorites' => $count, 'favorited_by_me' => false]);
    }
}