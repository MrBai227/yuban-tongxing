<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class UsersController extends Controller
{
    public function index()
    {
        $users = User::orderByDesc('id')->paginate(20);
        return view('admin.users.index', compact('users'));
    }

    public function makeAdmin(User $user)
    {
        $user->update(['is_admin' => true]);
        return back()->with('status', '已设为管理员');
    }

    public function revokeAdmin(User $user)
    {
        $user->update(['is_admin' => false]);
        return back()->with('status', '已取消管理员');
    }

    public function destroy(User $user)
    {
        // 防止删除自己
        if (auth()->id() === $user->id) {
            return back()->withErrors(['op' => '不能删除当前登录管理员']);
        }
        $user->delete();
        return back()->with('status', '用户已删除');
    }
}