@extends('admin.layout')

@section('content')
<div class="card">
    <h2>分类管理</h2>
    <p class="muted">分类来自后端API，可新增、编辑与删除。</p>
    <div class="mt-3">
        <form id="create-form" class="flex items-end gap-2">
            <div>
                <label class="block text-slate-700">键</label>
                <input type="text" name="key" class="form-input" placeholder="如 experience" required>
            </div>
            <div>
                <label class="block text-slate-700">名称</label>
                <input type="text" name="name" class="form-input" placeholder="如 经验交流" required>
            </div>
            <div>
                <label class="block text-slate-700">描述</label>
                <input type="text" name="desc" class="form-input" placeholder="可选">
            </div>
            <button type="submit" class="btn btn-primary">新增分类</button>
        </form>
    </div>
    <div id="categories-app" class="mt-3">
        <div class="muted">加载中...</div>
    </div>
</div>

<script>
async function ensureCsrf() {
    try { await fetch('/sanctum/csrf-cookie', { credentials: 'same-origin' }); } catch (e) {}
}

async function apiGet(url) {
    const res = await fetch(url, { credentials: 'same-origin' });
    return res.json();
}

async function apiPost(url, data) {
    await ensureCsrf();
    const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'same-origin',
        body: JSON.stringify(data),
    });
    return res.ok ? res.json() : Promise.reject(await res.text());
}

async function apiPut(url, data) {
    await ensureCsrf();
    const res = await fetch(url, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'same-origin',
        body: JSON.stringify(data),
    });
    return res.ok ? res.json() : Promise.reject(await res.text());
}

async function apiDelete(url) {
    await ensureCsrf();
    const res = await fetch(url, { method: 'DELETE', credentials: 'same-origin' });
    return res.ok ? res.json() : Promise.reject(await res.text());
}

function renderCategories(container, items) {
    const rows = (items || []).map(c => `
        <tr>
          <td class="text-slate-700">${c.key}</td>
          <td class="text-slate-900">${c.name}</td>
          <td class="text-slate-700">${c.desc || ''}</td>
          <td>
            <button class="btn" data-key="${c.key}" data-action="edit">编辑</button>
            <button class="btn btn-danger" data-key="${c.key}" data-action="delete">删除</button>
          </td>
        </tr>
    `).join('');

    container.innerHTML = `
      <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th>键</th>
              <th>名称</th>
              <th>描述</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            ${rows}
          </tbody>
        </table>
      </div>
    `;

    container.querySelectorAll('button[data-action="edit"]').forEach(btn => {
        btn.addEventListener('click', async () => {
            const key = btn.getAttribute('data-key');
            const name = prompt('请输入新的名称');
            if (!name) return;
            const desc = prompt('请输入新的描述（可留空）') || '';
            try { await apiPut(`/api/categories/${encodeURIComponent(key)}`, { name, desc }); await loadAndRender(container); }
            catch (e) { alert('编辑失败：' + e); }
        });
    });
    container.querySelectorAll('button[data-action="delete"]').forEach(btn => {
        btn.addEventListener('click', async () => {
            const key = btn.getAttribute('data-key');
            if (!confirm('确认删除该分类？')) return;
            try { await apiDelete(`/api/categories/${encodeURIComponent(key)}`); await loadAndRender(container); }
            catch (e) { alert('删除失败：' + e); }
        });
    });
}

async function loadAndRender(container) {
    try {
        const resp = await apiGet('/api/categories');
        renderCategories(container, resp);
    } catch (e) {
        container.innerHTML = `<div class="rounded-lg border border-red-300 bg-red-100 text-red-700 px-3 py-2">加载失败：${e}</div>`;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const container = document.getElementById('categories-app');
    if (container) {
        loadAndRender(container);
    }
    const createForm = document.getElementById('create-form');
    if (createForm) {
        createForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const form = e.target;
            const payload = {
                key: form.key.value.trim(),
                name: form.name.value.trim(),
                desc: form.desc.value.trim(),
            };
            if (!payload.key || !payload.name) { alert('键与名称必填'); return; }
            try { await apiPost('/api/categories', payload); form.reset(); await loadAndRender(container); }
            catch (e) { alert('新增失败：' + e); }
        });
    }
});
</script>
@endsection