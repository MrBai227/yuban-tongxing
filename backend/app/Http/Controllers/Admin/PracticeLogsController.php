<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PracticeLog;
use App\Models\User;
use Illuminate\Http\Request;

class PracticeLogsController extends Controller
{
    public function index()
    {
        $logs = PracticeLog::query()->with('user')->orderByDesc('created_at')->paginate(20);
        return view('admin.practice_logs.index', compact('logs'));
    }

    public function create()
    {
        // 提供一个简单的用户选择（可选），也允许直接填 user_id
        $users = User::query()->orderBy('id')->limit(100)->get(['id','name']);
        return view('admin.practice_logs.create', compact('users'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => ['required','integer','exists:users,id'],
            'duration_seconds' => ['required','integer','min:0','max:86400'],
            'soft_onset_seconds' => ['nullable','integer','min:0','max:86400'],
            'prolonged_seconds' => ['nullable','integer','min:0','max:86400'],
            'reading_seconds' => ['nullable','integer','min:0','max:86400'],
            'note' => ['nullable','string','max:255'],
        ]);

        PracticeLog::create([
            'user_id' => $data['user_id'],
            'duration_seconds' => $data['duration_seconds'],
            'soft_onset_seconds' => $data['soft_onset_seconds'] ?? 0,
            'prolonged_seconds' => $data['prolonged_seconds'] ?? 0,
            'reading_seconds' => $data['reading_seconds'] ?? 0,
            'note' => $data['note'] ?? null,
        ]);

        return redirect()->route('admin.practice_logs.index')->with('status', '已新增练习打卡记录');
    }
}