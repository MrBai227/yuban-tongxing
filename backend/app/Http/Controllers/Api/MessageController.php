<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\PostLike;
use App\Models\PostFavorite;
use App\Models\PostComment;
use App\Models\Follow;
use App\Models\SystemNotification;
use App\Models\MessageLastRead;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function reactions(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);

        $likes = PostLike::query()
            ->select('post_likes.*')
            ->join('posts', 'posts.id', '=', 'post_likes.post_id')
            ->where('posts.user_id', $user->id)
            ->with(['user', 'post'])
            ->orderByDesc('post_likes.created_at');

        $favorites = PostFavorite::query()
            ->select('post_favorites.*')
            ->join('posts', 'posts.id', '=', 'post_favorites.post_id')
            ->where('posts.user_id', $user->id)
            ->with(['user', 'post'])
            ->orderByDesc('post_favorites.created_at');

        $items = $likes->paginate($perPage, ['*'], 'page', $page);
        $favItems = $favorites->paginate($perPage, ['*'], 'page', $page);

        $data = collect($items->items())->map(function (PostLike $l) {
            return [
                'type' => 'like',
                'actor' => ['id' => $l->user_id, 'name' => optional($l->user)->name],
                'post' => ['id' => $l->post_id, 'title' => optional($l->post)->title],
                'created_at' => $l->created_at,
            ];
        });
        $data = $data->merge(collect($favItems->items())->map(function (PostFavorite $f) {
            return [
                'type' => 'favorite',
                'actor' => ['id' => $f->user_id, 'name' => optional($f->user)->name],
                'post' => ['id' => $f->post_id, 'title' => optional($f->post)->title],
                'created_at' => $f->created_at,
            ];
        }))->sortByDesc('created_at')->values();

        return response()->json([
            'data' => $data,
            'current_page' => $items->currentPage(),
            'per_page' => $items->perPage(),
            'has_more' => ($items->hasMorePages() || $favItems->hasMorePages()),
        ]);
    }

    public function follows(Request $request)
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
                'type' => 'follow',
                'actor' => ['id' => $f->follower_id, 'name' => optional($f->follower)->name],
                'created_at' => $f->created_at,
            ];
        })->values();

        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    public function commentsMentions(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);

        $query = PostComment::query()
            ->select('post_comments.*')
            ->join('posts', 'posts.id', '=', 'post_comments.post_id')
            ->where('posts.user_id', $user->id)
            ->with(['user', 'post'])
            ->orderByDesc('post_comments.created_at');

        $paginator = $query->paginate($perPage, ['*'], 'page', $page);
        $name = $user->name ?? '';
        $email = $user->email ?? '';
        $data = collect($paginator->items())->map(function (PostComment $c) use ($name, $email) {
            $content = $c->content ?? '';
            $isMention = false;
            if ($name) $isMention = $isMention || str_contains($content, '@'.$name);
            if ($email) $isMention = $isMention || str_contains($content, '@'.$email);
            return [
                'type' => $isMention ? 'mention' : 'comment',
                'actor' => ['id' => $c->user_id, 'name' => optional($c->user)->name],
                'post' => ['id' => $c->post_id, 'title' => optional($c->post)->title],
                'content' => $content,
                'created_at' => $c->created_at,
            ];
        })->values();

        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    public function system(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);
        $paginator = SystemNotification::query()
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        $data = collect($paginator->items())->map(function (SystemNotification $n) {
            return [
                'type' => $n->type,
                'title' => $n->title,
                'content' => $n->content,
                'created_at' => $n->created_at,
                'read_at' => $n->read_at,
            ];
        })->values();

        return response()->json([
            'data' => $data,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    public function systemUnreadCount(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $count = SystemNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->count();
        return response()->json(['count' => $count]);
    }

    public function markSystemAllRead(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        SystemNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
        return response()->json(['status' => 'ok']);
    }

    public function unreadCounts(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $last = MessageLastRead::query()->where('user_id', $user->id)->first();
        $reactionsLast = optional($last)->reactions_last_read_at;
        $followsLast = optional($last)->follows_last_read_at;
        $commentsLast = optional($last)->comments_last_read_at;

        $likesCount = PostLike::query()
            ->join('posts', 'posts.id', '=', 'post_likes.post_id')
            ->where('posts.user_id', $user->id)
            ->when($reactionsLast, function ($q) use ($reactionsLast) {
                $q->where('post_likes.created_at', '>', $reactionsLast);
            })
            ->count();

        $favoritesCount = PostFavorite::query()
            ->join('posts', 'posts.id', '=', 'post_favorites.post_id')
            ->where('posts.user_id', $user->id)
            ->when($reactionsLast, function ($q) use ($reactionsLast) {
                $q->where('post_favorites.created_at', '>', $reactionsLast);
            })
            ->count();

        $reactionsCount = $likesCount + $favoritesCount;

        $followsCount = Follow::query()
            ->where('followed_id', $user->id)
            ->when($followsLast, function ($q) use ($followsLast) {
                $q->where('created_at', '>', $followsLast);
            })
            ->count();

        $commentsCount = PostComment::query()
            ->join('posts', 'posts.id', '=', 'post_comments.post_id')
            ->where('posts.user_id', $user->id)
            ->when($commentsLast, function ($q) use ($commentsLast) {
                $q->where('post_comments.created_at', '>', $commentsLast);
            })
            ->count();

        $systemCount = SystemNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'reactions' => $reactionsCount,
            'follows' => $followsCount,
            'comments' => $commentsCount,
            'system' => $systemCount,
            'total' => $reactionsCount + $followsCount + $commentsCount + $systemCount,
        ]);
    }

    public function markReactionsAllRead(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $record = MessageLastRead::query()->firstOrCreate(['user_id' => $user->id]);
        $record->reactions_last_read_at = now();
        $record->save();
        return response()->json(['status' => 'ok']);
    }

    public function markFollowsAllRead(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $record = MessageLastRead::query()->firstOrCreate(['user_id' => $user->id]);
        $record->follows_last_read_at = now();
        $record->save();
        return response()->json(['status' => 'ok']);
    }

    public function markCommentsAllRead(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);
        $record = MessageLastRead::query()->firstOrCreate(['user_id' => $user->id]);
        $record->comments_last_read_at = now();
        $record->save();
        return response()->json(['status' => 'ok']);
    }
}