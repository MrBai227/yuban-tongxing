<?php

namespace App\Http\Controllers;

use App\Models\Mood;
use App\Models\MoodLike;
use App\Models\MoodView;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class MoodController extends Controller
{
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);
        $query = Mood::query()->with('user')
            ->withCount('comments')
            ->withCount('likes')
            ->withCount('views')
            ->orderByDesc('id');

        // Author filter: support 'me' or numeric user_id
        $author = $request->get('author');
        if ($author) {
            $user = $request->user();
            if ($author === 'me') {
                if (!$user) { return response()->json(['message' => 'Unauthorized'], 401); }
                $query->where('user_id', $user->id);
            } else if (is_numeric($author)) {
                $query->where('user_id', (int)$author);
            }
        }

        $paginator = $query->paginate($perPage, ['*'], 'page', $page);
        $user = Auth::user();
        $data = $paginator->getCollection()->map(function (Mood $m) use ($user) {
            $likedByMe = false;
            if ($user) {
                $likedByMe = MoodLike::query()->where('mood_id', $m->id)->where('user_id', $user->id)->exists();
            }
            return [
                'id' => $m->id,
                'content' => $m->content,
                'is_anonymous' => (bool) $m->is_anonymous,
                'created_at' => $m->created_at,
                'comments' => $m->comments_count,
                'likes' => $m->likes_count,
                'views' => $m->views_count,
                'liked_by_me' => $likedByMe,
                'owned_by_me' => $user ? $user->id === $m->user_id : false,
                'author' => $m->is_anonymous ? [
                    'name' => '匿名',
                    'avatar_url' => null,
                ] : [
                    'id' => $m->user_id,
                    'name' => ($m->user ? $m->user->name : null),
                    'avatar_url' => ($m->user && isset($m->user->avatar_url)) ? $m->user->avatar_url : null,
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

    // Record a view of a mood
    public function view(Mood $mood, Request $request)
    {
        $user = $request->user();
        MoodView::firstOrCreate([
            'mood_id' => $mood->id,
            'user_id' => $user ? $user->id : null,
        ]);
        return response()->json(['ok' => true]);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        $validated = $request->validate([
            'content' => ['required', 'string', 'max:1000'],
            'is_anonymous' => ['boolean'],
        ]);
        $mood = Mood::create([
            'user_id' => $user->id,
            'content' => $validated['content'],
            'is_anonymous' => (bool)($validated['is_anonymous'] ?? false),
        ]);
        return response()->json(['id' => $mood->id], 201);
    }

    public function destroy(Mood $mood, Request $request)
    {
        $user = $request->user();
        if (!$user) { return response()->json(['message' => 'Unauthorized'], 401); }
        if ($user->id !== $mood->user_id && !$user->is_admin) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        $mood->delete();
        return response()->json(['ok' => true]);
    }

    public function update(Mood $mood, Request $request)
    {
        $user = $request->user();
        if (!$user) { return response()->json(['message' => 'Unauthorized'], 401); }
        // 允许作者或管理员更新
        if ($user->id !== $mood->user_id && !$user->is_admin) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        $data = $request->validate([
            'content' => ['required','string','max:1000'],
            'is_anonymous' => ['boolean'],
        ]);
        $mood->update([
            'content' => $data['content'],
            'is_anonymous' => (bool)($data['is_anonymous'] ?? false),
        ]);
        return response()->json(['ok' => true]);
    }
}