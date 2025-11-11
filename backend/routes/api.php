<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\MoodController;
use App\Http\Controllers\MoodCommentController;
use App\Http\Controllers\MoodLikeController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\Api\PostController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\PostLikeController;
use App\Http\Controllers\Api\PostFavoriteController;
use App\Http\Controllers\Api\PostCommentController;
use App\Http\Controllers\Api\UserActivityController;
use App\Http\Controllers\Api\PostViewController;
use App\Http\Controllers\Api\FollowController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\PracticeController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Tree Hole (Moods)
Route::get('/moods', [MoodController::class, 'index']);
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/moods', [MoodController::class, 'store']);
    Route::put('/moods/{mood}', [MoodController::class, 'update']);
    Route::delete('/moods/{mood}', [MoodController::class, 'destroy']);
    // 浏览记录打点（树洞）
    Route::post('/moods/{mood}/view', [MoodController::class, 'view']);

    Route::post('/moods/{mood}/like', [MoodLikeController::class, 'like']);
    Route::delete('/moods/{mood}/like', [MoodLikeController::class, 'unlike']);

    Route::post('/moods/{mood}/comments', [MoodCommentController::class, 'store']);
    Route::delete('/comments/{comment}', [MoodCommentController::class, 'destroy']);
});
Route::get('/moods/{mood}/comments', [MoodCommentController::class, 'index']);

// Categories API
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/categories/{key}', [CategoryController::class, 'show']);

// Categories Admin CRUD (protected)
Route::middleware(['auth:sanctum','admin'])->group(function () {
    Route::post('/categories', [CategoryController::class, 'store']);
    Route::put('/categories/{key}', [CategoryController::class, 'update']);
    Route::delete('/categories/{key}', [CategoryController::class, 'destroy']);
});

// Profile API
Route::middleware('auth:sanctum')->group(function () {
    Route::put('/user', [ProfileController::class, 'update']);
    Route::post('/user/avatar', [ProfileController::class, 'uploadAvatar']);
    Route::put('/user/password', [ProfileController::class, 'changePassword']);
});

// Posts API
Route::get('/posts', [PostController::class, 'index']);
Route::middleware('auth:sanctum')->post('/posts', [PostController::class, 'store']);
Route::get('/posts/{post}/comments', [PostCommentController::class, 'index']);
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/posts/{post}/comments', [PostCommentController::class, 'store']);
    Route::delete('/post_comments/{comment}', [PostCommentController::class, 'destroy']);

    Route::post('/posts/{post}/like', [PostLikeController::class, 'like']);
    Route::delete('/posts/{post}/like', [PostLikeController::class, 'unlike']);

    Route::post('/posts/{post}/favorite', [PostFavoriteController::class, 'favorite']);
    Route::delete('/posts/{post}/favorite', [PostFavoriteController::class, 'unfavorite']);

    // 浏览记录打点
    Route::post('/posts/{post}/view', [PostViewController::class, 'record']);

    // 我的点赞/收藏/浏览记录
    Route::get('/me/likes', [UserActivityController::class, 'likes']);
    Route::get('/me/favorites', [UserActivityController::class, 'favorites']);
    Route::get('/me/views', [UserActivityController::class, 'views']);
    Route::get('/me/comments', [UserActivityController::class, 'commentsByMe']);
    // 我的社交关系与统计
    Route::get('/me/followings', [UserActivityController::class, 'followings']);
    Route::get('/me/followers', [UserActivityController::class, 'followers']);
    Route::get('/me/stats_received', [UserActivityController::class, 'statsReceived']);
    Route::get('/me/mutuals', [UserActivityController::class, 'mutuals']);

    // 消息中心
    Route::get('/messages/reactions', [MessageController::class, 'reactions']);
    Route::get('/messages/follows', [MessageController::class, 'follows']);
    Route::get('/messages/comments', [MessageController::class, 'commentsMentions']);
    Route::get('/messages/system', [MessageController::class, 'system']);
    Route::get('/messages/system/unread_count', [MessageController::class, 'systemUnreadCount']);
    Route::post('/messages/system/mark_all_read', [MessageController::class, 'markSystemAllRead']);
    Route::get('/messages/unread_counts', [MessageController::class, 'unreadCounts']);
    Route::post('/messages/reactions/mark_all_read', [MessageController::class, 'markReactionsAllRead']);
    Route::post('/messages/follows/mark_all_read', [MessageController::class, 'markFollowsAllRead']);
    Route::post('/messages/comments/mark_all_read', [MessageController::class, 'markCommentsAllRead']);

    // Follow API
    Route::post('/users/{user}/follow', [FollowController::class, 'follow']);
    Route::delete('/users/{user}/follow', [FollowController::class, 'unfollow']);

    // Practice API (打卡)
    Route::post('/practice/logs', [PracticeController::class, 'store']);
    Route::get('/practice/logs', [PracticeController::class, 'index']);
    Route::get('/practice/stats', [PracticeController::class, 'stats']);
});

// Auth API
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);
