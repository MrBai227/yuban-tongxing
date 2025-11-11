@extends('admin.layout')

@section('content')
<div class="card">
    <h2>树洞管理</h2>
    <p class="muted">管理树洞（心情）列表，支持删除；数据来自后端 API。</p>
    <div id="treeholes-app" class="mt-3">
        <div class="muted">加载中...</div>
    </div>
</div>

<script>
// 简易 cookie 读取
function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return decodeURIComponent(parts.pop().split(';').shift());
    return null;
}

async function ensureCsrf() {
    try { await fetch('/sanctum/csrf-cookie', { credentials: 'same-origin' }); } catch (e) { /* ignore */ }
}

async function apiGet(url) {
    const res = await fetch(url, { credentials: 'same-origin' });
    return res.json();
}

async function apiPost(url, data) {
    await ensureCsrf();
    const xsrf = getCookie('XSRF-TOKEN');
    const res = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-XSRF-TOKEN': xsrf || '',
        },
        credentials: 'same-origin',
        body: JSON.stringify(data),
    });
    return res.ok ? res.json() : Promise.reject(await res.text());
}

async function apiPut(url, data) {
    await ensureCsrf();
    const xsrf = getCookie('XSRF-TOKEN');
    const res = await fetch(url, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'X-XSRF-TOKEN': xsrf || '',
        },
        credentials: 'same-origin',
        body: JSON.stringify(data),
    });
    return res.ok ? res.json() : Promise.reject(await res.text());
}

async function apiDelete(url) {
    await ensureCsrf();
    const xsrf = getCookie('XSRF-TOKEN');
    const res = await fetch(url, {
        method: 'DELETE',
        headers: {
            'Accept': 'application/json',
            'X-XSRF-TOKEN': xsrf || '',
        },
        credentials: 'same-origin',
    });
    return res.ok ? res.json() : Promise.reject(await res.text());
}

function renderTreeholes(container, resp) {
    const data = resp.data || [];
    const hasMore = !!resp.has_more;
    const currentPage = resp.current_page || 1;

    const rows = data.map(m => `
        <tr>
          <td class="text-slate-700">${m.id}</td>
          <td class="text-slate-900">${m.content ? m.content.replace(/</g,'&lt;') : ''}</td>
          <td class="text-slate-700">${m.likes}</td>
          <td class="text-slate-700">${m.comments}</td>
          <td class="text-slate-700">${m.author && m.author.name ? m.author.name : (m.is_anonymous ? '匿名' : '')}</td>
          <td class="text-slate-700">${m.created_at || ''}</td>
          <td>
            <button class="btn" data-id="${m.id}" data-action="edit">编辑</button>
            <button class="btn btn-danger" data-id="${m.id}" data-action="delete">删除</button>
          </td>
        </tr>
    `).join('');

    container.innerHTML = `
      <div class="mb-3 flex items-end gap-2">
        <div>
            <label class="block text-slate-700">内容</label>
            <input type="text" id="mood-content" class="form-input" placeholder="发布内容">
        </div>
        <div class="flex items-center gap-2">
            <input type="checkbox" id="mood-anon">
            <label for="mood-anon" class="text-slate-700">匿名</label>
        </div>
        <button class="btn btn-primary" id="create-btn">发布</button>
        <button class="btn" id="refresh-btn">刷新</button>
      </div>
      <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th>ID</th>
              <th>内容</th>
              <th>点赞</th>
              <th>评论</th>
              <th>作者</th>
              <th>创建时间</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            ${rows}
          </tbody>
        </table>
      </div>
      <div class="mt-2 muted">第 ${currentPage} 页${hasMore ? '，还有更多…' : ''}</div>
    `;

    container.querySelectorAll('button[data-action="delete"]').forEach(btn => {
        btn.addEventListener('click', async () => {
            const id = btn.getAttribute('data-id');
            if (!id) return;
            if (!confirm('确认删除该树洞？')) return;
            try { await apiDelete(`/api/moods/${id}`); loadAndRender(container); }
            catch (e) { alert('删除失败：' + e); }
        });
    });
    container.querySelectorAll('button[data-action="edit"]').forEach(btn => {
        btn.addEventListener('click', async () => {
            const id = btn.getAttribute('data-id');
            const content = prompt('请输入新的内容');
            if (!content) return;
            const isAnon = confirm('是否匿名？确定为匿名，取消为非匿名');
            try { await apiPut(`/api/moods/${id}`, { content, is_anonymous: isAnon }); loadAndRender(container); }
            catch (e) { alert('编辑失败：' + e); }
        });
    });
    const refreshBtn = container.querySelector('#refresh-btn');
    if (refreshBtn) refreshBtn.addEventListener('click', () => loadAndRender(container));
}

async function loadAndRender(container) {
    try {
        const resp = await apiGet('/api/moods?per_page=10&page=1');
        renderTreeholes(container, resp);
    } catch (e) {
        container.innerHTML = `<div class="rounded-lg border border-red-300 bg-red-100 text-red-700 px-3 py-2">加载失败：${e}</div>`;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const container = document.getElementById('treeholes-app');
    if (container) {
        loadAndRender(container);
    }
    const createBtn = document.getElementById('create-btn');
    if (createBtn) {
        createBtn.addEventListener('click', async () => {
            const contentEl = document.getElementById('mood-content');
            const anonEl = document.getElementById('mood-anon');
            const content = (contentEl && contentEl.value || '').trim();
            const isAnon = !!(anonEl && anonEl.checked);
            if (!content) { alert('内容不能为空'); return; }
            try { await apiPost('/api/moods', { content, is_anonymous: isAnon }); if (contentEl) contentEl.value=''; if (anonEl) anonEl.checked=false; loadAndRender(container); }
            catch (e) { alert('发布失败：' + e); }
        });
    }
});
</script>
@endsection