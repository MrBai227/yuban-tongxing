<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class ProfileController extends Controller
{
    public function update(Request $request)
    {
        $user = $request->user();
        $validated = $request->validate([
            'name' => 'nullable|string|max:255',
            'bio' => 'nullable|string',
            'account_id' => 'nullable|string|max:64|unique:users,account_id,' . $user->id,
            'gender' => 'nullable|string|max:32',
            'gender_public' => 'nullable|boolean',
            'region' => 'nullable|string|max:64',
            'region_public' => 'nullable|boolean',
        ]);
        $user->fill($validated);
        $user->save();
        return response()->json($user);
    }

    public function uploadAvatar(Request $request)
    {
        $user = $request->user();
        $request->validate([
            'avatar' => 'required|file|mimes:jpg,jpeg,png,webp|max:2048',
        ]);

        $path = $request->file('avatar')->store('avatars', 'public');
        $relative = Storage::url($path); // /storage/avatars/xxx.png
        // Persist relative path; runtime accessor will rewrite to CORS-safe URL
        $user->avatar_url = $relative;
        $user->save();

        // Return CORS-safe absolute URL for web clients
        $host = rtrim($request->getSchemeAndHttpHost(), '/');
        $servePath = 'avatar/' . ltrim(str_replace('/storage/', '', $relative), '/');
        $absolute = $host . '/' . $servePath;
        return response()->json(['avatar_url' => $absolute, 'user' => $user]);
    }

    // Serve avatars with CORS headers for Flutter Web
    public function avatar(Request $request, string $path)
    {
        // Restrict to public avatars folder; avoid duplicating 'avatars/'
        $relative = ltrim($path, '/');
        if (!Str::startsWith($relative, 'avatars/')) {
            $relative = 'avatars/' . $relative;
        }
        $diskPath = storage_path('app/public/' . $relative);
        if (!file_exists($diskPath)) {
            return response('Not Found', 404)->header('Access-Control-Allow-Origin', '*');
        }
        $mime = function_exists('mime_content_type') ? mime_content_type($diskPath) : 'image/jpeg';
        return response()->file($diskPath, [
            'Access-Control-Allow-Origin' => '*',
            'Cache-Control' => 'public, max-age=604800',
            'Content-Type' => $mime,
        ]);
    }

    public function changePassword(Request $request)
    {
        $user = $request->user();
        $validated = $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6',
        ]);

        if (! Hash::check($validated['current_password'], $user->password)) {
            return response()->json(['message' => '当前密码不正确'], 422);
        }

        $user->password = Hash::make($validated['new_password']);
        $user->save();

        return response()->json(['ok' => true]);
    }
}