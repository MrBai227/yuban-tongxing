<?php

namespace App\Http\Controllers;

use App\Models\Mood;
use App\Models\MoodLike;
use Illuminate\Http\Request;

class MoodLikeController extends Controller
{
    public function like(Mood $mood, Request $request)
    {
        $user = $request->user();
        MoodLike::firstOrCreate(['mood_id' => $mood->id, 'user_id' => $user->id]);
        $likes = MoodLike::query()->where('mood_id', $mood->id)->count();
        return response()->json(['likes' => $likes, 'liked_by_me' => true]);
    }

    public function unlike(Mood $mood, Request $request)
    {
        $user = $request->user();
        MoodLike::query()->where('mood_id', $mood->id)->where('user_id', $user->id)->delete();
        $likes = MoodLike::query()->where('mood_id', $mood->id)->count();
        return response()->json(['likes' => $likes, 'liked_by_me' => false]);
    }
}