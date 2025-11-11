<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\PostComment;
use Illuminate\Http\Request;

class PostCommentController extends Controller
{
    public function index(Post $post, Request $request)
    {
        $perPage = min(max((int) $request->get('per_page', 20), 1), 100);
        $page = max((int) $request->get('page', 1), 1);
        $query = PostComment::query()->where('post_id', $post->id)->with('user')->orderBy('id');
        $paginator = $query->paginate($perPage, ['*'], 'page', $page);

        $user = $request->user();
        $data = $paginator->getCollection()->map(function (PostComment $c) use ($user) {
            return [
                'id' => $c->id,
                'content' => $c->content,
                'created_at' => $c->created_at,
                'owned_by_me' => $user ? $user->id === $c->user_id : false,
                'author' => [
                    'name' => ($c->user ? $c->user->name : null),
                    'avatar_url' => ($c->user && isset($c->user->avatar_url)) ? $c->user->avatar_url : null,
                ],
            ];
        });

        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    public function store(Post $post, Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $validated = $request->validate([
            'content' => ['required', 'string', 'max:1000'],
        ]);
        $comment = PostComment::create([
            'post_id' => $post->id,
            'user_id' => $user->id,
            'content' => $validated['content'],
        ]);
        return response()->json(['id' => $comment->id], 201);
    }

    public function destroy(PostComment $comment, Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        if ($comment->user_id !== $user->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        $comment->delete();
        return response()->json(['ok' => true]);
    }
}