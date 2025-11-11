<?php

namespace App\Http\Controllers;

use App\Models\Mood;
use App\Models\MoodComment;
use Illuminate\Http\Request;

class MoodCommentController extends Controller
{
    public function index(Mood $mood, Request $request)
    {
        $perPage = min(max((int) $request->get('per_page', 20), 1), 100);
        $page = max((int) $request->get('page', 1), 1);
        $query = MoodComment::query()->where('mood_id', $mood->id)->with('user')->orderBy('id');
        $paginator = $query->paginate($perPage, ['*'], 'page', $page);

        // Group into a two-level tree (parent -> children)
        $items = $paginator->getCollection();
        $byParent = [];
        foreach ($items as $c) {
            $pid = $c->parent_id ?: 0;
            $byParent[$pid][] = $c;
        }
        $tree = [];
        foreach (($byParent[0] ?? []) as $root) {
            $node = [
                'id' => $root->id,
                'content' => $root->content,
                'created_at' => $root->created_at,
                'owned_by_me' => (($request->user() ? $request->user()->id : 0) === $root->user_id),
                'author' => [
                    'name' => ($root->user ? $root->user->name : null),
                    'avatar_url' => ($root->user && isset($root->user->avatar_url)) ? $root->user->avatar_url : null,
                ],
                'children' => [],
            ];
            foreach (($byParent[$root->id] ?? []) as $child) {
                $node['children'][] = [
                    'id' => $child->id,
                    'content' => $child->content,
                    'created_at' => $child->created_at,
                    'owned_by_me' => (($request->user() ? $request->user()->id : 0) === $child->user_id),
                    'author' => [
                        'name' => ($child->user ? $child->user->name : null),
                        'avatar_url' => ($child->user && isset($child->user->avatar_url)) ? $child->user->avatar_url : null,
                    ],
                ];
            }
            $tree[] = $node;
        }

        return response()->json([
            'data' => $tree,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    public function store(Mood $mood, Request $request)
    {
        $user = $request->user();
        $validated = $request->validate([
            'content' => ['required', 'string', 'max:300'],
            'parent_id' => ['nullable', 'integer'],
        ]);
        $parentId = $validated['parent_id'] ?? null;
        if ($parentId) {
            $exists = MoodComment::query()->where('id', $parentId)->where('mood_id', $mood->id)->exists();
            if (!$exists) {
                return response()->json(['message' => 'Invalid parent'], 422);
            }
        }
        MoodComment::create([
            'mood_id' => $mood->id,
            'user_id' => $user->id,
            'content' => $validated['content'],
            'parent_id' => $parentId,
        ]);
        return response()->json(['ok' => true], 201);
    }

    public function destroy(MoodComment $comment, Request $request)
    {
        if ($comment->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        $comment->delete();
        return response()->json(['ok' => true]);
    }
}