/* 知识库：加载文档、分段、绑定智能体和更新时间 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const esc = global.AdminUtil.escapeHtml;
  const toast = global.AdminUtil.toast;
  let knowledgeBases = [];

  function render(keyword) {
    const tbody = $('#pg-kb tbody');
    if (!tbody) return;
    const text = String(keyword || '').trim().toLowerCase();
    const rows = knowledgeBases.filter((item) => {
      if (!text) return true;
      return [item.name, item.description]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(text));
    });
    if (!rows.length) {
      tbody.innerHTML = '<tr><td colspan="5" class="empty-cell">暂无知识库</td></tr>';
      return;
    }
    tbody.innerHTML = rows
      .map(
        (item) => `
          <tr>
            <td><strong>${esc(item.name || '-')}</strong><em>${esc(item.description || '')}</em></td>
            <td>${esc(item.documentCount || 0)}</td>
            <td>${esc(item.chunkCount || 0)}</td>
            <td>${esc(item.boundAgentCount || 0)}</td>
            <td>${esc(global.AdminUtil.formatDateTime(item.updatedAt))}</td>
          </tr>`,
      )
      .join('');
  }

  async function load() {
    try {
      const data = await global.AdminApi.get('/kbs', {
        mockKey: 'kb',
      });
      knowledgeBases = Array.isArray(data) ? data : (data && data.list) || [];
      const input = $('#pg-kb .tb-search input');
      render(input ? input.value : '');
    } catch (error) {
      toast((error && error.message) || '知识库数据加载失败', 'err');
    }
  }

  function init() {
    const input = $('#pg-kb .tb-search input');
    if (input) {
      input.addEventListener(
        'input',
        global.AdminUtil.debounce(() => render(input.value), 180),
      );
    }
  }

  global.AdminPages.kb = { init, load };
})(window);
