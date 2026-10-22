/* API 网关：加载对外接口、鉴权、限流与调用量 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const esc = global.AdminUtil.escapeHtml;
  const toast = global.AdminUtil.toast;
  let endpoints = [];

  function render(keyword) {
    const tbody = $('#pg-gateway tbody');
    if (!tbody) return;
    const text = String(keyword || '').trim().toLowerCase();
    const rows = endpoints.filter((item) => {
      if (!text) return true;
      return [item.name, item.path, item.method]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(text));
    });
    if (!rows.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">暂无对外接口</td></tr>';
      return;
    }
    tbody.innerHTML = rows
      .map(
        (item) => `
          <tr>
            <td><strong>${esc(item.name || '-')}</strong><em>${esc(item.callCount || 0)} 次调用</em></td>
            <td><span class="bdg gold">${esc(item.method || 'POST')}</span></td>
            <td><code>${esc(item.path || '-')}</code></td>
            <td>${esc(item.agentId == null ? '—' : 'Agent #' + item.agentId)}</td>
            <td>${item.authRequired ? 'API Key' : '公开'}<em>${item.rateLimit ? item.rateLimit + ' 次/分' : '不限流'}</em></td>
            <td>${item.online ? '<span class="bdg teal">在线</span>' : '<span class="bdg gold">草稿</span>'}</td>
          </tr>`,
      )
      .join('');
  }

  async function load() {
    try {
      const data = await global.AdminApi.get('/gateway/endpoints', {
        mockKey: 'gateway',
      });
      endpoints = Array.isArray(data) ? data : (data && data.list) || [];
      const input = $('#pg-gateway .tb-search input');
      render(input ? input.value : '');
    } catch (error) {
      toast((error && error.message) || '网关数据加载失败', 'err');
    }
  }

  function init() {
    const input = $('#pg-gateway .tb-search input');
    if (input) {
      input.addEventListener(
        'input',
        global.AdminUtil.debounce(() => render(input.value), 180),
      );
    }
  }

  global.AdminPages.gateway = { init, load };
})(window);
