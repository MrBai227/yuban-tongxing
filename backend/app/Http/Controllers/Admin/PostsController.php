<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\SystemNotification;
use Illuminate\Http\Request;

class PostsController extends Controller
{
    public function index()
    {
        $posts = Post::orderByDesc('id')->paginate(20);
        return view('admin.posts.index', compact('posts'));
    }

    public function create()
    {
        return view('admin.posts.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string'],
            'category_key' => ['required', 'string', 'max:64'],
        ]);
        Post::create($data);
        return redirect()->route('admin.posts.index')->with('status', '帖子已创建');
    }

    public function edit(Post $post)
    {
        return view('admin.posts.edit', compact('post'));
    }

    public function update(Request $request, Post $post)
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string'],
            'category_key' => ['required', 'string', 'max:64'],
        ]);
        $post->update($data);
        return redirect()->route('admin.posts.index')->with('status', '帖子已更新');
    }

    public function destroy(Post $post)
    {
        // 向发帖人发送系统通知：帖子因违规被删除
        if ($post->user_id) {
            try {
                SystemNotification::create([
                    'user_id' => $post->user_id,
                    'type' => 'post_deleted',
                    'title' => '帖子违规删除通知',
                    'content' => sprintf('你的帖子《%s》因违反社区规范已被管理员删除。', $post->title ?? ''),
                ]);
            } catch (\Throwable $e) {
                // 忽略通知创建失败，继续删除流程
            }
        }

        $post->delete();
        return redirect()->route('admin.posts.index')->with('status', '帖子已删除');
    }
}