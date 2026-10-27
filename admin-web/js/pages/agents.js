/* 智能体工作台：真实接口的列表、新建、详情、工具编排、保存与预览 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const $$ = global.AdminUtil.$$;
  const toast = global.AdminUtil.toast;
  const escape = global.AdminUtil.escapeHtml;
  const debounce = global.AdminUtil.debounce;

  // 本页固定连接真实后端，页面请求全部经过 AdminApi（js/api.js）。
  const USE_MOCK = false;

  const CATEGORY_META = {
    CUSTOMER_SERVICE: { label: '客服', badge: 'blue' },
    MARKETING: { label: '营销', badge: 'teal' },
    DESIGN: { label: '设计', badge: 'pink' },
    DATA_ANALYSIS: { label: '数据分析', badge: 'purple' },
    OTHER: { label: '其他', badge: 'gold' },
  };

  const STATUS_META = {
    DRAFT: { label: '草稿', badge: 'gold' },
    PUBLISHED: { label: '已发布', badge: 'teal' },
    OFFLINE: { label: '已下线', badge: 'red' },
  };

  const SOURCE_META = {
    MODEL: { label: '模型', badge: 'purple', icon: '🧠' },
    KNOWLEDGE: { label: '知识库', badge: 'blue', icon: '📚' },
    MCP: { label: 'MCP', badge: 'gold', icon: '🔌' },
    BUILTIN: { label: '内置', badge: 'teal', icon: '🧩' },
  };

  const state = {
    initialized: false,
    listLoading: false,
    listSeq: 0,
    page: 1,
    pageSize: 10,
    total: 0,
    keyword: '',
    category: '',
    status: '',
    items: [],
    detail: null,
    activeAgentId: null,
    detailLoading: false,
    dirty: false,
    saving: false,
    tools: [],
    toolsLoaded: false,
    toolsLoading: null,
    toolsError: '',
    nodeEditingIndex: -1,
  };

  function realOptions() {
    return { silent: true };
  }

  function inputValue(value) {
    return value === null || value === undefined ? '' : String(value);
  }

  function trimToNull(value) {
    const text = String(value === null || value === undefined ? '' : value).trim();
    return text || null;
  }

  function numberText(value, digits) {
    if (value === null || value === undefined || value === '') return '—';
    const number = Number(value);
    if (!Number.isFinite(number)) return '—';
    const fixed = number.toFixed(digits === undefined ? 1 : digits);
    return fixed.includes('.') ? fixed.replace(/\.?0+$/, '') : fixed;
  }

  function elapsedText(value) {
    if (value === null || value === undefined || value === '') return '—';
    const number = Number(value);
    if (!Number.isFinite(number)) return '—';
    return number >= 1000
      ? numberText(number / 1000, 1) + 's'
      : numberText(number, 0) + 'ms';
  }

  function categoryMeta(value, label) {
    return CATEGORY_META[value] || {
      label: label || value || '其他',
      badge: 'gold',
    };
  }

  function statusMeta(value, label) {
    return STATUS_META[value] || {
      label: label || value || '未知',
      badge: 'gold',
    };
  }

  function sourceMeta(value, label) {
    return SOURCE_META[value] || {
      label: label || value || '工具',
      badge: 'teal',
      icon: '🧩',
    };
  }

  function toolIdentity(tool) {
    return [
      tool.toolSource || '',
      tool.toolRefId === null || tool.toolRefId === undefined
        ? ''
        : tool.toolRefId,
      tool.toolKey || '',
    ].join('|');
  }

  function setText(selector, value) {
    const element = $(selector);
    if (element) element.textContent = inputValue(value);
  }

  function setValue(selector, value) {
    const element = $(selector);
    if (element) element.value = inputValue(value);
  }

  function markDirty(dirty) {
    state.dirty = dirty !== false;
    const badge = $('#agent-dirty');
    if (badge) badge.classList.toggle('hidden', !state.dirty);
  }

  function setButtonLoading(selector, loading, idleText, loadingText) {
    const button = $(selector);
    if (!button) return;
    button.disabled = loading;
    button.textContent = loading ? loadingText : idleText;
  }

  // -------------------------------------------------------------------------
  // 第一层：列表
  // -------------------------------------------------------------------------

  function listQuery() {
    const params = new URLSearchParams();
    params.set('page', state.page);
    params.set('pageSize', state.pageSize);
    if (state.keyword) params.set('keyword', state.keyword);
    if (state.category) params.set('category', state.category);
    if (state.status) params.set('status', state.status);
    return '/agents?' + params.toString();
  }

  function renderListLoading() {
    const body = $('#agent-table tbody');
    if (body) {
      body.innerHTML =
        '<tr><td colspan="9" class="empty-cell">正在加载智能体…</td></tr>';
    }
    setText('#agent-count', '正在加载…');
  }

  function renderListEmpty(message) {
    const body = $('#agent-table tbody');
    if (body) {
      body.innerHTML =
        '<tr><td colspan="9" class="empty-cell">' +
        escape(message || '暂无智能体') +
        '</td></tr>';
    }
  }

  function renderAgentRow(agent) {
    const category = categoryMeta(agent.category, agent.categoryLabel);
    const status = statusMeta(agent.status, agent.statusLabel);
    const rate =
      agent.successRate === null || agent.successRate === undefined
        ? '—'
        : numberText(agent.successRate, 1) + '%';
    const rateClass =
      agent.successRate === null || agent.successRate === undefined
        ? ''
        : Number(agent.successRate) >= 95
          ? ' green'
          : ' gold';
    const statusAction =
      agent.status === 'PUBLISHED'
        ? '<button class="op freeze" type="button" data-agent-action="offline" data-id="' +
          escape(agent.id) +
          '">下线</button>'
        : '<button class="op freeze" type="button" data-agent-action="publish" data-id="' +
          escape(agent.id) +
          '">发布</button>';

    return (
      '<tr data-agent-id="' +
      escape(agent.id) +
      '">' +
      '<td><div class="agent-name-cell"><span>' +
      escape(agent.icon || '🤖') +
      '</span><div><strong>' +
      escape(agent.name || '未命名智能体') +
      '</strong><em>' +
      escape(agent.code || '—') +
      '</em></div></div></td>' +
      '<td><span class="bdg ' +
      category.badge +
      '">' +
      escape(category.label) +
      '</span></td>' +
      '<td>' +
      Number(agent.modelCount || 0) +
      '</td>' +
      '<td>' +
      Number(agent.enabledSkillCount || 0) +
      ' / ' +
      Number(agent.skillCount || 0) +
      '</td>' +
      '<td>' +
      Number(agent.todayCalls || 0).toLocaleString('zh-CN') +
      '</td>' +
      '<td>' +
      escape(elapsedText(agent.avgElapsedMs)) +
      '</td>' +
      '<td><b class="num' +
      rateClass +
      '">' +
      escape(rate) +
      '</b></td>' +
      '<td><span class="bdg ' +
      status.badge +
      '">' +
      escape(status.label) +
      '</span></td>' +
      '<td class="ops">' +
      '<button class="op edit" type="button" data-agent-action="config" data-id="' +
      escape(agent.id) +
      '">配置</button>' +
      '<button class="op reset" type="button" data-agent-action="debug" data-id="' +
      escape(agent.id) +
      '">调试</button>' +
      '<button class="op addc" type="button" data-agent-action="duplicate" data-id="' +
      escape(agent.id) +
      '">复制</button>' +
      statusAction +
      '</td></tr>'
    );
  }

  function renderList(rows) {
    const body = $('#agent-table tbody');
    if (!body || !Array.isArray(rows)) return;
    if (!rows.length) {
      renderListEmpty('当前筛选条件下暂无智能体');
      return;
    }
    body.innerHTML = rows.map(renderAgentRow).join('');
  }

  function renderPager() {
    const pages = Math.max(1, Math.ceil(state.total / state.pageSize));
    const current = Math.min(state.page, pages);
    setText(
      '#agent-count',
      '共 ' + state.total + ' 个智能体 · 第 ' + current + ' / ' + pages + ' 页',
    );

    const root = $('#agent-pager');
    if (!root) return;
    const visiblePages = new Set([
      1,
      pages,
      current - 2,
      current - 1,
      current,
      current + 1,
      current + 2,
    ]);
    const pageNumbers = Array.from(visiblePages)
      .filter((page) => page >= 1 && page <= pages)
      .sort((a, b) => a - b);
    const buttons = [
      '<button type="button" data-agent-page="' +
        (current - 1) +
        '"' +
        (current <= 1 ? ' disabled' : '') +
        '>«</button>',
    ];
    let previous = 0;
    pageNumbers.forEach((page) => {
      if (previous && page - previous > 1) {
        buttons.push('<button type="button" disabled>…</button>');
      }
      buttons.push(
        '<button type="button" data-agent-page="' +
          page +
          '" class="' +
          (page === current ? 'on' : '') +
          '">' +
          page +
          '</button>',
      );
      previous = page;
    });
    buttons.push(
      '<button type="button" data-agent-page="' +
        (current + 1) +
        '"' +
        (current >= pages ? ' disabled' : '') +
        '>»</button>',
    );
    root.innerHTML = buttons.join('');
  }

  async function load() {
    if (USE_MOCK) return;
    const sequence = ++state.listSeq;
    state.listLoading = true;
    renderListLoading();
    try {
      const data = await global.AdminApi.get(listQuery(), realOptions());
      if (sequence !== state.listSeq) return;
      state.items = (data && data.list) || [];
      state.total = (data && data.total) || 0;
      const pages = Math.max(1, Math.ceil(state.total / state.pageSize));
      if (state.page > pages) {
        state.page = pages;
        state.listLoading = false;
        return load();
      }
      renderList(state.items);
    } catch (error) {
      if (sequence !== state.listSeq) return;
      state.items = [];
      state.total = 0;
      renderListEmpty(
        '智能体加载失败：' +
          ((error && error.message) || '请确认后端与管理员登录状态'),
      );
    } finally {
      if (sequence === state.listSeq) {
        state.listLoading = false;
        renderPager();
      }
    }
  }

  function reloadFromFirstPage() {
    state.page = 1;
    load();
  }

  // -------------------------------------------------------------------------
  // 统一工具库
  // -------------------------------------------------------------------------

  async function loadTools(force) {
    if (!force && state.toolsLoaded) return state.tools;
    if (state.toolsLoading) return state.toolsLoading;

    state.toolsLoading = global.AdminApi
      .get('/tools', realOptions())
      .then((data) => {
        state.tools = Array.isArray(data) ? data : [];
        state.toolsLoaded = true;
        state.toolsError = '';
        return state.tools;
      })
      .catch((error) => {
        state.tools = [];
        state.toolsLoaded = false;
        state.toolsError =
          (error && error.message) || '统一工具库加载失败';
        throw error;
      })
      .finally(() => {
        state.toolsLoading = null;
      });
    return state.toolsLoading;
  }

  function modelTools() {
    return state.tools.filter((tool) => tool.toolSource === 'MODEL');
  }

  function populateModelSelect(detail) {
    const select = $('#ad-model');
    if (!select) return;
    const options = [
      '<option value="">不绑定默认模型</option>',
    ];
    const seen = new Set();
    modelTools().forEach((tool) => {
      const id = Number(tool.toolRefId);
      if (!Number.isFinite(id) || seen.has(id)) return;
      seen.add(id);
      options.push(
        '<option value="' +
          escape(id) +
          '">' +
          escape(tool.name || '未命名模型') +
          '</option>',
      );
    });
    if (
      detail &&
      detail.modelProviderId !== null &&
      detail.modelProviderId !== undefined &&
      !seen.has(Number(detail.modelProviderId))
    ) {
      options.push(
        '<option value="' +
          escape(detail.modelProviderId) +
          '">' +
          escape(detail.modelProviderName || '当前绑定模型（不可用）') +
          '</option>',
      );
    }
    select.innerHTML = options.join('');
    select.value =
      detail &&
      detail.modelProviderId !== null &&
      detail.modelProviderId !== undefined
        ? String(detail.modelProviderId)
        : '';
  }

  function findToolForNode(node) {
    return state.tools.find(
      (tool) =>
        tool.toolSource === node.toolSource &&
        String(tool.toolRefId === null || tool.toolRefId === undefined ? '' : tool.toolRefId) ===
          String(node.toolRefId === null || node.toolRefId === undefined ? '' : node.toolRefId) &&
        tool.toolKey === node.toolKey,
    );
  }

  function renderToolPicker(message) {
    const box = $('#skill-picker');
    if (!box) return;
    if (message) {
      box.innerHTML =
        '<div class="agent-tool-empty">' + escape(message) + '</div>';
      return;
    }
    if (!state.tools.length) {
      box.innerHTML =
        '<div class="agent-tool-empty">统一工具库暂无可绑定工具</div>';
      return;
    }
    box.innerHTML = state.tools
      .map((tool, index) => {
        const source = sourceMeta(tool.toolSource, tool.toolSourceLabel);
        const added = Boolean(
          state.detail &&
            state.detail.nodes.some(
              (node) => toolIdentity(node) === toolIdentity(tool),
            ),
        );
        const disabled = added || tool.enabled === false;
        return (
          '<button class="skill-card agent-tool-card' +
          (disabled ? ' added' : '') +
          '" type="button" data-tool-index="' +
          index +
          '" data-tool-source="' +
          escape(tool.toolSource || '') +
          '"' +
          (disabled ? ' disabled' : '') +
          '>' +
          '<span class="sc-top"><span class="sc-ico">' +
          escape(source.icon) +
          '</span><strong>' +
          escape(tool.name || tool.toolKey || '未命名工具') +
          '</strong></span>' +
          '<span class="agent-tool-meta"><span class="bdg ' +
          source.badge +
          '">' +
          escape(tool.toolSourceLabel || source.label) +
          '</span><em>' +
          escape(tool.toolKindLabel || tool.toolKind || '能力') +
          '</em></span>' +
          '<p>' +
          escape(tool.description || tool.toolKey || '统一工具库能力') +
          '</p>' +
          '<span class="sc-add">' +
          (added ? '已添加' : tool.enabled === false ? '已停用' : '添加到编排') +
          '</span></button>'
        );
      })
      .join('');
    filterToolPicker();
  }

  function filterToolPicker() {
    const keywordElement = $('#agent-tool-search');
    const sourceElement = $('#agent-tool-source');
    const keyword = keywordElement
      ? keywordElement.value.trim().toLowerCase()
      : '';
    const source = sourceElement ? sourceElement.value : '';
    $$('#skill-picker .skill-card').forEach((card) => {
      const index = Number(card.dataset.toolIndex);
      const tool = state.tools[index];
      if (!tool) {
        card.style.display = 'none';
        return;
      }
      const text = [
        tool.name,
        tool.description,
        tool.toolKindLabel,
        tool.toolSourceLabel,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      const visible =
        (!keyword || text.includes(keyword)) &&
        (!source || tool.toolSource === source);
      card.style.display = visible ? '' : 'none';
    });
  }

  async function openToolPicker() {
    const box = $('#skill-picker');
    if (box && !state.toolsLoaded) {
      renderToolPicker('正在加载统一工具库…');
    }
    global.AdminApp.openModal('modal-skill');
    try {
      await loadTools(false);
      renderToolPicker();
    } catch (error) {
      renderToolPicker(state.toolsError || '统一工具库加载失败，请稍后重试');
    }
  }

  function nextNodeKey() {
    const keys = new Set(
      state.detail ? state.detail.nodes.map((node) => node.nodeKey) : [],
    );
    let index = 1;
    while (keys.has('n' + index)) index += 1;
    return 'n' + index;
  }

  function addTool(index) {
    if (!state.detail) return;
    const tool = state.tools[index];
    if (!tool || tool.enabled === false) return;
    if (
      state.detail.nodes.some(
        (node) => toolIdentity(node) === toolIdentity(tool),
      )
    ) {
      toast('该工具已在当前编排中', 'warn');
      return;
    }
    state.detail.nodes.push({
      nodeKey: nextNodeKey(),
      name: tool.name || tool.toolKey || '编排节点',
      orderIndex: state.detail.nodes.length,
      enabled: true,
      toolSource: tool.toolSource,
      toolRefId: tool.toolRefId,
      toolKey: tool.toolKey,
      toolNameSnapshot: tool.name || null,
      paramsJson: '{}',
      routeKeywords: null,
      routeTargetKey: null,
    });
    markDirty(true);
    renderNodes();
    renderToolPicker();
    toast('已添加节点：' + (tool.name || tool.toolKey), 'ok');
  }

  // -------------------------------------------------------------------------
  // 第二层：详情与节点编排
  // -------------------------------------------------------------------------

  function normalizeNode(node, index) {
    return {
      nodeKey: node.nodeKey || 'n' + (index + 1),
      name: node.name || node.toolNameSnapshot || node.nodeKey || '编排节点',
      orderIndex:
        node.orderIndex === null || node.orderIndex === undefined
          ? index
          : Number(node.orderIndex),
      enabled: node.enabled !== false,
      toolSource: node.toolSource || 'BUILTIN',
      toolSourceLabel: node.toolSourceLabel || null,
      toolRefId: node.toolRefId === undefined ? null : node.toolRefId,
      toolKey: node.toolKey || '',
      toolKind: node.toolKind || '',
      toolKindLabel: node.toolKindLabel || '',
      toolNameSnapshot:
        node.toolNameSnapshot || node.name || node.toolKey || '工具',
      paramsJson:
        node.paramsJson === null || node.paramsJson === undefined
          ? '{}'
          : String(node.paramsJson),
      routeKeywords: node.routeKeywords || '',
      routeTargetKey: node.routeTargetKey || '',
    };
  }

  function normalizeDetail(detail) {
    const billing = detail.billing || {};
    return {
      id: detail.id,
      name: detail.name || '',
      code: detail.code || '',
      category: detail.category || 'OTHER',
      categoryLabel: detail.categoryLabel || '',
      description: detail.description || '',
      icon: detail.icon || '🤖',
      modelProviderId:
        detail.modelProviderId === undefined ? null : detail.modelProviderId,
      modelProviderName: detail.modelProviderName || '',
      systemPrompt: detail.systemPrompt || '',
      greeting: detail.greeting || '',
      billing: {
        baseCost:
          billing.baseCost === null || billing.baseCost === undefined
            ? 0
            : billing.baseCost,
        maxRounds:
          billing.maxRounds === null || billing.maxRounds === undefined
            ? 8
            : billing.maxRounds,
        timeoutSeconds:
          billing.timeoutSeconds === null ||
          billing.timeoutSeconds === undefined
            ? 60
            : billing.timeoutSeconds,
        dailyQuota:
          billing.dailyQuota === null || billing.dailyQuota === undefined
            ? 5000
            : billing.dailyQuota,
        allowUserSkill: billing.allowUserSkill === true,
        logFullConversation: billing.logFullConversation !== false,
      },
      nodes: (detail.nodes || []).map(normalizeNode),
      status: detail.status || 'DRAFT',
      statusLabel: detail.statusLabel || '',
      currentVersion: detail.currentVersion || 0,
      createdAt: detail.createdAt || null,
      updatedAt: detail.updatedAt || null,
    };
  }

  function renderDetailStatus(detail) {
    const status = statusMeta(detail.status, detail.statusLabel);
    const badge = $('#agent-detail-status');
    if (badge) {
      badge.textContent = status.label;
      badge.className = 'bdg st ' + status.badge;
    }
    const publishButton = $('#agent-publish');
    if (publishButton) {
      publishButton.textContent =
        detail.status === 'PUBLISHED' ? '下线' : '发布';
    }
  }

  function fillDetail(detail) {
    setText('#agent-detail-name', detail.name || '未命名智能体');
    renderDetailStatus(detail);
    setValue('#ad-name', detail.name);
    setValue('#ad-key', detail.code);
    setValue('#ad-type', detail.category || 'OTHER');
    populateModelSelect(detail);
    setValue('#ad-description', detail.description);
    setValue('#ad-prompt', detail.systemPrompt);
    setValue('#ad-greeting', detail.greeting);
    setValue('#ad-base-cost', detail.billing.baseCost);
    setValue('#ad-max-rounds', detail.billing.maxRounds);
    setValue('#ad-timeout', detail.billing.timeoutSeconds);
    setValue('#ad-quota', detail.billing.dailyQuota);

    $$('#ad-emoji .emo').forEach((button) => {
      button.classList.toggle('on', button.dataset.emo === detail.icon);
    });
    const allowSkill = $('#ad-allow-skill');
    const logFull = $('#ad-log-full');
    if (allowSkill) {
      allowSkill.classList.toggle('on', detail.billing.allowUserSkill);
      allowSkill.setAttribute(
        'aria-pressed',
        detail.billing.allowUserSkill ? 'true' : 'false',
      );
    }
    if (logFull) {
      logFull.classList.toggle('on', detail.billing.logFullConversation);
      logFull.setAttribute(
        'aria-pressed',
        detail.billing.logFullConversation ? 'true' : 'false',
      );
    }
    renderNodes();
    renderPreviewPlaceholder();
    markDirty(false);
  }

  function renderNodes() {
    const root = $('#ad-skill-list');
    if (!root || !state.detail) return;
    const nodes = state.detail.nodes;
    if (!nodes.length) {
      root.innerHTML =
        '<div class="agent-tool-empty">还没有编排节点。点击下方“添加工具节点”开始编排。</div>';
    } else {
      root.innerHTML = nodes
        .map((node, index) => {
          const source = sourceMeta(node.toolSource, node.toolSourceLabel);
          const tool = findToolForNode(node);
          const toolName =
            node.toolNameSnapshot ||
            (tool && tool.name) ||
            node.toolKey ||
            '工具';
          return (
            '<div class="skill-item' +
            (node.enabled ? '' : ' off') +
            '" data-node-index="' +
            index +
            '">' +
            '<span class="drag" title="节点顺序">' +
            (index + 1) +
            '</span>' +
            '<span class="sk-ico">' +
            escape(source.icon) +
            '</span>' +
            '<span class="sk-main"><strong>' +
            escape(node.name) +
            '</strong><em><span class="bdg ' +
            source.badge +
            '">' +
            escape(node.toolSourceLabel || source.label) +
            '</span>' +
            escape(node.toolKindLabel || node.toolKind || '能力') +
            ' · ' +
            escape(toolName) +
            '</em></span>' +
            '<span class="sk-ops">' +
            '<button class="sw' +
            (node.enabled ? ' on' : '') +
            '" type="button" data-node-action="toggle" title="启用/停用"></button>' +
            '<button class="sk-btn cfg" type="button" data-node-action="config" title="配置节点">⚙</button>' +
            '<button class="sk-btn up" type="button" data-node-action="up" title="上移">▲</button>' +
            '<button class="sk-btn down" type="button" data-node-action="down" title="下移">▼</button>' +
            '<button class="sk-btn del" type="button" data-node-action="delete" title="删除节点">✕</button>' +
            '</span></div>'
          );
        })
        .join('');
    }
    const enabledCount = nodes.filter((node) => node.enabled).length;
    setText(
      '#ad-skill-count',
      nodes.length + ' 个节点 · ' + enabledCount + ' 启用',
    );
    setText(
      '#ad-skill-cost',
      enabledCount
        ? enabledCount + ' 个启用节点 · 附加算力由运行时结算'
        : '暂无启用节点',
    );
  }

  function renderPreviewPlaceholder() {
    const root = $('#agent-preview-log');
    if (!root || !state.detail) return;
    const greeting =
      state.detail.greeting || '你好，请输入要预览的用户输入。';
    const nodes = state.detail.nodes
      .filter((node) => node.enabled)
      .map(
        (node, index) =>
          (index + 1) + '. ' + (node.name || node.nodeKey),
      );
    root.innerHTML =
      '<div class="bub bot">' +
      escape(greeting) +
      (nodes.length
        ? '<span class="tool-trace">当前启用链路：' +
          escape(nodes.join(' → ')) +
          '</span>'
        : '<span class="tool-trace">当前没有启用节点，保存后可继续添加。</span>') +
      '</div>';
    setText(
      '#agent-preview-meta',
      '预览消耗不扣费 · 当前版本 v' + state.detail.currentVersion,
    );
  }

  async function openDetail(id, options) {
    if (!id) return;
    const opts = options || {};
    state.activeAgentId = Number(id);
    state.detailLoading = true;
    state.detail = null;
    $('#agents-list-view').classList.add('hidden');
    $('#agents-detail-view').classList.remove('hidden');
    $('#pg-agents').scrollTop = 0;
    setText('#pg-title', '智能体 Skill 配置 / 加载中…');
    setText('#agent-detail-name', '加载中…');
    setText('#ad-skill-count', '正在加载…');
    const list = $('#ad-skill-list');
    if (list) {
      list.innerHTML =
        '<div class="agent-tool-empty">正在加载节点编排…</div>';
    }
    markDirty(false);

    let toolsError = null;
    try {
      const results = await Promise.all([
        global.AdminApi.get('/agents/' + Number(id), realOptions()),
        loadTools(true).catch((error) => {
          toolsError = error;
          return [];
        }),
      ]);
      const detail = normalizeDetail(results[0] || {});
      state.detail = detail;
      fillDetail(detail);
      setText(
        '#pg-title',
        '智能体 Skill 配置 / ' + (detail.name || detail.code),
      );
      if (toolsError) {
        toast(
          '编排已加载，但工具库加载失败：' +
            (toolsError.message || '请稍后重试'),
          'warn',
        );
      } else if (!opts.silent) {
        toast('已加载「' + detail.name + '」的编排', 'ok');
      }
    } catch (error) {
      state.detail = null;
      setText('#agent-detail-name', '加载失败');
      setText('#pg-title', '智能体 Skill 配置 / 加载失败');
      const root = $('#ad-skill-list');
      if (root) {
        root.innerHTML =
          '<div class="agent-tool-empty">' +
          escape(
            '智能体详情加载失败：' +
              ((error && error.message) || '请确认后端状态'),
          ) +
          '</div>';
      }
      toast(
        (error && error.message) || '智能体详情加载失败',
        'err',
      );
    } finally {
      state.detailLoading = false;
    }
  }

  function showList() {
    $('#agents-list-view').classList.remove('hidden');
    $('#agents-detail-view').classList.add('hidden');
    setText('#pg-title', '智能体 Skill 配置');
    state.detail = null;
    state.activeAgentId = null;
    state.nodeEditingIndex = -1;
    markDirty(false);
  }

  function openNodeEditor(index) {
    if (!state.detail || !state.detail.nodes[index]) return;
    state.nodeEditingIndex = index;
    const node = state.detail.nodes[index];
    const source = sourceMeta(node.toolSource, node.toolSourceLabel);
    const tool = findToolForNode(node);
    const toolInfo = $('#node-editor-tool');
    if (toolInfo) {
      toolInfo.innerHTML =
        '<span class="node-editor-tool-icon">' +
        escape(source.icon) +
        '</span><div><strong>' +
        escape(
          node.toolNameSnapshot ||
            (tool && tool.name) ||
            node.toolKey ||
            '工具',
        ) +
        '</strong><em><span class="bdg ' +
        source.badge +
        '">' +
        escape(node.toolSourceLabel || source.label) +
        '</span>' +
        escape(node.toolKindLabel || node.toolKind || '统一工具') +
        '</em></div>';
    }
    setValue('#node-name', node.name);
    setValue('#node-key', node.nodeKey);
    setValue('#node-params', node.paramsJson || '{}');
    setValue('#node-keywords', node.routeKeywords);
    const enabled = $('#node-enabled');
    if (enabled) {
      enabled.classList.toggle('on', node.enabled);
      enabled.setAttribute('aria-pressed', node.enabled ? 'true' : 'false');
    }
    renderNodeTargets(node.routeTargetKey, index);
    global.AdminApp.openModal('modal-agent-node');
    const nameInput = $('#node-name');
    if (nameInput) nameInput.focus();
  }

  function renderNodeTargets(selected, editingIndex) {
    const select = $('#node-target');
    if (!select || !state.detail) return;
    const options = ['<option value="">不跳转</option>'];
    state.detail.nodes.forEach((node, index) => {
      if (index === editingIndex) return;
      options.push(
        '<option value="' +
          escape(node.nodeKey) +
          '">' +
          escape(node.name + '（' + node.nodeKey + '）') +
          '</option>',
      );
    });
    select.innerHTML = options.join('');
    select.value = selected || '';
  }

  function saveNodeEditor() {
    if (
      !state.detail ||
      state.nodeEditingIndex < 0 ||
      !state.detail.nodes[state.nodeEditingIndex]
    ) {
      return;
    }
    const node = state.detail.nodes[state.nodeEditingIndex];
    const name = $('#node-name').value.trim();
    const nodeKey = $('#node-key').value.trim();
    if (!name) {
      toast('请填写节点名称', 'err');
      return;
    }
    if (!/^[A-Za-z0-9_-]+$/.test(nodeKey)) {
      toast('节点标识只能包含字母、数字、下划线和短横线', 'err');
      return;
    }
    if (
      state.detail.nodes.some(
        (item, index) =>
          index !== state.nodeEditingIndex && item.nodeKey === nodeKey,
      )
    ) {
      toast('节点标识已存在，请更换', 'err');
      return;
    }
    const paramsText = $('#node-params').value.trim();
    if (paramsText) {
      try {
        JSON.parse(paramsText);
      } catch (error) {
        toast('节点参数必须是合法 JSON', 'err');
        return;
      }
    }
    const routeTarget = $('#node-target').value;
    if (routeTarget && routeTarget === nodeKey) {
      toast('路由目标不能指向节点自身', 'err');
      return;
    }

    const previousKey = node.nodeKey;
    node.name = name;
    node.nodeKey = nodeKey;
    if (previousKey !== nodeKey) {
      state.detail.nodes.forEach((item) => {
        if (item !== node && item.routeTargetKey === previousKey) {
          item.routeTargetKey = nodeKey;
        }
      });
    }
    node.paramsJson = paramsText || '{}';
    node.routeKeywords = $('#node-keywords').value.trim();
    node.routeTargetKey = routeTarget;
    const enabled = $('#node-enabled');
    node.enabled = Boolean(enabled && enabled.classList.contains('on'));
    state.nodeEditingIndex = -1;
    global.AdminApp.closeModal('modal-agent-node');
    markDirty(true);
    renderNodes();
    toast('节点配置已更新，保存编排后生效', 'ok');
  }

  function handleNodeAction(event) {
    const button = event.target.closest('[data-node-action]');
    if (!button) return;
    const item = button.closest('[data-node-index]');
    if (!item || !state.detail) return;
    const index = Number(item.dataset.nodeIndex);
    const node = state.detail.nodes[index];
    if (!node) return;
    const action = button.dataset.nodeAction;

    if (action === 'toggle') {
      node.enabled = !node.enabled;
      markDirty(true);
      renderNodes();
      return;
    }
    if (action === 'config') {
      openNodeEditor(index);
      return;
    }
    if (action === 'delete') {
      const deletedKey = node.nodeKey;
      state.detail.nodes.splice(index, 1);
      state.detail.nodes.forEach((item, itemIndex) => {
        item.orderIndex = itemIndex;
        if (item.routeTargetKey === deletedKey) {
          item.routeTargetKey = '';
        }
      });
      markDirty(true);
      renderNodes();
      toast('节点已从当前编排移除，保存后生效', 'warn');
      return;
    }
    if (action === 'up' && index > 0) {
      const previous = state.detail.nodes[index - 1];
      state.detail.nodes[index - 1] = node;
      state.detail.nodes[index] = previous;
      state.detail.nodes.forEach((item, itemIndex) => {
        item.orderIndex = itemIndex;
      });
      markDirty(true);
      renderNodes();
      return;
    }
    if (action === 'down' && index < state.detail.nodes.length - 1) {
      const next = state.detail.nodes[index + 1];
      state.detail.nodes[index + 1] = node;
      state.detail.nodes[index] = next;
      state.detail.nodes.forEach((item, itemIndex) => {
        item.orderIndex = itemIndex;
      });
      markDirty(true);
      renderNodes();
    }
  }

  function numericField(selector, label, min, integer) {
    const raw = $(selector).value.trim();
    if (raw === '') return null;
    const value = Number(raw);
    if (
      !Number.isFinite(value) ||
      (min !== undefined && value < min) ||
      (integer && !Number.isInteger(value))
    ) {
      throw new Error(
        label +
          (min !== undefined ? '不能小于 ' + min : '') +
          (integer ? '，且必须是整数' : ''),
      );
    }
    return value;
  }

  function collectDetailPayload() {
    if (!state.detail) throw new Error('智能体详情尚未加载');
    const name = $('#ad-name').value.trim();
    const code = $('#ad-key').value.trim();
    if (!name) throw new Error('请填写智能体名称');
    if (!code) throw new Error('请填写智能体标识');
    if (!/^[A-Za-z0-9_-]+$/.test(code)) {
      throw new Error('智能体标识只能包含字母、数字、下划线和短横线');
    }

    const category = $('#ad-type').value;
    if (!CATEGORY_META[category]) {
      throw new Error('请选择有效的智能体分类');
    }
    const modelValue = $('#ad-model').value;
    const selectedEmoji = $('#ad-emoji .emo.on');
    const nodes = state.detail.nodes.map((node, index) => {
      if (!node.nodeKey || !node.toolKey) {
        throw new Error('第 ' + (index + 1) + ' 个节点缺少工具标识');
      }
      const params = trimToNull(node.paramsJson);
      if (params) {
        try {
          JSON.parse(params);
        } catch (error) {
          throw new Error('节点「' + node.name + '」的参数不是合法 JSON');
        }
      }
      return {
        nodeKey: node.nodeKey,
        name: node.name,
        orderIndex: index,
        enabled: node.enabled !== false,
        toolSource: node.toolSource,
        toolRefId: node.toolRefId === undefined ? null : node.toolRefId,
        toolKey: node.toolKey,
        toolNameSnapshot: node.toolNameSnapshot || node.name,
        paramsJson: params,
        routeKeywords: trimToNull(node.routeKeywords),
        routeTargetKey: trimToNull(node.routeTargetKey),
      };
    });

    return {
      name: name,
      code: code,
      category: category,
      description: trimToNull($('#ad-description').value),
      icon: selectedEmoji ? selectedEmoji.dataset.emo : '🤖',
      modelProviderId: modelValue ? Number(modelValue) : null,
      systemPrompt: trimToNull($('#ad-prompt').value),
      greeting: trimToNull($('#ad-greeting').value),
      billing: {
        baseCost: numericField('#ad-base-cost', '基础算力', 0, false),
        maxRounds: numericField('#ad-max-rounds', '最大轮次', 1, true),
        timeoutSeconds: numericField('#ad-timeout', '超时时间', 5, true),
        dailyQuota: numericField('#ad-quota', '每日调用上限', 0, true),
        allowUserSkill: Boolean(
          $('#ad-allow-skill') &&
            $('#ad-allow-skill').classList.contains('on'),
        ),
        logFullConversation: Boolean(
          $('#ad-log-full') &&
            $('#ad-log-full').classList.contains('on'),
        ),
      },
      nodes: nodes,
    };
  }

  async function saveDetail() {
    if (!state.detail || state.saving) return;
    let payload;
    try {
      payload = collectDetailPayload();
    } catch (error) {
      toast(error.message, 'err');
      return;
    }

    state.saving = true;
    setButtonLoading('#agent-save', true, '保存编排', '保存中…');
    try {
      const saved = await global.AdminApi.put(
        '/agents/' + state.detail.id + '/nodes',
        payload,
        realOptions(),
      );
      const detail = normalizeDetail(saved || payload);
      if (!detail.id) detail.id = state.detail.id;
      state.detail = detail;
      fillDetail(detail);
      setText(
        '#pg-title',
        '智能体 Skill 配置 / ' + (detail.name || detail.code),
      );
      toast(
        '编排已保存为 v' + (detail.currentVersion || '新') + ' 版本',
        'ok',
      );
      await load();
    } catch (error) {
      toast((error && error.message) || '编排保存失败', 'err');
    } finally {
      state.saving = false;
      setButtonLoading('#agent-save', false, '保存编排', '保存中…');
    }
  }

  async function togglePublish() {
    if (!state.detail) return;
    if (state.dirty) {
      toast('请先保存编排，再发布或下线', 'warn');
      return;
    }
    const published = state.detail.status === 'PUBLISHED';
    if (
      published &&
      !global.confirm('确定下线「' + state.detail.name + '」吗？')
    ) {
      return;
    }
    const button = $('#agent-publish');
    if (button) button.disabled = true;
    try {
      await global.AdminApi.post(
        '/agents/' +
          state.detail.id +
          '/' +
          (published ? 'offline' : 'publish'),
        undefined,
        realOptions(),
      );
      toast(
        state.detail.name + (published ? ' 已下线' : ' 已发布'),
        'ok',
      );
      await openDetail(state.detail.id, { silent: true });
      await load();
    } catch (error) {
      toast((error && error.message) || '状态更新失败', 'err');
    } finally {
      if (button) button.disabled = false;
    }
  }

  async function runPreview() {
    if (!state.detail) return;
    if (state.dirty) {
      toast('请先保存编排，预览运行的是已保存版本', 'warn');
      return;
    }
    const input =
      ($('#agent-preview-input') && $('#agent-preview-input').value.trim()) ||
      '请介绍这个智能体的能力';
    const root = $('#agent-preview-log');
    if (root) {
      root.innerHTML =
        '<div class="bub user">' +
        escape(input) +
        '</div><div class="bub bot">正在执行编排，请稍候…</div>';
    }
    setButtonLoading(
      '#btn-agent-preview',
      true,
      '运行预览',
      '运行中…',
    );
    try {
      const result = await global.AdminApi.post(
        '/agents/' + state.detail.id + '/preview',
        { input: input },
        realOptions(),
      );
      const steps = (result && result.nodes) || [];
      const trace = steps.length
        ? steps
            .map(
              (step, index) =>
                (index + 1) +
                '. ' +
                escape(step.name || step.nodeKey) +
                (step.success === false ? '（失败）' : '') +
                ' · ' +
                elapsedText(step.elapsedMs),
            )
            .join('<br>')
        : '没有启用的编排节点';
      if (root) {
        root.innerHTML =
          '<div class="bub user">' +
          escape(input) +
          '</div><div class="bub bot">' +
          escape((result && result.finalOutput) || '预览执行完成') +
          '<span class="tool-trace">' +
          trace +
          '</span></div>';
      }
      setText(
        '#agent-preview-meta',
        '耗时 ' +
          elapsedText(result && result.totalElapsedMs) +
          ' · 演示算力 ' +
          numberText(result && result.totalCredits, 2) +
          ' · 不扣真实余额',
      );
    } catch (error) {
      renderPreviewPlaceholder();
      toast((error && error.message) || '编排预览失败', 'err');
    } finally {
      setButtonLoading(
        '#btn-agent-preview',
        false,
        '运行预览',
        '运行中…',
      );
    }
  }

  // -------------------------------------------------------------------------
  // 新建、导入与列表操作
  // -------------------------------------------------------------------------

  function openCreateModal() {
    setValue('#ag-name', '');
    setValue('#ag-key', '');
    setValue('#ag-type', 'MARKETING');
    setValue('#ag-desc', '');
    setValue('#ag-icon', '🤖');
    global.AdminApp.openModal('modal-agent');
    const nameInput = $('#ag-name');
    if (nameInput) nameInput.focus();
  }

  async function createAgent() {
    const name = $('#ag-name').value.trim();
    const code = $('#ag-key').value.trim();
    const category = $('#ag-type').value;
    const description = $('#ag-desc').value.trim();
    const icon = $('#ag-icon').value.trim() || '🤖';
    if (!name) {
      toast('请填写智能体名称', 'err');
      return;
    }
    if (!code) {
      toast('请填写智能体标识', 'err');
      return;
    }
    if (!/^[A-Za-z0-9_-]+$/.test(code)) {
      toast('智能体标识只能包含字母、数字、下划线和短横线', 'err');
      return;
    }
    if (!CATEGORY_META[category]) {
      toast('请选择智能体分类', 'err');
      return;
    }

    setButtonLoading('#ag-ok', true, '确认创建', '创建中…');
    try {
      const created = await global.AdminApi.post(
        '/agents',
        {
          name: name,
          code: code,
          category: category,
          description: description || null,
          icon: icon,
        },
        realOptions(),
      );
      if (!created || !created.id) {
        throw new Error('后端未返回新智能体 ID');
      }
      global.AdminApp.closeModal('modal-agent');
      toast('智能体「' + name + '」创建成功', 'ok');
      await load();
      await openDetail(created.id, { silent: true });
    } catch (error) {
      toast((error && error.message) || '智能体创建失败', 'err');
    } finally {
      setButtonLoading('#ag-ok', false, '确认创建', '创建中…');
    }
  }

  async function importAgentFile(file) {
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      toast('配置文件不能超过 2MB', 'err');
      return;
    }
    try {
      const content = await file.text();
      let config;
      try {
        config = JSON.parse(content);
      } catch (error) {
        throw new Error('所选文件不是合法 JSON');
      }
      const imported = await global.AdminApi.post(
        '/agents/import',
        config,
        realOptions(),
      );
      toast('智能体配置导入成功', 'ok');
      await load();
      if (imported && imported.id) {
        await openDetail(imported.id, { silent: true });
      }
    } catch (error) {
      toast((error && error.message) || '智能体配置导入失败', 'err');
    } finally {
      const input = $('#agent-import-file');
      if (input) input.value = '';
    }
  }

  async function handleListAction(action, id) {
    if (!id) return;
    if (action === 'config') {
      openDetail(id);
      return;
    }
    if (action === 'debug') {
      global.AdminApp.goPage('debug');
      toast('已切换调试面板；请在面板中选择该智能体', 'warn');
      return;
    }
    if (action === 'duplicate') {
      try {
        const copied = await global.AdminApi.post(
          '/agents/' + id + '/duplicate',
          undefined,
          realOptions(),
        );
        toast('智能体已复制为草稿', 'ok');
        await load();
        if (copied && copied.id) {
          await openDetail(copied.id, { silent: true });
        }
      } catch (error) {
        toast((error && error.message) || '智能体复制失败', 'err');
      }
      return;
    }
    if (action === 'publish' || action === 'offline') {
      try {
        await global.AdminApi.post(
          '/agents/' + id + '/' + action,
          undefined,
          realOptions(),
        );
        toast(action === 'publish' ? '智能体已发布' : '智能体已下线', 'ok');
        await load();
      } catch (error) {
        toast((error && error.message) || '智能体状态更新失败', 'err');
      }
    }
  }

  // -------------------------------------------------------------------------
  // 事件绑定
  // -------------------------------------------------------------------------

  function bind() {
    if (state.initialized) return;
    state.initialized = true;

    const search = $('#agent-search');
    if (search) {
      search.addEventListener(
        'input',
        debounce(() => {
          state.keyword = search.value.trim();
          reloadFromFirstPage();
        }, 250),
      );
    }
    const category = $('#agent-type');
    if (category) {
      category.addEventListener('change', () => {
        state.category = category.value;
        reloadFromFirstPage();
      });
    }
    const status = $('#agent-status');
    if (status) {
      status.addEventListener('change', () => {
        state.status = status.value;
        reloadFromFirstPage();
      });
    }
    const refresh = $('#btn-agent-refresh');
    if (refresh) refresh.addEventListener('click', load);
    const add = $('#btn-agent-add');
    if (add) add.addEventListener('click', openCreateModal);

    const importButton = $('#btn-agent-import');
    const importFile = $('#agent-import-file');
    if (importButton && importFile) {
      importButton.addEventListener('click', () => importFile.click());
      importFile.addEventListener('change', () =>
        importAgentFile(importFile.files && importFile.files[0]),
      );
    }

    const table = $('#agent-table');
    if (table) {
      table.addEventListener('click', (event) => {
        const button = event.target.closest('[data-agent-action]');
        if (!button || button.disabled) return;
        handleListAction(button.dataset.agentAction, button.dataset.id);
      });
    }

    const pager = $('#agent-pager');
    if (pager) {
      pager.addEventListener('click', (event) => {
        const button = event.target.closest('[data-agent-page]');
        if (!button || button.disabled) return;
        state.page = Number(button.dataset.agentPage) || 1;
        load();
      });
    }

    const back = $('#agent-back');
    if (back) back.addEventListener('click', showList);
    const save = $('#agent-save');
    if (save) save.addEventListener('click', saveDetail);
    const publish = $('#agent-publish');
    if (publish) publish.addEventListener('click', togglePublish);
    const preview = $('#btn-agent-preview');
    if (preview) preview.addEventListener('click', runPreview);
    const previewInput = $('#agent-preview-input');
    if (previewInput) {
      previewInput.addEventListener('keydown', (event) => {
        if (event.key === 'Enter') {
          event.preventDefault();
          runPreview();
        }
      });
    }

    [
      '#ad-name',
      '#ad-key',
      '#ad-type',
      '#ad-model',
      '#ad-description',
      '#ad-prompt',
      '#ad-greeting',
      '#ad-base-cost',
      '#ad-max-rounds',
      '#ad-timeout',
      '#ad-quota',
    ].forEach((selector) => {
      const element = $(selector);
      if (!element) return;
      element.addEventListener('input', () => markDirty(true));
      element.addEventListener('change', () => markDirty(true));
    });

    const emoji = $('#ad-emoji');
    if (emoji) {
      emoji.addEventListener('click', (event) => {
        const button = event.target.closest('.emo');
        if (!button) return;
        $$('#ad-emoji .emo').forEach((item) =>
          item.classList.remove('on'),
        );
        button.classList.add('on');
        markDirty(true);
      });
    }
    ['#ad-allow-skill', '#ad-log-full'].forEach((selector) => {
      const toggle = $(selector);
      if (!toggle) return;
      toggle.addEventListener('click', () => {
        toggle.classList.toggle('on');
        toggle.setAttribute(
          'aria-pressed',
          toggle.classList.contains('on') ? 'true' : 'false',
        );
        markDirty(true);
      });
    });

    const nodeList = $('#ad-skill-list');
    if (nodeList) nodeList.addEventListener('click', handleNodeAction);
    const addNode = $('#btn-add-skill');
    if (addNode) addNode.addEventListener('click', openToolPicker);

    const toolSearch = $('#agent-tool-search');
    if (toolSearch) toolSearch.addEventListener('input', filterToolPicker);
    const toolSource = $('#agent-tool-source');
    if (toolSource) toolSource.addEventListener('change', filterToolPicker);
    const toolPicker = $('#skill-picker');
    if (toolPicker) {
      toolPicker.addEventListener('click', (event) => {
        const card = event.target.closest('[data-tool-index]');
        if (!card || card.disabled) return;
        addTool(Number(card.dataset.toolIndex));
      });
    }

    const nodeEnabled = $('#node-enabled');
    if (nodeEnabled) {
      nodeEnabled.addEventListener('click', () => {
        nodeEnabled.classList.toggle('on');
        nodeEnabled.setAttribute(
          'aria-pressed',
          nodeEnabled.classList.contains('on') ? 'true' : 'false',
        );
      });
    }
    const saveNode = $('#node-save');
    if (saveNode) saveNode.addEventListener('click', saveNodeEditor);
    const createButton = $('#ag-ok');
    if (createButton) createButton.addEventListener('click', createAgent);
  }

  function init() {
    bind();
    renderPager();
  }

  global.AdminPages.agents = {
    init,
    load,
    showList,
    showDetail: openDetail,
    USE_MOCK,
    state,
  };
})(window);
