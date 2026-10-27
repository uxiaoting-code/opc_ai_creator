/* 系统设置：平台参数、全局公告与运行控制开关 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const $$ = global.AdminUtil.$$;
  const toast = global.AdminUtil.toast;

  const saveButtons = [
    '#btn-save-platform-settings',
    '#btn-save-settings',
  ];
  let saving = false;

  function switches() {
    return $$('#pg-settings .sw-row .sw[data-setting]');
  }

  function setSwitch(name, enabled) {
    const button = $('#pg-settings .sw[data-setting="' + name + '"]');
    if (!button) return;
    button.classList.toggle('on', !!enabled);
    button.setAttribute('aria-pressed', enabled ? 'true' : 'false');
  }

  function setValue(id, value) {
    const input = $('#' + id);
    if (input && value != null) input.value = value;
  }

  function applySettings(data) {
    setValue('set-platform-name', data.platformName);
    setValue('set-signup-bonus', data.signupBonusCredits);
    setValue('set-generation-cost', data.generationCostCredits);
    setValue('set-recharge-bonus', data.rechargeBonusPercent);
    setValue('set-credit-price', data.creditPrice);
    setValue('set-announcement', data.announcement);
    setSwitch('announcementEnabled', data.announcementEnabled);
    setSwitch('signupEnabled', data.signupEnabled);
    setSwitch('aiDebugLogEnabled', data.aiDebugLogEnabled);
    setSwitch('maintenanceMode', data.maintenanceMode);
  }

  async function load() {
    try {
      const data = await global.AdminApi.get('/settings', {
        mockKey: 'settings',
      });
      if (data) applySettings(data);
    } catch (error) {
      // api.js 已统一提示
    }
  }

  function numberValue(id, label, options) {
    const raw = ($('#' + id).value || '').trim();
    const value = Number(raw);
    if (raw === '' || !Number.isFinite(value)) {
      throw new Error('请输入有效的' + label);
    }
    if (options.integer && !Number.isInteger(value)) {
      throw new Error(label + '必须是整数');
    }
    if (value < options.min || value > options.max) {
      throw new Error(
        label + '必须在 ' + options.min + '-' + options.max + ' 之间',
      );
    }
    return value;
  }

  function readForm() {
    const platformName = ($('#set-platform-name').value || '').trim();
    if (!platformName) throw new Error('请输入平台名称');
    if (platformName.length > 100) {
      throw new Error('平台名称不能超过 100 个字符');
    }
    const announcement = ($('#set-announcement').value || '').trim();
    if (announcement.length > 2000) {
      throw new Error('公告内容不能超过 2000 个字符');
    }

    const switchValue = (name) => {
      const button = $('#pg-settings .sw[data-setting="' + name + '"]');
      return !!(button && button.classList.contains('on'));
    };

    return {
      platformName,
      signupBonusCredits: numberValue('set-signup-bonus', '赠送算力', {
        min: 0,
        max: 1000000000,
        integer: true,
      }),
      generationCostCredits: numberValue(
        'set-generation-cost',
        '单次生成消耗',
        { min: 1, max: 1000000, integer: true },
      ),
      rechargeBonusPercent: numberValue('set-recharge-bonus', '充值赠送比例', {
        min: 0,
        max: 100,
      }),
      creditPrice: numberValue('set-credit-price', '算力单价', {
        min: 0,
        max: 1000000,
      }),
      announcement,
      announcementEnabled: switchValue('announcementEnabled'),
      signupEnabled: switchValue('signupEnabled'),
      aiDebugLogEnabled: switchValue('aiDebugLogEnabled'),
      maintenanceMode: switchValue('maintenanceMode'),
    };
  }

  function setSaving(active) {
    saving = active;
    saveButtons.forEach((selector) => {
      const button = $(selector);
      if (!button) return;
      if (!button.dataset.label) button.dataset.label = button.textContent;
      button.disabled = active;
      button.textContent = active ? '保存中…' : button.dataset.label;
    });
  }

  async function save() {
    if (saving) return;
    let payload;
    try {
      payload = readForm();
    } catch (error) {
      toast(error.message, 'err');
      return;
    }

    setSaving(true);
    try {
      let saved = await global.AdminApi.put('/settings', payload, {
        mockKey: 'settings',
      });
      if (global.AdminApi.USE_MOCK) {
        saved = Object.assign(saved || {}, payload);
      }
      if (saved) applySettings(saved);
      toast('系统设置已保存并生效', 'ok');
    } catch (error) {
      // api.js 已统一提示
    } finally {
      setSaving(false);
    }
  }

  function init() {
    switches().forEach((button) => {
      button.addEventListener('click', () => {
        const enabled = !button.classList.contains('on');
        button.classList.toggle('on', enabled);
        button.setAttribute('aria-pressed', enabled ? 'true' : 'false');
      });
    });

    saveButtons.forEach((selector) => {
      const button = $(selector);
      if (button) button.addEventListener('click', save);
    });
  }

  global.AdminPages.settings = { init, load };
})(window);
