/* 算力使用：先用 mock 填顶部统计 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;

  async function load() {
    try {
      const data = await global.AdminApi.get('/credits/stats', {
        mockKey: 'usage',
      });
      const stats = (data && data.stats) || data || {};
      const set = (id, value) => {
        const el = $('#' + id);
        if (el) el.textContent = value;
      };
      set('usage-today', global.AdminUtil.formatCredits(stats.todayUsed));
      set('usage-yesterday', global.AdminUtil.formatCredits(stats.yesterdayUsed));
      set('usage-month', global.AdminUtil.formatCredits(stats.monthUsed));
      set('usage-stock', global.AdminUtil.formatCredits(stats.platformStock));
    } catch (error) {
      // 保留静态展示
    }
  }

  global.AdminPages.usage = { load };
})(window);
