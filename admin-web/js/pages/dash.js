/* 数据概览：先用 mock 填四张卡，接口接入后换 mockKey 即可 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;

  async function load() {
    try {
      const data = await global.AdminApi.get('/dashboard/overview', {
        mockKey: 'overview',
      });
      if (!data) return;
      const set = (id, value) => {
        const el = $('#' + id);
        if (el) el.textContent = value;
      };
      set('dash-total-users', Number(data.totalUsers || 0).toLocaleString('zh-CN'));
      set('dash-active-users', Number(data.activeUsersToday || 0).toLocaleString('zh-CN'));
      set('dash-revenue', '¥ ' + Number(data.revenueToday || 0).toLocaleString('zh-CN', { maximumFractionDigits: 2 }));
      set('dash-credits', global.AdminUtil.formatCredits(data.creditsUsedToday));
    } catch (error) {
      // api.js 已经弹过错误提示，这里保持静态数据即可
    }
  }

  global.AdminPages.dash = { load };
})(window);
