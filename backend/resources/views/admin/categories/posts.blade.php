@extends('admin.layout')

@section('content')
<div class="card">
    <h2>分类帖子管理</h2>
    <p class="muted">按分类浏览与管理帖子，支持编辑与删除。</p>

    <div class="mt-3 flex items-end gap-2">
        <div>
            <label class="block text-slate-700">分类</label>
            <select id="category-select" class="form-input"></select>
        </div>
        <div>
            <label class="block text-slate-700">排序</label>
            <select id="sort-select" class="form-input">
                <option value="latest">最新</option>
                <option value="hot">最热</option>
            </select>
        </div>
        <a class="btn" href="{{ route('admin.posts.create') }}" target="_self">创建帖子</a>
        <button class="btn" id="refresh-btn">刷新</button>
    </div>

    <div id="category-posts-app" class="mt-3">
        <div class="muted">加载中...</div>
    </div>
</div>

<script>
async function apiGet(url) {
    const res = await fetch(url, { credentials: 'same-origin' });
    return res.json();
}

function getCsrfToken() {
    const el = document.querySelector('meta[name="csrf-token"]');
    return el ? el.getAttribute('content') : '';
}

async function webDelete(url) {
    const res = await fetch(url, {
        method: 'DELETE',
        headers: { 'X-CSRF-TOKEN': getCsrfToken() },
        credentials: 'same-origin',
    });
    if (!res.ok) throw new Error(await res.text());
}

function renderPosts(container, posts) {
    const rows = (posts || []).map(p => `
        <tr>
          <td class="text-slate-700">${p.id}</td>
          <td class="text-slate-900">${p.title}</td>
          <td class="text-slate-700">${p.category_key}</td>
          <td class="text-slate-700">${p.created_at || ''}</td>
          <td class="text-slate-700">👍 ${p.likes}｜💬 ${p.comments}｜⭐ ${p.favorites}</td>
          <td>
            <a class="btn" href="/admin/posts/${p.id}/edit">编辑</a>
            <button class="btn btn-danger" data-id="${p.id}" data-action="delete">删除</button>
          </td>
        </tr>
    `).join('');

    container.innerHTML = `
      <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th>ID</th>
              <th>标题</th>
              <th>分类键</th>
              <th>创建时间</th>
              <th>统计</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            ${rows}
          </tbody>
        </table>
      </div>
    `;

    container.querySelectorAll('button[data-action="delete"]').forEach(btn => {
        btn.addEventListener('click', async () => {
            const id = btn.getAttribute('data-id');
            if (!id) return;
            if (!confirm('确认删除该帖子？')) return;
            try { await webDelete(`/admin/posts/${id}`); await loadAndRender(container); }
            catch (e) { alert('删除失败：' + e); }
        });
    });
}

async function loadAndRender(container) {
    try {
        const categoryEl = document.getElementById('category-select');
        const sortEl = document.getElementById('sort-select');
        const key = categoryEl ? categoryEl.value : '';
        const sort = sortEl ? sortEl.value : 'latest';
        const resp = await apiGet(`/api/posts?per_page=20&page=1${key ? `&category_key=${encodeURIComponent(key)}` : ''}&sort=${encodeURIComponent(sort)}`);
        renderPosts(container, resp.data || resp.content || resp);
    } catch (e) {
        container.innerHTML = `<div class="rounded-lg border border-red-300 bg-red-100 text-red-700 px-3 py-2">加载失败：${e}</div>`;
    }
}

async function initSelectors() {
    const categoryEl = document.getElementById('category-select');
    const sortEl = document.getElementById('sort-select');
    const refreshBtn = document.getElementById('refresh-btn');
    const container = document.getElementById('category-posts-app');

    try {
        const cats = await apiGet('/api/categories');
        const items = Array.isArray(cats) ? cats : (cats.data || []);
        categoryEl.innerHTML = `<option value="">全部</option>` + items.map(c => `<option value="${c.key}">${c.name}</option>`).join('');
    } catch (_) {
        categoryEl.innerHTML = `<option value="">全部</option>`;
    }

    if (sortEl) sortEl.addEventListener('change', () => loadAndRender(container));
    if (categoryEl) categoryEl.addEventListener('change', () => loadAndRender(container));
    if (refreshBtn) refreshBtn.addEventListener('click', () => loadAndRender(container));
}

document.addEventListener('DOMContentLoaded', async () => {
    await initSelectors();
    const container = document.getElementById('category-posts-app');
    if (container) { loadAndRender(container); }
});
</script>
@endsection