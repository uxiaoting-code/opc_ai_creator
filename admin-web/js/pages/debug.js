/* 调试面板：加载调试会话并按搜索词过滤 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const esc = global.AdminUtil.escapeHtml;
  const toast = global.AdminUtil.toast;
  let sessions = [];

  function statusBadge(status) {
    if (status === 'SUCCESS') return '<span class="bdg teal">成功</span>';
    if (status === 'FAILED') return '<span class="bdg red">失败</span>';
    return '<span class="bdg gold">运行中</span>';
  }

  function render(keyword) {
    const tbody = $('#pg-debug tbody');
    if (!tbody) return;
    const text = String(keyword || '').trim().toLowerCase();
    const rows = sessions.filter((item) => {
      if (!text) return true;
      return [item.sessionId, item.agentName, item.status]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(text));
    });

    if (!rows.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">暂无调试会话</td></tr>';
      return;
    }
    tbody.innerHTML = rows
      .map(
        (item) => `
          <tr>
            <td><strong>${esc(item.sessionId || '-')}</strong></td>
            <td>${esc(item.agentName || '-')}</td>
            <td>${statusBadge(item.status)}</td>
            <td>${(Number(item.elapsedMs) / 1000).toFixed(1)}s</td>
            <td>${esc(item.credits == null ? '-' : item.credits)}</td>
            <td>${esc(global.AdminUtil.formatDateTime(item.createdAt))}</td>
          </tr>`,
      )
      .join('');
  }

  async function load() {
    try {
      const data = await global.AdminApi.get('/debug/logs', {
        mockKey: 'debug',
      });
      sessions = Array.isArray(data) ? data : (data && data.list) || [];
      const input = $('#pg-debug .tb-search input');
      render(input ? input.value : '');
    } catch (error) {
      toast((error && error.message) || '调试数据加载失败', 'err');
    }
  }

  function init() {
    const input = $('#pg-debug .tb-search input');
    if (input) {
      input.addEventListener(
        'input',
        global.AdminUtil.debounce(() => render(input.value), 180),
      );
    }
  }

  global.AdminPages.debug = { init, load };
})(window);
