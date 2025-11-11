<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Post;
use App\Models\PostLike;
use App\Models\PostFavorite;
use App\Models\Category;

class CategoryController extends Controller
{
    private function categoriesFallback(): array
    {
        return [
            ['key' => 'experience', 'name' => '经验交流', 'desc' => '分享经历与方法'],
            ['key' => 'practice',   'name' => '练习打卡', 'desc' => '每日复读与练习'],
            ['key' => 'resources',  'name' => '资源分享', 'desc' => '教材与资料'],
            ['key' => 'qa',         'name' => '求助问答', 'desc' => '提问与解答'],
            ['key' => 'events',     'name' => '线下活动', 'desc' => '聚会与活动'],
        ];
    }

    public function index(Request $request)
    {
        $items = Category::query()->orderBy('id')->get(['key','name','desc']);
        if ($items->count() === 0) {
            return response()->json($this->categoriesFallback());
        }
        return response()->json($items);
    }

    public function show(string $key, Request $request)
    {
        $catModel = Category::query()->where('key', $key)->first();
        $cat = $catModel ? ['key' => $catModel->key, 'name' => $catModel->name, 'desc' => $catModel->desc] : null;
        if (!$cat) {
            // fallback
            foreach ($this->categoriesFallback() as $c) { if ($c['key'] === $key) { $cat = $c; break; } }
        }
        if ($cat) {
                $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
                $page = max((int) $request->get('page', 1), 1);
                $sort = $request->get('sort', 'latest'); // 'latest' or 'hot'

                $query = Post::query()->where('category_key', $key)
                    ->with(['user'])
                    ->withCount(['likes', 'favorites', 'comments', 'views']);
                if ($sort === 'hot') {
                    $query->orderBy('likes_count', 'desc')
                          ->orderBy('comments_count', 'desc')
                          ->orderByDesc('id');
                } else {
                    $query->orderByDesc('created_at');
                }

                $paginator = $query->paginate($perPage, ['*'], 'page', $page);
                $user = $request->user();
                $content = collect($paginator->items())->map(function (Post $p) use ($user) {
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
                        'author' => [
                            'id' => $p->user_id,
                            'name' => ($p->user ? $p->user->name : null),
                            'avatar_url' => ($p->user && isset($p->user->avatar_url)) ? $p->user->avatar_url : null,
                        ],
                    ];
                })->values();

                return response()->json([
                    'category' => $cat,
                    'content' => $content,
                    'current_page' => $paginator->currentPage(),
                    'per_page' => $paginator->perPage(),
                    'has_more' => $paginator->hasMorePages(),
                ]);
        }
        return response()->json(['message' => 'Not Found'], 404);
    }

    // Admin-only CRUD
    public function store(Request $request)
    {
        $user = Auth::user();
        if (!$user || !$user->is_admin) { return response()->json(['message' => 'Forbidden'], 403); }
        $data = $request->validate([
            'key' => ['required','string','max:64'],
            'name' => ['required','string','max:255'],
            'desc' => ['nullable','string','max:255'],
        ]);
        if (Category::query()->where('key',$data['key'])->exists()) {
            return response()->json(['message' => 'Key exists'], 422);
        }
        $cat = Category::create($data);
        return response()->json(['id' => $cat->id], 201);
    }

    public function update(string $key, Request $request)
    {
        $user = Auth::user();
        if (!$user || !$user->is_admin) { return response()->json(['message' => 'Forbidden'], 403); }
        $cat = Category::query()->where('key',$key)->first();
        if (!$cat) { return response()->json(['message' => 'Not Found'], 404); }
        $data = $request->validate([
            'name' => ['required','string','max:255'],
            'desc' => ['nullable','string','max:255'],
        ]);
        $cat->update($data);
        return response()->json(['ok' => true]);
    }

    public function destroy(string $key, Request $request)
    {
        $user = Auth::user();
        if (!$user || !$user->is_admin) { return response()->json(['message' => 'Forbidden'], 403); }
        $cat = Category::query()->where('key',$key)->first();
        if (!$cat) { return response()->json(['message' => 'Not Found'], 404); }
        $cat->delete();
        return response()->json(['ok' => true]);
    }
}