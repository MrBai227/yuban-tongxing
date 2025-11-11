<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\PostLike;
use App\Models\PostFavorite;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);
        $categoryKey = $request->get('category_key');
        $sort = $request->get('sort', 'latest'); // 'latest' or 'hot'
        $author = $request->get('author'); // optional: 'me' or user id

        $query = Post::query()
            ->with(['user'])
            ->withCount(['likes', 'favorites', 'comments', 'views']);
        if ($categoryKey) {
            $query->where('category_key', $categoryKey);
        }
        if ($author === 'me' && $request->user()) {
            $query->where('user_id', $request->user()->id);
        } elseif ($author && is_numeric($author)) {
            $query->where('user_id', (int)$author);
        }
        if ($sort === 'hot') {
            $query->orderBy('likes_count', 'desc')
                  ->orderBy('comments_count', 'desc')
                  ->orderByDesc('id');
        } else {
            $query->orderByDesc('created_at');
        }

        $paginator = $query->paginate($perPage, ['*'], 'page', $page);
        $user = $request->user();
        $data = collect($paginator->items())->map(function (Post $p) use ($user) {
            $likedByMe = false;
            $favoritedByMe = false;
            if ($user) {
                $likedByMe = PostLike::query()->where('post_id', $p->id)->where('user_id', $user->id)->exists();
                $favoritedByMe = PostFavorite::query()->where('post_id', $p->id)->where('user_id', $user->id)->exists();
            }
            return [
                'id' => $p->id,
                'title' => $p->title,
                'body' => $p->body,
                'category_key' => $p->category_key,
                'created_at' => $p->created_at,
                'likes' => $p->likes_count,
                'favorites' => $p->favorites_count,
                'comments' => $p->comments_count,
                'views' => $p->views_count,
                'liked_by_me' => $likedByMe,
                'favorited_by_me' => $favoritedByMe,
                'owned_by_me' => $user ? $user->id === $p->user_id : false,
                'author' => [
                    'id' => $p->user_id,
                    'name' => ($p->user ? $p->user->name : null),
                    'avatar_url' => ($p->user && isset($p->user->avatar_url)) ? $p->user->avatar_url : null,
                ],
            ];
        })->values();

        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'body' => 'required|string',
            'category_key' => 'nullable|string',
        ]);

        $post = Post::create([
            'user_id' => $user->id,
            'title' => $validated['title'],
            'body' => $validated['body'],
            'category_key' => $validated['category_key'] ?? null,
        ]);
        return response()->json(['id' => $post->id], 201);
    }
}