/* 大模型配置：真实 /api/admin/providers 数据、完整配置表单与连通性测试 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const $$ = global.AdminUtil.$$;
  const toast = global.AdminUtil.toast;
  const escape = global.AdminUtil.escapeHtml;
  const debounce = global.AdminUtil.debounce;

  // 本页固定使用真实后端；其他尚未完成的后台页面仍遵守 api.js 的全局 Mock 开关。
  const USE_MOCK = false;

  const typeMeta = {
    CHAT: { label: '聊天', badge: 'teal' },
    IMAGE: { label: '图片', badge: 'purple' },
    VIDEO: { label: '视频', badge: 'pink' },
    AUDIO: { label: '音频', badge: 'gold' },
  };

  const implMeta = {
    mock: 'Mock 演示',
    http: 'HTTP 模板',
    'stable-diffusion': 'Stable Diffusion',
  };

  const priceUnitMeta = {
    TOKEN: '百万 token',
    SECOND: '秒',
    CALL: '次',
  };

  const state = {
    initialized: false,
    loading: false,
    page: 1,
    pageSize: 10,
    total: 0,
    keyword: '',
    type: '',
    items: [],
    editingId: null,
    activeTab: 'basic',
    testingIds: new Set(),
    mockSessionWarned: false,
  };

  function requestOptions() {
    return USE_MOCK
      ? { mockKey: 'models' }
      : { silent: true };
  }

  function numberText(value, maxDigits) {
    if (value === null || value === undefined || value === '') return '—';
    const number = Number(value);
    if (!Number.isFinite(number)) return '—';
    const fixed = number.toFixed(maxDigits === undefined ? 4 : maxDigits);
    return fixed.replace(/\.?0+$/, '');
  }

  function inputValue(value) {
    return value === null || value === undefined ? '' : String(value);
  }

  function renderLoading() {
    const body = $('#model-table tbody');
    if (body) {
      body.innerHTML =
        '<tr><td colspan="9" class="empty-cell">正在加载模型配置…</td></tr>';
    }
    const count = $('#model-count');
    if (count) count.textContent = '正在加载…';
  }

  function renderEmpty(message) {
    const body = $('#model-table tbody');
    if (!body) return;
    body.innerHTML =
      '<tr><td colspan="9" class="empty-cell">' +
      escape(message || '暂无模型配置') +
      '</td></tr>';
  }

  function renderModels(rows) {
    const table = $('#model-table');
    if (!table || !Array.isArray(rows)) return;
    if (!rows.length) {
      renderEmpty('当前筛选条件下暂无模型配置');
      return;
    }
    const body = $('tbody', table);
    body.innerHTML = rows.map(renderRow).join('');
  }

  function renderRow(model) {
    const type = typeMeta[model.type] || {
      label: model.typeLabel || model.type || '其他',
      badge: 'teal',
    };
    const successRate =
      model.successRate === null || model.successRate === undefined
        ? '—'
        : numberText(model.successRate, 1) + '%';
    const rateClass =
      model.successRate === null || model.successRate === undefined
        ? ''
        : Number(model.successRate) >= 95
          ? ' green'
          : ' gold';
    const testing = state.testingIds.has(Number(model.id));
    const unit = priceUnitMeta[model.priceUnit] || model.priceUnitLabel || '';
    return (
      '<tr data-provider-id="' +
      escape(model.id) +
      '">' +
      '<td><strong>' +
      escape(model.name || '未命名模型') +
      '</strong><em>' +
      escape(model.vendor || '自定义接入') +
      ' · ' +
      escape(implMeta[model.providerImpl] || model.providerImpl || '未配置实现') +
      (model.modelName ? ' · ' + escape(model.modelName) : '') +
      '</em></td>' +
      '<td><span class="bdg ' +
      type.badge +
      '">' +
      escape(type.label) +
      '</span></td>' +
      '<td>' +
      escape(model.channel || '—') +
      '</td>' +
      '<td>' +
      escape(numberText(model.inputPrice)) +
      (unit ? '<em class="price-unit"> / ' + escape(unit) + '</em>' : '') +
      '</td>' +
      '<td>' +
      escape(numberText(model.outputPrice)) +
      (unit ? '<em class="price-unit"> / ' + escape(unit) + '</em>' : '') +
      '</td>' +
      '<td>' +
      Number(model.todayCalls || 0).toLocaleString('zh-CN') +
      '</td>' +
      '<td><b class="num' +
      rateClass +
      '">' +
      escape(successRate) +
      '</b></td>' +
      '<td><button class="sw' +
      (model.online ? ' on' : '') +
      '" type="button" data-model-action="toggle" data-id="' +
      escape(model.id) +
      '" aria-label="' +
      (model.online ? '下架' : '上架') +
      '"></button></td>' +
      '<td class="ops">' +
      '<button class="op test" type="button" data-model-action="test" data-id="' +
      escape(model.id) +
      '"' +
      (testing ? ' disabled' : '') +
      '>' +
      (testing ? '测试中…' : '测试') +
      '</button>' +
      '<button class="op edit" type="button" data-model-action="edit" data-id="' +
      escape(model.id) +
      '">编辑</button>' +
      '<button class="op danger" type="button" data-model-action="delete" data-id="' +
      escape(model.id) +
      '">删除</button>' +
      '</td></tr>'
    );
  }

  function renderPagination() {
    const count = $('#model-count');
    if (count) count.textContent = '共 ' + state.total + ' 条';
    const root = $('#model-pager');
    if (!root) return;
    const pages = Math.max(1, Math.ceil(state.total / state.pageSize));
    const current = Math.min(state.page, pages);
    const pageSet = new Set([
      1,
      pages,
      current - 2,
      current - 1,
      current,
      current + 1,
      current + 2,
    ]);
    const sorted = Array.from(pageSet)
      .filter((page) => page >= 1 && page <= pages)
      .sort((a, b) => a - b);
    let last = 0;
    const buttons = [
      '<button type="button" data-model-page="' +
        (current - 1) +
        '"' +
        (current <= 1 ? ' disabled' : '') +
        '>«</button>',
    ];
    sorted.forEach((page) => {
      if (last && page - last > 1) buttons.push('<button disabled>…</button>');
      buttons.push(
        '<button type="button" data-model-page="' +
          page +
          '" class="' +
          (page === current ? 'on' : '') +
          '">' +
          page +
          '</button>',
      );
      last = page;
    });
    buttons.push(
      '<button type="button" data-model-page="' +
        (current + 1) +
        '"' +
        (current >= pages ? ' disabled' : '') +
        '>»</button>',
    );
    root.innerHTML = buttons.join('');
  }

  function buildQuery() {
    const params = new URLSearchParams();
    params.set('page', state.page);
    params.set('pageSize', state.pageSize);
    if (state.keyword) params.set('keyword', state.keyword);
    if (state.type) params.set('type', state.type);
    return '/providers?' + params.toString();
  }

  async function load() {
    if (
      global.AdminApi.USE_MOCK &&
      global.AdminApi.getToken() === 'mock-admin-token'
    ) {
      renderEmpty(
        '本页固定连接真实后端。请退出后使用 ?mock=0 重新登录管理员账号（admin / admin123）。',
      );
      state.total = 0;
      renderPagination();
      if (!state.mockSessionWarned) {
        state.mockSessionWarned = true;
        toast('大模型配置已切换真实接口，请先真实登录', 'warn');
      }
      return;
    }
    state.loading = true;
    renderLoading();
    try {
      const data = await global.AdminApi.get(
        buildQuery(),
        requestOptions(),
      );
      state.items = (data && data.list) || [];
      state.total = (data && data.total) || 0;
      const pages = Math.max(1, Math.ceil(state.total / state.pageSize));
      if (state.page > pages) {
        state.page = pages;
        state.loading = false;
        return load();
      }
      renderModels(state.items);
    } catch (error) {
      state.items = [];
      state.total = 0;
      renderEmpty(
        '模型配置加载失败：' +
          ((error && error.message) || '请确认后端和登录状态'),
      );
    } finally {
      state.loading = false;
    }
    renderPagination();
  }

  function activateTab(name) {
    state.activeTab = name;
    $$('#model-tabs [data-model-tab]').forEach((button) => {
      button.classList.toggle('on', button.dataset.modelTab === name);
    });
    $$('[data-model-pane]').forEach((pane) => {
      pane.classList.toggle('hidden', pane.dataset.modelPane !== name);
    });
  }

  function syncAuthFields() {
    const type = $('#md-auth-type').value || 'NONE';
    $$('[data-auth-for]').forEach((group) => {
      group.classList.toggle('hidden', group.dataset.authFor !== type);
    });
  }

  function setValue(selector, value) {
    const element = $(selector);
    if (element) element.value = inputValue(value);
  }

  function resetEditor() {
    setValue('#md-name', '');
    setValue('#md-vendor', '');
    setValue('#md-type', 'IMAGE');
    setValue('#md-impl', 'mock');
    setValue('#md-ch', '');
    setValue('#md-model-name', '');
    setValue('#md-base-url', '');
    setValue('#md-in', '');
    setValue('#md-out', '');
    setValue('#md-price-unit', 'TOKEN');
    setValue('#md-timeout', '180');
    setValue('#md-sort', '0');
    setValue('#md-remark', '');

    setValue('#md-auth-type', 'NONE');
    setValue('#md-api-key', '');
    setValue('#md-header-name', '');
    setValue('#md-header-value', '');
    setValue('#md-oauth-token-url', '');
    setValue('#md-oauth-client-id', '');
    setValue('#md-oauth-client-secret', '');
    syncAuthFields();

    setValue('#md-req-method', 'POST');
    setValue('#md-req-path', '');
    setValue('#md-req-content-type', 'application/json');
    setValue('#md-req-query', '');
    setValue('#md-req-headers', '');
    setValue('#md-req-body', '{"model":"{{modelName}}","prompt":"{{prompt}}"}');

    setValue('#md-res-success', '');
    setValue('#md-res-url', '');
    setValue('#md-res-thumb', '');
    setValue('#md-res-error', '');
    setValue('#md-res-task', '');
  }

  function fillEditor(detail) {
    setValue('#md-name', detail.name);
    setValue('#md-vendor', detail.vendor);
    setValue('#md-type', detail.type || 'IMAGE');
    setValue('#md-impl', detail.providerImpl || 'mock');
    setValue('#md-ch', detail.channel);
    setValue('#md-model-name', detail.modelName);
    setValue('#md-base-url', detail.baseUrl);
    setValue('#md-in', detail.inputPrice);
    setValue('#md-out', detail.outputPrice);
    setValue('#md-price-unit', detail.priceUnit || 'TOKEN');
    setValue('#md-timeout', detail.timeoutSeconds || 180);
    setValue('#md-sort', detail.sortOrder || 0);
    setValue('#md-remark', detail.remark);

    setValue('#md-auth-type', detail.authType || 'NONE');
    setValue('#md-api-key', detail.apiKeyMasked);
    setValue('#md-header-name', detail.headerName);
    setValue('#md-header-value', detail.headerValue);
    setValue('#md-oauth-token-url', detail.oauthTokenUrl);
    setValue('#md-oauth-client-id', detail.oauthClientId);
    setValue('#md-oauth-client-secret', '');
    syncAuthFields();

    setValue('#md-req-method', detail.requestMethod || 'POST');
    setValue('#md-req-path', detail.requestPath);
    setValue(
      '#md-req-content-type',
      detail.requestContentType || 'application/json',
    );
    setValue('#md-req-query', detail.requestQueryJson);
    setValue('#md-req-headers', detail.requestHeadersJson);
    setValue('#md-req-body', detail.requestBodyJson);

    setValue('#md-res-success', detail.responseSuccessPath);
    setValue('#md-res-url', detail.responseResultUrlPath);
    setValue('#md-res-thumb', detail.responseThumbPath);
    setValue('#md-res-error', detail.responseErrorPath);
    setValue('#md-res-task', detail.responseTaskIdPath);
  }

  async function openEditor(id) {
    resetEditor();
    state.editingId = id ? Number(id) : null;
    const title = $('#model-dialog-title');
    const subtitle = $('#model-dialog-subtitle');
    if (title) title.textContent = id ? '编辑模型配置' : '接入新模型';
    if (subtitle) {
      subtitle.textContent = id
        ? '修改后会同步保存基础信息、鉴权和请求/响应模板'
        : '新增配置后默认不上架，可在列表中单独上架';
    }
    const testButton = $('#md-test');
    if (testButton) {
      testButton.classList.toggle('hidden', !id);
      testButton.disabled = false;
      testButton.textContent = '连通性测试';
    }
    activateTab('basic');

    if (id) {
      try {
        const detail = await global.AdminApi.get(
          '/providers/' + id,
          { silent: true },
        );
        fillEditor(detail);
      } catch (error) {
        toast((error && error.message) || '模型详情加载失败', 'err');
        return;
      }
    }
    global.AdminApp.openModal('modal-model');
  }

  function parsePrice(selector, label) {
    const value = $(selector).value.trim();
    if (!value) return null;
    const number = Number(value);
    if (!Number.isFinite(number) || number < 0) {
      throw new Error(label + '必须是非负数字');
    }
    return number;
  }

  function collectBase() {
    const name = $('#md-name').value.trim();
    if (!name) throw new Error('请填写模型名称');
    return {
      name: name,
      vendor: $('#md-vendor').value.trim() || null,
      type: $('#md-type').value,
      channel: $('#md-ch').value.trim() || null,
      modelName: $('#md-model-name').value.trim() || null,
      baseUrl: $('#md-base-url').value.trim() || null,
      providerImpl: $('#md-impl').value,
      inputPrice: parsePrice('#md-in', '输入价'),
      outputPrice: parsePrice('#md-out', '输出价'),
      priceUnit: $('#md-price-unit').value,
      timeoutSeconds: Number($('#md-timeout').value || 180),
      sortOrder: Number($('#md-sort').value || 0),
      remark: $('#md-remark').value.trim() || null,
    };
  }

  function collectAuth() {
    return {
      authType: $('#md-auth-type').value || 'NONE',
      apiKey: $('#md-api-key').value.trim() || null,
      headerName: $('#md-header-name').value.trim() || null,
      headerValue: $('#md-header-value').value.trim() || null,
      oauthTokenUrl: $('#md-oauth-token-url').value.trim() || null,
      oauthClientId: $('#md-oauth-client-id').value.trim() || null,
      oauthClientSecret:
        $('#md-oauth-client-secret').value.trim() || null,
    };
  }

  function validateJsonField(selector, label) {
    const element = $(selector);
    const value = element.value.trim();
    if (!value) return null;
    try {
      JSON.parse(value);
      return value;
    } catch (error) {
      element.focus();
      throw new Error(label + '不是合法 JSON');
    }
  }

  function collectRequestTemplate() {
    return {
      method: $('#md-req-method').value,
      path: $('#md-req-path').value.trim() || null,
      contentType:
        $('#md-req-content-type').value.trim() || 'application/json',
      queryJson: validateJsonField('#md-req-query', 'Query JSON'),
      headersJson: validateJsonField('#md-req-headers', 'Headers JSON'),
      bodyJson: validateJsonField('#md-req-body', 'Body JSON'),
    };
  }

  function collectResponseTemplate() {
    return {
      successPath: $('#md-res-success').value.trim() || null,
      resultUrlPath: $('#md-res-url').value.trim() || null,
      thumbPath: $('#md-res-thumb').value.trim() || null,
      errorPath: $('#md-res-error').value.trim() || null,
      taskIdPath: $('#md-res-task').value.trim() || null,
    };
  }

  function setSaveLoading(loading) {
    const button = $('#md-ok');
    if (!button) return;
    button.disabled = loading;
    button.textContent = loading ? '保存中…' : '保存配置';
  }

  async function saveProvider() {
    let base;
    let auth;
    let requestTemplate;
    let responseTemplate;
    try {
      base = collectBase();
      auth = collectAuth();
      requestTemplate = collectRequestTemplate();
      responseTemplate = collectResponseTemplate();
    } catch (error) {
      toast(error.message, 'err');
      return;
    }

    setSaveLoading(true);
    try {
      let id = state.editingId;
      if (id) {
        await global.AdminApi.put('/providers/' + id, base, {
          silent: true,
        });
      } else {
        const created = await global.AdminApi.post('/providers', base, {
          silent: true,
        });
        id = created && created.id;
        if (!id) throw new Error('后端未返回新模型 ID');
        state.editingId = Number(id);
        const testButton = $('#md-test');
        if (testButton) testButton.classList.remove('hidden');
      }

      await global.AdminApi.put('/providers/' + id + '/auth', auth, {
        silent: true,
      });
      await global.AdminApi.put(
        '/providers/' + id + '/request-template',
        requestTemplate,
        { silent: true },
      );
      await global.AdminApi.put(
        '/providers/' + id + '/response-template',
        responseTemplate,
        { silent: true },
      );

      global.AdminApp.closeModal('modal-model');
      toast('模型配置已保存', 'ok');
      state.editingId = null;
      await load();
    } catch (error) {
      toast((error && error.message) || '模型配置保存失败', 'err');
    } finally {
      setSaveLoading(false);
    }
  }

  function setTesting(id, testing) {
    if (testing) state.testingIds.add(Number(id));
    else state.testingIds.delete(Number(id));
    $$('[data-model-action="test"][data-id="' + Number(id) + '"]').forEach(
      (button) => {
        button.disabled = testing;
        button.textContent = testing ? '测试中…' : '测试';
      },
    );
    const modalButton = $('#md-test');
    if (
      modalButton &&
      Number(state.editingId) === Number(id)
    ) {
      modalButton.disabled = testing;
      modalButton.textContent = testing ? '测试中…' : '连通性测试';
    }
  }

  function renderTestLoading() {
    const root = $('#provider-test-content');
    if (!root) return;
    root.innerHTML =
      '<div class="provider-test-loading"><div class="provider-spinner"></div><span>正在请求上游服务，请稍候…</span></div>';
  }

  function renderTestResult(result, error) {
    const root = $('#provider-test-content');
    if (!root) return;
    const success = Boolean(result && result.success);
    const message =
      (result && result.message) ||
      (error && error.message) ||
      (success ? '连通性正常' : '连通性测试失败');
    const httpStatus =
      result && Number(result.httpStatus) > 0 ? result.httpStatus : '—';
    const elapsed =
      result && Number(result.elapsedMs) > 0
        ? result.elapsedMs + ' ms'
        : '—';
    const raw = result && result.rawResponse
      ? escape(result.rawResponse)
      : '';
    const extracted =
      result && result.extractedResultUrl
        ? escape(result.extractedResultUrl)
        : '—';
    const extractedError =
      result && result.extractedError
        ? escape(result.extractedError)
        : '—';
    root.innerHTML =
      '<div class="provider-test-hero ' +
      (success ? 'ok' : 'fail') +
      '"><i>' +
      (success ? '✓' : '!') +
      '</i><div><strong>' +
      (success ? '测试成功' : '测试失败') +
      '</strong><span>' +
      escape(message) +
      '</span></div></div>' +
      '<div class="provider-test-grid">' +
      '<div><em>HTTP 状态</em><b>' +
      escape(httpStatus) +
      '</b></div>' +
      '<div><em>耗时</em><b>' +
      escape(elapsed) +
      '</b></div>' +
      '<div><em>提取错误</em><b>' +
      extractedError +
      '</b></div>' +
      '<div style="grid-column:1/-1"><em>提取结果 URL</em><b>' +
      extracted +
      '</b></div>' +
      '</div>' +
      (raw
        ? '<div class="provider-test-raw"><span>原始响应' +
          (result.rawResponseTruncated ? '（已截断）' : '') +
          '</span><pre>' +
          raw +
          '</pre></div>'
        : '');
  }

  async function testProvider(id) {
    if (!id || state.testingIds.has(Number(id))) return;
    setTesting(id, true);
    renderTestLoading();
    global.AdminApp.openModal('modal-provider-test');
    try {
      const result = await global.AdminApi.post(
        '/providers/' + id + '/test',
        {},
        { silent: true },
      );
      renderTestResult(result, null);
      toast(
        (result && result.message) ||
          (result && result.success ? '连通性正常' : '连通性测试失败'),
        result && result.success ? 'ok' : 'err',
      );
    } catch (error) {
      renderTestResult(null, error);
      toast((error && error.message) || '连通性测试请求失败', 'err');
    } finally {
      setTesting(id, false);
    }
  }

  async function toggleOnline(id) {
    const model = state.items.find((item) => Number(item.id) === Number(id));
    if (!model) return;
    const online = !model.online;
    const button = $(
      '[data-model-action="toggle"][data-id="' + Number(id) + '"]',
    );
    if (button) button.disabled = true;
    try {
      await global.AdminApi.put(
        '/providers/' +
          id +
          '/' +
          (online ? 'online' : 'offline'),
        undefined,
        { silent: true },
      );
      toast(model.name + (online ? ' 已上架' : ' 已下架'), 'ok');
      await load();
    } catch (error) {
      toast((error && error.message) || '上下架操作失败', 'err');
      if (button) button.disabled = false;
    }
  }

  async function deleteProvider(id) {
    const model = state.items.find((item) => Number(item.id) === Number(id));
    if (!model) return;
    if (
      !global.confirm(
        '确定删除「' + model.name + '」的模型配置吗？删除后将从列表移除。',
      )
    ) {
      return;
    }
    try {
      await global.AdminApi.del('/providers/' + id, { silent: true });
      toast('模型配置已删除', 'ok');
      await load();
    } catch (error) {
      toast((error && error.message) || '删除模型配置失败', 'err');
    }
  }

  function reloadFromFirstPage() {
    state.page = 1;
    load();
  }

  function bind() {
    if (state.initialized) return;
    state.initialized = true;

    const search = $('#model-search');
    if (search) {
      search.addEventListener(
        'input',
        debounce(() => {
          state.keyword = search.value.trim();
          reloadFromFirstPage();
        }, 250),
      );
    }
    const type = $('#model-type');
    if (type) {
      type.addEventListener('change', () => {
        state.type = type.value;
        reloadFromFirstPage();
      });
    }
    const refresh = $('#btn-model-refresh');
    if (refresh) refresh.addEventListener('click', load);
    const add = $('#btn-model-add');
    if (add) add.addEventListener('click', () => openEditor(null));

    const table = $('#model-table');
    if (table) {
      table.addEventListener('click', (event) => {
        const button = event.target.closest('[data-model-action]');
        if (!button || button.disabled) return;
        const id = Number(button.dataset.id);
        if (button.dataset.modelAction === 'toggle') toggleOnline(id);
        if (button.dataset.modelAction === 'test') testProvider(id);
        if (button.dataset.modelAction === 'edit') openEditor(id);
        if (button.dataset.modelAction === 'delete') deleteProvider(id);
      });
    }

    const pager = $('#model-pager');
    if (pager) {
      pager.addEventListener('click', (event) => {
        const button = event.target.closest('[data-model-page]');
        if (!button || button.disabled) return;
        state.page = Number(button.dataset.modelPage) || 1;
        load();
      });
    }

    const tabs = $('#model-tabs');
    if (tabs) {
      tabs.addEventListener('click', (event) => {
        const button = event.target.closest('[data-model-tab]');
        if (button) activateTab(button.dataset.modelTab);
      });
    }
    const authType = $('#md-auth-type');
    if (authType) authType.addEventListener('change', syncAuthFields);
    const save = $('#md-ok');
    if (save) save.addEventListener('click', saveProvider);
    const test = $('#md-test');
    if (test) test.addEventListener('click', () => testProvider(state.editingId));
  }

  function init() {
    bind();
    syncAuthFields();
  }

  global.AdminPages.models = {
    init,
    load,
    USE_MOCK,
    state,
  };
})(window);
