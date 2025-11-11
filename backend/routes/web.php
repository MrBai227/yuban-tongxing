<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\CategoryPageController;
use App\Http\Controllers\Web\PostPageController;
use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\UsersController;
use App\Http\Controllers\Admin\PostsController;
use App\Http\Controllers\Admin\SystemNotificationsController;
use App\Http\Controllers\Api\ProfileController;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return redirect('/admin');
});
// 前台分类页已移除
Route::get('/posts/{post}', [PostPageController::class, 'show']);

// Serve avatars with CORS headers for Flutter Web
Route::get('/avatar/{path}', [ProfileController::class, 'avatar'])->where('path', '.*');

// Admin Routes
// Provide a standard 'login' route name for middleware redirects
Route::get('/login', [AuthController::class, 'showLoginForm'])->name('login');

Route::prefix('admin')->group(function () {
    Route::get('/login', [AuthController::class, 'showLoginForm'])->name('admin.login');
    Route::post('/login', [AuthController::class, 'login'])->name('admin.login.post');

    Route::middleware(['auth', 'admin'])->group(function () {
        Route::get('/', function () { return view('admin.dashboard'); })->name('admin.dashboard');
        Route::post('/logout', [AuthController::class, 'logout'])->name('admin.logout');

        // Users management
        Route::get('/users', [UsersController::class, 'index'])->name('admin.users.index');
        Route::post('/users/{user}/make_admin', [UsersController::class, 'makeAdmin'])->name('admin.users.make_admin');
        Route::post('/users/{user}/revoke_admin', [UsersController::class, 'revokeAdmin'])->name('admin.users.revoke_admin');
        Route::delete('/users/{user}', [UsersController::class, 'destroy'])->name('admin.users.destroy');

        // Posts CRUD
        Route::get('/posts', [PostsController::class, 'index'])->name('admin.posts.index');
        Route::get('/posts/create', [PostsController::class, 'create'])->name('admin.posts.create');
        Route::post('/posts', [PostsController::class, 'store'])->name('admin.posts.store');
        Route::get('/posts/{post}/edit', [PostsController::class, 'edit'])->name('admin.posts.edit');
        Route::put('/posts/{post}', [PostsController::class, 'update'])->name('admin.posts.update');
        Route::delete('/posts/{post}', [PostsController::class, 'destroy'])->name('admin.posts.destroy');

        // Tree Holes (Moods) management - placeholder page
        Route::get('/treeholes', function () { return view('admin.treeholes.index'); })->name('admin.treeholes.index');

        // Categories management - placeholder page
        Route::get('/categories', function () { return view('admin.categories.index'); })->name('admin.categories.index');

        // Category Posts management page
        Route::get('/categories/posts', function () { return view('admin.categories.posts'); })->name('admin.categories.posts');

        // System Notifications management
        Route::get('/system_notifications', [SystemNotificationsController::class, 'index'])->name('admin.system_notifications.index');
        Route::get('/system_notifications/create', [SystemNotificationsController::class, 'create'])->name('admin.system_notifications.create');
        Route::post('/system_notifications', [SystemNotificationsController::class, 'store'])->name('admin.system_notifications.store');
        Route::delete('/system_notifications/{notification}', [SystemNotificationsController::class, 'destroy'])->name('admin.system_notifications.destroy');
    });
});
