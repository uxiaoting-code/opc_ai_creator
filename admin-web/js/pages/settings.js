/* 系统设置：平台参数 + 公告 + 3 个开关 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const $$ = global.AdminUtil.$$;
  const toast = global.AdminUtil.toast;

  function switches() {
    return $$('#pg-settings .sw-row .sw');
  }

  function setSwitch(index, enabled) {
    const item = switches()[index];
    if (item) item.classList.toggle('on', !!enabled);
  }

  async function load() {
    try {
      const data = await global.AdminApi.get('/settings', {
        mockKey: 'settings',
      });
      if (!data) return;
      const set = (id, value) => {
        const el = $('#' + id);
        if (el && value != null) el.value = value;
      };
      set('set-platform-name', data.platformName);
      set('set-signup-bonus', data.signupBonusCredits);
      set('set-recharge-bonus', data.rechargeBonusPercent);
      set('set-credit-price', data.creditPrice);
      set('set-announcement', data.announcement);
      setSwitch(0, data.signupEnabled);
      setSwitch(1, data.rechargeEnabled);
      setSwitch(2, data.maintenanceMode);
    } catch (error) {
      // api.js 已提示
    }
  }

  function init() {
    switches().forEach((button) => {
      button.addEventListener('click', () => {
        button.classList.toggle('on');
        const label = button.closest('.sw-row').querySelector('span').textContent;
        toast(
          label + (button.classList.contains('on') ? '：已开启' : '：已关闭'),
          button.classList.contains('on') ? 'ok' : 'warn',
        );
      });
    });

    $$('#pg-settings .panel .btn.teal').forEach((button) => {
      button.addEventListener('click', () => {
        const text = button.textContent.trim();
        if (text.includes('保存')) toast('平台参数已保存并生效', 'ok');
        else if (text.includes('公告')) toast('系统公告已发布，前台将弹窗展示', 'ok');
      });
    });
  }

  global.AdminPages.settings = { init, load };
})(window);
