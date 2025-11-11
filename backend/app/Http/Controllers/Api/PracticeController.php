<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PracticeLog;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class PracticeController extends Controller
{
    /**
     * Create a practice log (打卡).
     */
    public function store(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $data = $request->validate([
            'duration_seconds' => ['required','integer','min:0','max:86400'],
            'soft_onset_seconds' => ['nullable','integer','min:0','max:86400'],
            'prolonged_seconds' => ['nullable','integer','min:0','max:86400'],
            'reading_seconds' => ['nullable','integer','min:0','max:86400'],
            'note' => ['nullable','string','max:255'],
        ]);

        $log = PracticeLog::create([
            'user_id' => $user->id,
            'duration_seconds' => $data['duration_seconds'] ?? 0,
            'soft_onset_seconds' => $data['soft_onset_seconds'] ?? 0,
            'prolonged_seconds' => $data['prolonged_seconds'] ?? 0,
            'reading_seconds' => $data['reading_seconds'] ?? 0,
            'note' => $data['note'] ?? null,
        ]);

        return response()->json(['id' => $log->id, 'created_at' => $log->created_at], 201);
    }

    /**
     * List practice logs for the current user.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $perPage = min(max((int) $request->get('per_page', 10), 1), 50);
        $page = max((int) $request->get('page', 1), 1);
        $paginator = PracticeLog::query()
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->paginate($perPage, ['*'], 'page', $page);

        $items = collect($paginator->items())->map(function (PracticeLog $l) {
            return [
                'id' => $l->id,
                'duration_seconds' => $l->duration_seconds,
                'soft_onset_seconds' => $l->soft_onset_seconds,
                'prolonged_seconds' => $l->prolonged_seconds,
                'reading_seconds' => $l->reading_seconds,
                'note' => $l->note,
                'created_at' => $l->created_at,
            ];
        })->values();

        return response()->json([
            'data' => $items,
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    /**
     * Simple stats for the current user.
     */
    public function stats(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $total = PracticeLog::query()->where('user_id', $user->id)->count();

        // streak by day (naive): consecutive days with at least one log
        $days = PracticeLog::query()
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get(['created_at'])
            ->map(fn($l) => $l->created_at->toDateString())
            ->unique()
            ->values();

        $streak = 0;
        $cursor = Carbon::now()->toDateString();
        foreach ($days as $d) {
            if ($d === $cursor) {
                $streak += 1;
                $cursor = Carbon::parse($cursor)->subDay()->toDateString();
            } else {
                break;
            }
        }

        return response()->json([
            'total' => $total,
            'streak' => $streak,
        ]);
    }
}