<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\PostView;
use Illuminate\Http\Request;

class PostViewController extends Controller
{
    public function record(Request $request, Post $post)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        PostView::create(['post_id' => $post->id, 'user_id' => $user->id]);
        return response()->json(['message' => 'ok']);
    }
}