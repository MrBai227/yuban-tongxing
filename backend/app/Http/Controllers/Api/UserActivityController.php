<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\PostComment;
use App\Models\PostLike;
use App\Models\PostFavorite;
use App\Models\PostView;
use App\Models\Follow;
use Illuminate\Http\Request;

class UserActivityController extends Controller
{
    private function mapPosts($paginator, $user)
    {
        return collect($paginator->items())->map(function (Post $p) use ($user) {
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
                'views' => property_exists($p, 'views_count') ? $p->views_count : null,
                'liked_by_me' => $likedByMe,
                'favorited_by_me' => $favoritedByMe,
            ];
        })->values();
    }

    public function likes(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);

        $query = Post::query()
            ->select('posts.*')
            ->join('post_likes', 'post_likes.post_id', '=', 'posts.id')
            ->where('post_likes.user_id', $user->id)
            ->withCount(['likes', 'favorites', 'comments', 'views'])
            ->orderByDesc('post_likes.created_at');

        $paginator = $query->paginate($perPage, ['*'], 'page', $page);
        $data = $this->mapPosts($paginator, $user);
        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    public function favorites(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);

        $query = Post::query()
            ->select('posts.*')
            ->join('post_favorites', 'post_favorites.post_id', '=', 'posts.id')
            ->where('post_favorites.user_id', $user->id)
            ->withCount(['likes', 'favorites', 'comments', 'views'])
            ->orderByDesc('post_favorites.created_at');

        $paginator = $query->paginate($perPage, ['*'], 'page', $page);
        $data = $this->mapPosts($paginator, $user);
        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    public function views(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);

        $query = Post::query()
            ->select('posts.*')
            ->join('post_views', 'post_views.post_id', '=', 'posts.id')
            ->where('post_views.user_id', $user->id)
            ->withCount(['likes', 'favorites', 'comments', 'views'])
            ->orderByDesc('post_views.created_at');

        $paginator = $query->paginate($perPage, ['*'], 'page', $page);
        $data = $this->mapPosts($paginator, $user);
        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    /**
     * 我关注的人（关注列表）
     */
    public function followings(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);

        $paginator = Follow::query()
            ->where('follower_id', $user->id)
            ->with('followed')
            ->orderByDesc('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        $data = collect($paginator->items())->map(function (Follow $f) {
            return [
                'id' => $f->followed_id,
                'name' => optional($f->followed)->name,
                'email' => optional($f->followed)->email,
                'followed_at' => $f->created_at,
            ];
        })->values();

        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    /**
     * 关注我的人（粉丝列表）
     */
    public function followers(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);

        $paginator = Follow::query()
            ->where('followed_id', $user->id)
            ->with('follower')
            ->orderByDesc('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        $data = collect($paginator->items())->map(function (Follow $f) {
            return [
                'id' => $f->follower_id,
                'name' => optional($f->follower)->name,
                'email' => optional($f->follower)->email,
                'followed_at' => $f->created_at,
            ];
        })->values();

        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    /**
     * 获赞和收藏统计（别人对我发布内容的点赞/收藏总数）
     */
    public function statsReceived(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $likesReceived = PostLike::query()
            ->join('posts', 'posts.id', '=', 'post_likes.post_id')
            ->where('posts.user_id', $user->id)
            ->count();

        $favoritesReceived = PostFavorite::query()
            ->join('posts', 'posts.id', '=', 'post_favorites.post_id')
            ->where('posts.user_id', $user->id)
            ->count();

        return response()->json([
            'likes_received' => $likesReceived,
            'favorites_received' => $favoritesReceived,
        ]);
    }

    /**
     * 互相关注列表（与我相互关注的人）
     */
    public function mutuals(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);

        $paginator = Follow::query()
            ->where('follower_id', $user->id)
            ->whereExists(function ($q) use ($user) {
                $q->selectRaw('1')
                  ->from('follows as f2')
                  ->whereColumn('f2.follower_id', 'follows.followed_id')
                  ->whereColumn('f2.followed_id', 'follows.follower_id');
            })
            ->with('followed')
            ->orderByDesc('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        $data = collect($paginator->items())->map(function (Follow $f) {
            return [
                'id' => $f->followed_id,
                'name' => optional($f->followed)->name,
                'email' => optional($f->followed)->email,
                'followed_at' => $f->created_at,
            ];
        })->values();

        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    /**
     * 我的评论（我发表过的评论列表，含归属帖子信息）
     */
    public function commentsByMe(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);

        $query = PostComment::query()
            ->select('post_comments.*')
            ->where('post_comments.user_id', $user->id)
            ->with(['post'])
            ->orderByDesc('post_comments.created_at');

        $paginator = $query->paginate($perPage, ['*'], 'page', $page);
        $data = collect($paginator->items())->map(function (PostComment $c) {
            return [
                'id' => $c->id,
                'content' => $c->content,
                'created_at' => $c->created_at,
                'post' => [
                    'id' => $c->post_id,
                    'title' => optional($c->post)->title,
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
}