<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        // 创建默认管理员账号（如不存在）
        $email = 'admin@example.com';
        $password = 'admin123';
        $admin = User::where('email', $email)->first();
        if (!$admin) {
            User::create([
                'name' => 'Administrator',
                'email' => $email,
                'password' => Hash::make($password),
                'is_admin' => true,
            ]);
        } else {
            // 确保已有该邮箱用户被设为管理员
            if (!$admin->is_admin) {
                $admin->update(['is_admin' => true]);
            }
        }
    }
}
