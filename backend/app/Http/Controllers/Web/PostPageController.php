<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Post;

class PostPageController extends Controller
{
    public function show(Post $post)
    {
        $post->loadCount(['likes', 'favorites', 'comments']);
        $post->load(['comments' => function ($q) {
            $q->orderByDesc('id');
        }, 'comments.user']);
        return view('posts.show', ['post' => $post]);
    }
}