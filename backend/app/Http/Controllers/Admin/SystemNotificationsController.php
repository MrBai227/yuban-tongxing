<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SystemNotification;
use App\Models\User;
use Illuminate\Http\Request;

class SystemNotificationsController extends Controller
{
    public function index()
    {
        $notifications = SystemNotification::query()
            ->orderByDesc('id')
            ->paginate(20);
        return view('admin.system_notifications.index', compact('notifications'));
    }

    public function create()
    {
        $users = User::query()->orderBy('id')->limit(100)->get(['id','name','email']);
        return view('admin.system_notifications.create', compact('users'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'type' => ['nullable','string','max:50'],
            'title' => ['required','string','max:255'],
            'content' => ['nullable','string'],
            'target' => ['required','string'], // 'all' 或 'one'
            'user_id' => ['nullable','integer','exists:users,id'],
        ]);

        if ($validated['target'] === 'all') {
            $count = 0;
            User::query()->select('id')->chunk(500, function ($users) use ($validated, &$count) {
                $rows = [];
                $now = now();
                foreach ($users as $u) {
                    $rows[] = [
                        'user_id' => $u->id,
                        'type' => $validated['type'] ?? null,
                        'title' => $validated['title'],
                        'content' => $validated['content'] ?? null,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                }
                SystemNotification::query()->insert($rows);
                $count += count($rows);
            });
            return redirect()->route('admin.system_notifications.index')->with('status', "已向所有用户发送 {$count} 条通知");
        }

        // 指定单个用户
        if (! $validated['user_id']) {
            return back()->withErrors(['user_id' => '请指定接收用户'])->withInput();
        }
        SystemNotification::create([
            'user_id' => $validated['user_id'],
            'type' => $validated['type'] ?? null,
            'title' => $validated['title'],
            'content' => $validated['content'] ?? null,
        ]);
        return redirect()->route('admin.system_notifications.index')->with('status', '系统通知已创建');
    }

    public function destroy(SystemNotification $notification)
    {
        $notification->delete();
        return back()->with('status', '已删除通知');
    }
}