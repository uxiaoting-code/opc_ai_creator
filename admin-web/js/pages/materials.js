/* 素材库后台：加载素材类型、分组、标签和大小 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const esc = global.AdminUtil.escapeHtml;
  const toast = global.AdminUtil.toast;
  let materials = [];

  function typeLabel(type) {
    return type === 'VIDEO' ? '视频' : type === 'AUDIO' ? '音频' : '图片';
  }

  function formatBytes(value) {
    const size = Number(value);
    if (!Number.isFinite(size) || size <= 0) return '—';
    if (size < 1024) return size + ' B';
    if (size < 1024 * 1024) return (size / 1024).toFixed(1) + ' KB';
    return (size / 1024 / 1024).toFixed(1) + ' MB';
  }

  function render(keyword) {
    const tbody = $('#pg-materials tbody');
    if (!tbody) return;
    const text = String(keyword || '').trim().toLowerCase();
    const rows = materials.filter((item) => {
      if (!text) return true;
      return [item.name, item.groupName, item.tags, item.type]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(text));
    });
    if (!rows.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">暂无素材</td></tr>';
      return;
    }
    tbody.innerHTML = rows
      .map(
        (item) => `
          <tr>
            <td><strong>${esc(item.name || '-')}</strong><em>${esc(item.id ? '素材 #' + item.id : '')}</em></td>
            <td>${esc(typeLabel(item.type))}</td>
            <td>${esc(item.groupName || '未分组')}</td>
            <td>${esc(item.tags || '—')}</td>
            <td>${esc(formatBytes(item.fileSize))}</td>
            <td>${esc(global.AdminUtil.formatDateTime(item.createdAt))}</td>
          </tr>`,
      )
      .join('');
  }

  async function load() {
    try {
      const data = await global.AdminApi.get('/materials', {
        mockKey: 'materials',
      });
      materials = Array.isArray(data) ? data : (data && data.list) || [];
      const input = $('#pg-materials .tb-search input');
      render(input ? input.value : '');
    } catch (error) {
      toast((error && error.message) || '素材数据加载失败', 'err');
    }
  }

  function init() {
    const input = $('#pg-materials .tb-search input');
    if (input) {
      input.addEventListener(
        'input',
        global.AdminUtil.debounce(() => render(input.value), 180),
      );
    }
  }

  global.AdminPages.materials = { init, load };
})(window);
