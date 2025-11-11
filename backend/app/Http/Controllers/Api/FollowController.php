<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Follow;
use App\Models\User;
use Illuminate\Http\Request;

class FollowController extends Controller
{
    public function follow(User $user, Request $request)
    {
        $me = $request->user();
        if (!$me) return response()->json(['message' => 'Unauthorized'], 401);
        if ($me->id === $user->id) return response()->json(['message' => 'Cannot follow self'], 422);
        Follow::firstOrCreate(['follower_id' => $me->id, 'followed_id' => $user->id]);
        return response()->json(['is_following' => true]);
    }

    public function unfollow(User $user, Request $request)
    {
        $me = $request->user();
        if (!$me) return response()->json(['message' => 'Unauthorized'], 401);
        Follow::where('follower_id', $me->id)->where('followed_id', $user->id)->delete();
        return response()->json(['is_following' => false]);
    }
}