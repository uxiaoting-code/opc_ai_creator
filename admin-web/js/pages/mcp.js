/* MCP 接入：加载 Server 列表、能力数量与连接状态 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const esc = global.AdminUtil.escapeHtml;
  const toast = global.AdminUtil.toast;
  let servers = [];

  function render(keyword) {
    const tbody = $('#pg-mcp tbody');
    if (!tbody) return;
    const text = String(keyword || '').trim().toLowerCase();
    const rows = servers.filter((item) => {
      if (!text) return true;
      return [item.name, item.transport, item.status]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(text));
    });
    if (!rows.length) {
      tbody.innerHTML = '<tr><td colspan="5" class="empty-cell">暂无 MCP Server</td></tr>';
      return;
    }
    tbody.innerHTML = rows
      .map((item) => {
        const badge =
          item.status === 'CONNECTED'
            ? '<span class="bdg teal">已连接</span>'
            : '<span class="bdg gold">待发现</span>';
        return `
          <tr>
            <td><strong>${esc(item.name || '-')}</strong><em>MCP Server</em></td>
            <td>${esc(item.transport || '-')}</td>
            <td>${esc(item.enabledToolCount || 0)} / ${esc(item.toolCount || 0)}</td>
            <td>${badge}</td>
            <td>${esc(item.lastDiscoverAt ? global.AdminUtil.formatDateTime(item.lastDiscoverAt) : '—')}</td>
          </tr>`;
      })
      .join('');
  }

  async function load() {
    try {
      const data = await global.AdminApi.get('/mcp/servers', {
        mockKey: 'mcp',
      });
      servers = Array.isArray(data) ? data : (data && data.list) || [];
      const input = $('#pg-mcp .tb-search input');
      render(input ? input.value : '');
    } catch (error) {
      toast((error && error.message) || 'MCP 数据加载失败', 'err');
    }
  }

  function init() {
    const input = $('#pg-mcp .tb-search input');
    if (input) {
      input.addEventListener(
        'input',
        global.AdminUtil.debounce(() => render(input.value), 180),
      );
    }
  }

  global.AdminPages.mcp = { init, load };
})(window);
