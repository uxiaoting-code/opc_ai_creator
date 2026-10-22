/* ============ 星枢 AI 聚合平台 · 服务端后台交互 ============ */
(function () {
  'use strict';
  const $ = (s, c) => (c || document).querySelector(s);
  const $$ = (s, c) => Array.from((c || document).querySelectorAll(s));

  /* ---------- Toast 轻提示 ---------- */
  let toastWrap = null;
  function toast(msg, type) {
    if (!toastWrap) {
      toastWrap = document.createElement('div');
      toastWrap.className = 'toast-wrap';
      document.body.appendChild(toastWrap);
    }
    const t = document.createElement('div');
    t.className = 'toast' + (type ? ' ' + type : '');
    t.textContent = msg;
    toastWrap.appendChild(t);
    requestAnimationFrame(() => t.classList.add('in'));
    setTimeout(() => {
      t.classList.remove('in');
      setTimeout(() => t.remove(), 260);
    }, 2200);
  }

  /* ---------- 登录 / 退出 ---------- */
  const viewLogin = $('#view-login');
  const viewApp = $('#view-app');
  $('#btn-admin-login').addEventListener('click', () => {
    const u = $('#lg-user').value.trim();
    const p = $('#lg-pass').value.trim();
    if (!u || !p) { toast('请输入账号与密码', 'err'); return; }
    viewLogin.classList.add('hidden');
    viewApp.classList.remove('hidden');
    toast('登录成功，欢迎回来，超级管理员', 'ok');
  });
  $('#lg-pass').addEventListener('keydown', (e) => { if (e.key === 'Enter') $('#btn-admin-login').click(); });
  $('#btn-admin-exit').addEventListener('click', () => {
    viewApp.classList.add('hidden');
    viewLogin.classList.remove('hidden');
    toast('已安全退出');
  });

  /* ---------- 侧栏导航 ---------- */
  const pgTitles = { dash: '数据概览', users: '用户管理', bills: '账单管理', models: '大模型配置', agents: '智能体 Skill 配置', usage: '算力使用', settings: '系统设置' };
  function goPage(pg) {
    $$('.anv').forEach((b) => b.classList.toggle('active', b.dataset.pg === pg));
    $$('.page').forEach((s) => s.classList.toggle('hidden', s.id !== 'pg-' + pg));
    $('#pg-title').textContent = pgTitles[pg] || '';
    if (pg === 'agents') showAgentList();
    const main = $('.adm-main .page:not(.hidden)');
    if (main) main.scrollTop = 0;
  }
  $$('.anv').forEach((b) => b.addEventListener('click', () => goPage(b.dataset.pg)));
  $$('.ph-link[data-goto]').forEach((b) => b.addEventListener('click', () => goPage(b.dataset.goto)));

  /* ---------- 弹窗通用 ---------- */
  function openModal(id) { const m = $('#' + id); if (m) m.classList.remove('hidden'); }
  function closeModal(id) { const m = $('#' + id); if (m) m.classList.add('hidden'); }
  $$('.mask').forEach((m) => {
    m.addEventListener('click', (e) => { if (e.target === m) m.classList.add('hidden'); });
  });
  $$('[data-close]').forEach((b) => b.addEventListener('click', () => closeModal(b.dataset.close)));
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') $$('.mask').forEach((m) => m.classList.add('hidden'));
  });

  /* ---------- 用户管理：搜索 + 状态筛选 ---------- */
  const userTable = $('#user-table');
  function filterUsers() {
    const kw = ($('#user-search').value || '').trim().toLowerCase();
    const st = $('#user-status').value;
    $$('#user-table tbody tr').forEach((tr) => {
      const txt = tr.textContent.toLowerCase();
      const status = $('.st', tr) ? $('.st', tr).textContent.trim() : '';
      const okKw = !kw || txt.includes(kw);
      const okSt = !st || status === st;
      tr.style.display = (okKw && okSt) ? '' : 'none';
    });
  }
  $('#user-search').addEventListener('input', filterUsers);
  $('#user-status').addEventListener('change', filterUsers);
  $('#btn-user-export').addEventListener('click', () => toast('用户数据导出任务已提交，完成后将通知下载', 'ok'));
  $('#btn-user-add').addEventListener('click', () => toast('新增用户请在 C 端注册或导入名单', 'warn'));

  /* 用户行操作：加算力 / 冻结 / 重置密码 */
  let addcRow = null;
  userTable.addEventListener('click', (e) => {
    const btn = e.target.closest('.op');
    if (!btn) return;
    const tr = btn.closest('tr');
    const name = $('.u-cell strong', tr).textContent;
    const uid = tr.children[0].textContent;
    if (btn.classList.contains('addc')) {
      addcRow = tr;
      $('#addc-user').textContent = name + '（UID ' + uid + '）';
      $('#addc-val').value = 100;
      openModal('modal-addc');
    } else if (btn.classList.contains('freeze')) {
      const badge = $('.st', tr);
      const frozen = badge.textContent.trim() === '冻结';
      badge.textContent = frozen ? '正常' : '冻结';
      badge.classList.toggle('red', !frozen);
      badge.classList.toggle('teal', frozen);
      btn.textContent = frozen ? '冻结' : '解冻';
      toast(frozen ? ('已解冻用户 ' + name) : ('已冻结用户 ' + name), frozen ? 'ok' : 'warn');
    } else if (btn.classList.contains('reset')) {
      toast('已向 ' + name + ' 的绑定手机发送重置链接', 'ok');
    }
  });
  $('#addc-ok').addEventListener('click', () => {
    const val = parseFloat($('#addc-val').value || '0');
    if (!val || val <= 0) { toast('请输入有效的算力值', 'err'); return; }
    if (addcRow) {
      const cell = $('.num.teal', addcRow);
      const cur = parseFloat((cell.textContent || '0').replace(/,/g, '')) || 0;
      cell.textContent = (cur + val).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
      toast('已为 ' + $('#addc-user').textContent + ' 增加 ' + val + ' 算力', 'ok');
    }
    closeModal('modal-addc');
  });

  /* ---------- 账单管理：类型分段筛选 ---------- */
  $$('#bill-tabs button').forEach((b) => {
    b.addEventListener('click', () => {
      $$('#bill-tabs button').forEach((x) => x.classList.remove('on'));
      b.classList.add('on');
      const type = b.dataset.type;
      $$('#bill-table tbody tr').forEach((tr) => {
        tr.style.display = (!type || tr.dataset.type === type) ? '' : 'none';
      });
    });
  });

  /* ---------- 大模型配置：搜索 + 类型筛选 ---------- */
  function filterModels() {
    const kw = ($('#model-search').value || '').trim().toLowerCase();
    const ty = $('#model-type').value;
    $$('#model-table tbody tr').forEach((tr) => {
      const txt = tr.textContent.toLowerCase();
      const okKw = !kw || txt.includes(kw);
      const okTy = !ty || tr.dataset.type === ty;
      tr.style.display = (okKw && okTy) ? '' : 'none';
    });
  }
  $('#model-search').addEventListener('input', filterModels);
  $('#model-type').addEventListener('change', filterModels);
  $('#btn-model-add').addEventListener('click', () => {
    $('#md-name').value = ''; $('#md-ch').value = ''; $('#md-in').value = 80; $('#md-out').value = 300;
    openModal('modal-model');
  });

  /* 模型表：上架开关 + 编辑/调价 */
  $('#model-table').addEventListener('click', (e) => {
    const sw = e.target.closest('.sw');
    if (sw) {
      sw.classList.toggle('on');
      const name = $('td strong', sw.closest('tr')).textContent;
      toast(name + (sw.classList.contains('on') ? ' 已上架' : ' 已下架'), sw.classList.contains('on') ? 'ok' : 'warn');
      return;
    }
    const op = e.target.closest('.op');
    if (!op) return;
    const name = $('td strong', op.closest('tr')).textContent;
    if (op.classList.contains('edit')) toast('打开模型配置：' + name);
    else if (op.classList.contains('price')) toast('打开计费调价：' + name, 'warn');
  });

  /* 接入新模型 → 追加表格行 */
  const typeBadge = { '聊天': 'teal', '图片': 'purple', '视频': 'pink', '音频': 'gold' };
  $('#md-ok').addEventListener('click', () => {
    const name = $('#md-name').value.trim();
    if (!name) { toast('请填写模型名称', 'err'); return; }
    const type = $('#md-type').value;
    const ch = $('#md-ch').value.trim() || 'DE-XX-01';
    const pin = $('#md-in').value || '0';
    const pout = $('#md-out').value || '0';
    const tr = document.createElement('tr');
    tr.dataset.type = type;
    const bc = typeBadge[type] || 'teal';
    const cells = [
      { html: 0, build: (td) => { const s = document.createElement('strong'); s.textContent = name; const em = document.createElement('em'); em.textContent = '自定义接入'; td.append(s, em); } },
      { text: type, badge: bc },
      { text: ch },
      { text: pin },
      { text: pout },
      { text: '0' },
      { text: '—', cls: 'num green' },
    ];
    cells.forEach((c) => {
      const td = document.createElement('td');
      if (c.build) { c.build(td); }
      else if (c.badge) { const b = document.createElement('span'); b.className = 'bdg ' + c.badge; b.textContent = c.text; td.appendChild(b); }
      else { if (c.cls) td.className = c.cls; td.textContent = c.text; }
      tr.appendChild(td);
    });
    // 上架开关
    const tdSw = document.createElement('td');
    const swb = document.createElement('button');
    swb.className = 'sw on';
    tdSw.appendChild(swb);
    tr.appendChild(tdSw);
    // 操作
    const tdOps = document.createElement('td');
    tdOps.className = 'ops';
    ['edit', 'price'].forEach((k) => {
      const b = document.createElement('button');
      b.className = 'op ' + k;
      b.textContent = k === 'edit' ? '编辑' : '调价';
      tdOps.appendChild(b);
    });
    tr.appendChild(tdOps);
    $('#model-table tbody').appendChild(tr);
    closeModal('modal-model');
    toast('模型 ' + name + ' 接入成功并已上架', 'ok');
  });

  /* ---------- 通用开关（系统设置等） ---------- */
  $$('.sw-row .sw').forEach((sw) => {
    sw.addEventListener('click', () => {
      sw.classList.toggle('on');
      const label = sw.closest('.sw-row').querySelector('span').textContent;
      toast(label + (sw.classList.contains('on') ? '：已开启' : '：已关闭'), sw.classList.contains('on') ? 'ok' : 'warn');
    });
  });
  $$('.panel .btn.teal').forEach((b) => {
    b.addEventListener('click', () => {
      const txt = b.textContent.trim();
      if (txt.includes('保存')) toast('平台参数已保存并生效', 'ok');
      else if (txt.includes('公告')) toast('系统公告已发布，前台将弹窗展示', 'ok');
    });
  });

  /* ---------- 智能体 Skill 配置 ---------- */
  // Skill 类型 → 徽章配色
  const SKILL_TYPE_BADGE = {
    '模型调用': 'teal', '联网搜索': 'blue', '知识库检索': 'purple', '代码执行': 'gold',
    '图像处理': 'pink', '数据查询': 'teal', 'HTTP 请求': 'blue', '人工审核': 'red'
  };
  // 可选 Skill 库
  const SKILL_LIB = [
    { id: 'sk_web_search', name: '联网搜索（Web Search）', type: '联网搜索', ico: '🌐', desc: '实时抓取全网搜索结果与热点榜单', cost: 0.5 },
    { id: 'sk_web_extract', name: '网页正文抓取', type: '联网搜索', ico: '📄', desc: '提取指定 URL 网页的正文内容', cost: 0.3 },
    { id: 'sk_goods_db', name: '商品库查询（MySQL）', type: '数据查询', ico: '🗄', desc: '查询平台商品库 SKU、库存与利润率', cost: 0.2 },
    { id: 'sk_vector_kb', name: '向量知识库检索', type: '知识库检索', ico: '📚', desc: '语义检索企业私有知识库文档', cost: 0.4 },
    { id: 'sk_python', name: 'Python 代码执行', type: '代码执行', ico: '🐍', desc: '沙箱运行 Python 计算与数据处理脚本', cost: 0.6 },
    { id: 'sk_img_crop', name: '图片裁剪/压缩', type: '图像处理', ico: '✂', desc: '按目标尺寸裁剪与压缩图片', cost: 0.2 },
    { id: 'sk_ocr', name: '图片 OCR 识别', type: '图像处理', ico: '🔍', desc: '识别图片中的文字与表格信息', cost: 0.3 },
    { id: 'sk_tt_image', name: '调用 TT Image 2 出图', type: '模型调用', ico: '🎨', desc: '文生图 / 图生图，输出高清主图', cost: 3.0 },
    { id: 'sk_gem', name: '调用 GEM 3.7 flash 推理', type: '模型调用', ico: '🧠', desc: '大模型推理与文本生成', cost: 1.0 },
    { id: 'sk_jimeng', name: '调用即梦 3.5 Pro 生成视频', type: '模型调用', ico: '🎬', desc: '文生视频 / 图生视频', cost: 6.0 },
    { id: 'sk_http_logistics', name: '汇率/物流 API 请求', type: 'HTTP 请求', ico: '🔗', desc: '实时汇率换算与物流轨迹查询', cost: 0.1 },
    { id: 'sk_review', name: '敏感内容人工复核', type: '人工审核', ico: '🛡', desc: '命中风控规则时转人工复核', cost: 0.0 }
  ];
  const SKILL_MAP = {};
  SKILL_LIB.forEach((s) => { SKILL_MAP[s.id] = s; });

  // 各智能体已有编排（按标识索引）
  const AGENT_META = {
    'cross-border-picker': { emoji: '🛒', model: 'GEM 3.7 flash', base: 2.0, rounds: 8, timeout: 60, quota: 5000, allow: false, log: true, prompt: '你是跨境电商选品专家，熟悉欧美、东南亚主流平台的选品逻辑、合规要求与物流成本。请结合联网搜索、商品库查询与出图能力，为用户输出可落地的选品建议。', greeting: '你好，告诉我目标市场与品类，我来帮你选品。', skills: [['sk_web_search', 1], ['sk_goods_db', 1], ['sk_tt_image', 1], ['sk_http_logistics', 0]] },
    'short-video-script': { emoji: '🎬', model: 'GEM 3.7 flash', base: 1.5, rounds: 6, timeout: 45, quota: 8000, allow: false, log: true, prompt: '你是短视频脚本创作专家，擅长根据选题生成钩子开头、分镜脚本与口播文案。', greeting: '告诉我账号定位与选题，我来生成爆款脚本。', skills: [['sk_gem', 1], ['sk_web_search', 1], ['sk_web_extract', 1]] },
    'cs-xiaoxing': { emoji: '💬', model: 'GEM 3.7 flash', base: 1.0, rounds: 12, timeout: 30, quota: 50000, allow: false, log: true, prompt: '你是智能客服小星，需依据知识库准确回答用户问题，无法回答时转人工。', greeting: '你好，我是小星，有什么可以帮您？', skills: [['sk_gem', 1], ['sk_vector_kb', 1], ['sk_goods_db', 1], ['sk_http_logistics', 1], ['sk_review', 1], ['sk_ocr', 0]] },
    'poster-batch': { emoji: '🎨', model: 'TT Image 2', base: 3.0, rounds: 4, timeout: 120, quota: 3000, allow: true, log: false, prompt: '你是海报批量生成助手，根据商品信息与模板批量产出多尺寸海报。', greeting: '上传商品图与文案，我来批量出海报。', skills: [['sk_tt_image', 1], ['sk_img_crop', 1]] },
    'fin-report-reader': { emoji: '📊', model: 'GEM 3.7 flash', base: 2.5, rounds: 8, timeout: 90, quota: 1500, allow: false, log: true, prompt: '你是财报解读助手，可 OCR 识别财报、运行财务指标计算并输出解读。', greeting: '上传财报，我来为你解读关键指标。', skills: [['sk_gem', 1], ['sk_ocr', 1], ['sk_python', 1], ['sk_vector_kb', 1], ['sk_web_extract', 0]] },
    'copy-localize': { emoji: '🚀', model: 'GEM 3.7 flash', base: 1.2, rounds: 6, timeout: 45, quota: 6000, allow: false, log: true, prompt: '你是多语言文案本地化专家，可将营销文案地道地翻译并本地化到目标语言。', greeting: '提供原文与目标语言，我来本地化。', skills: [['sk_gem', 1], ['sk_web_search', 1], ['sk_vector_kb', 1]] },
    'picker-legacy-v1': { emoji: '🛒', model: 'GEM 3.5 flash', base: 2.0, rounds: 8, timeout: 60, quota: 0, allow: false, log: false, prompt: '（旧版）跨境选品助手，已被 cross-border-picker 取代。', greeting: '你好，请输入选品需求。', skills: [['sk_web_search', 1], ['sk_goods_db', 1], ['sk_tt_image', 1], ['sk_http_logistics', 1]] }
  };
  const DEFAULT_META = { emoji: '🤖', model: 'GEM 3.7 flash', base: 2.0, rounds: 8, timeout: 60, quota: 5000, allow: false, log: true, prompt: '', greeting: '', skills: [['sk_gem', 1]] };

  const agentListView = $('#agents-list-view');
  const agentDetailView = $('#agents-detail-view');
  let curAgentRow = null;
  let curAgentKey = null;
  let curSkills = [];

  // 列表搜索 + 双筛选
  function filterAgents() {
    const kw = ($('#agent-search').value || '').trim().toLowerCase();
    const ty = $('#agent-type').value;
    const st = $('#agent-status').value;
    $$('#agent-table tbody tr').forEach((tr) => {
      const okKw = !kw || tr.textContent.toLowerCase().includes(kw);
      const okTy = !ty || tr.dataset.type === ty;
      const okSt = !st || tr.dataset.status === st;
      tr.style.display = (okKw && okTy && okSt) ? '' : 'none';
    });
  }
  $('#agent-search').addEventListener('input', filterAgents);
  $('#agent-type').addEventListener('change', filterAgents);
  $('#agent-status').addEventListener('change', filterAgents);
  $('#btn-agent-import').addEventListener('click', () => toast('请上传符合规范的 agent.config.json', 'warn'));

  // 列表行操作
  $('#agent-table').addEventListener('click', (e) => {
    const op = e.target.closest('.op');
    if (!op) return;
    const tr = op.closest('tr');
    const name = $('td strong', tr).textContent;
    if (op.classList.contains('edit')) { openAgentDetail(tr); }
    else if (op.classList.contains('reset')) { toast('打开调试沙箱：' + name); }
    else if (op.classList.contains('addc')) { copyAgentRow(tr, name); }
    else if (op.classList.contains('freeze')) { toggleAgentStatus(tr, name); }
  });

  function toggleAgentStatus(tr, name) {
    const badge = $('.st', tr);
    const btn = $('.op.freeze', tr);
    const offline = badge.textContent.trim() === '已下线';
    badge.textContent = offline ? '已发布' : '已下线';
    badge.className = 'bdg st ' + (offline ? 'teal' : 'red');
    tr.dataset.status = offline ? '已发布' : '已下线';
    btn.textContent = offline ? '下线' : '发布';
    toast(offline ? (name + ' 已发布，C 端立即可调用') : (name + ' 已下线'), offline ? 'ok' : 'warn');
  }

  function copyAgentRow(tr, name) {
    const clone = tr.cloneNode(true);
    $('td strong', clone).textContent = name + ' 副本';
    const badge = $('.st', clone);
    badge.textContent = '草稿';
    badge.className = 'bdg st gold';
    clone.dataset.status = '草稿';
    $('.op.freeze', clone).textContent = '发布';
    $('#agent-table tbody').appendChild(clone);
    toast('已复制智能体：' + name + ' 副本（草稿）', 'ok');
  }

  // 进入详情
  function openAgentDetail(tr) {
    curAgentRow = tr;
    const name = $('td strong', tr).textContent;
    const key = $('td em', tr).textContent;
    const type = tr.dataset.type;
    curAgentKey = key;
    const meta = AGENT_META[key] || DEFAULT_META;
    curSkills = (meta.skills || []).map((s) => ({ id: s[0], enabled: !!s[1] }));

    $('#agent-detail-name').textContent = name;
    const stBadge = $('#agent-detail-status');
    stBadge.textContent = $('.st', tr).textContent;
    stBadge.className = 'bdg st ' + ($('.st', tr).className.match(/(teal|gold|red)/) || ['teal'])[0];
    $('#pg-title').textContent = '智能体 Skill 配置 / ' + name;

    $('#ad-name').value = name;
    $('#ad-key').value = key;
    $('#ad-type').value = type;
    $('#ad-model').value = meta.model;
    $('#ad-prompt').value = meta.prompt;
    $('#ad-greeting').value = meta.greeting;
    $('#ad-base-cost').value = meta.base;
    $('#ad-max-rounds').value = meta.rounds;
    $('#ad-timeout').value = meta.timeout;
    $('#ad-quota').value = meta.quota;
    $$('#ad-emoji .emo').forEach((b) => b.classList.toggle('on', b.dataset.emo === meta.emoji));
    const sws = $$('.agent-detail-grid .sw-row .sw');
    if (sws[0]) sws[0].classList.toggle('on', meta.allow);
    if (sws[1]) sws[1].classList.toggle('on', meta.log);

    renderSkills();
    agentListView.classList.add('hidden');
    agentDetailView.classList.remove('hidden');
    $('#pg-agents').scrollTop = 0;
  }

  function showAgentList() {
    agentDetailView.classList.add('hidden');
    agentListView.classList.remove('hidden');
    if ($('#pg-title').textContent.indexOf(' / ') > -1) $('#pg-title').textContent = '智能体 Skill 配置';
  }
  $('#agent-back').addEventListener('click', showAgentList);

  // 渲染 Skill 列表
  function renderSkills() {
    const list = $('#ad-skill-list');
    list.innerHTML = '';
    curSkills.forEach((s, idx) => {
      const lib = SKILL_MAP[s.id] || { name: s.id, type: '其他', ico: '🧩', desc: '', cost: 0 };
      const bc = SKILL_TYPE_BADGE[lib.type] || 'teal';
      const item = document.createElement('div');
      item.className = 'skill-item' + (s.enabled ? '' : ' off');
      item.dataset.id = s.id;
      item.innerHTML =
        '<span class="drag">⣿</span>' +
        '<span class="sk-ico">' + lib.ico + '</span>' +
        '<span class="sk-main"><strong>' + lib.name + '</strong>' +
        '<em><span class="bdg ' + bc + '">' + lib.type + '</span>' + lib.cost.toFixed(1) + ' 算力/次</em></span>' +
        '<span class="sk-ops">' +
        '<button class="sw' + (s.enabled ? ' on' : '') + '" title="启用/停用"></button>' +
        '<button class="sk-btn cfg" title="展开配置">⚙</button>' +
        '<button class="sk-btn up" title="上移">▲</button>' +
        '<button class="sk-btn down" title="下移">▼</button>' +
        '<button class="sk-btn del" title="删除">✕</button>' +
        '</span>';
      list.appendChild(item);
    });
    const enabledCount = curSkills.filter((s) => s.enabled).length;
    $('#ad-skill-count').textContent = curSkills.length + ' 个 Skill · ' + enabledCount + ' 启用';
    const sum = curSkills.filter((s) => s.enabled).reduce((a, s) => a + ((SKILL_MAP[s.id] || {}).cost || 0), 0);
    $('#ad-skill-cost').textContent = sum.toFixed(1) + ' 算力 / 次';
  }

  // Skill 列表操作（事件委托）
  $('#ad-skill-list').addEventListener('click', (e) => {
    const item = e.target.closest('.skill-item');
    if (!item) return;
    const id = item.dataset.id;
    const idx = curSkills.findIndex((s) => s.id === id);
    if (idx < 0) return;
    const lib = SKILL_MAP[id];
    if (e.target.closest('.sw')) {
      curSkills[idx].enabled = !curSkills[idx].enabled;
      renderSkills();
      toast('Skill「' + lib.name + '」' + (curSkills[idx].enabled ? '已启用' : '已停用'), curSkills[idx].enabled ? 'ok' : 'warn');
    } else if (e.target.closest('.cfg')) {
      toast('展开 Skill 配置：' + lib.name);
    } else if (e.target.closest('.up')) {
      if (idx === 0) { toast('已是第一个 Skill', 'warn'); return; }
      [curSkills[idx - 1], curSkills[idx]] = [curSkills[idx], curSkills[idx - 1]];
      renderSkills();
    } else if (e.target.closest('.down')) {
      if (idx === curSkills.length - 1) { toast('已是最后一个 Skill', 'warn'); return; }
      [curSkills[idx + 1], curSkills[idx]] = [curSkills[idx], curSkills[idx + 1]];
      renderSkills();
    } else if (e.target.closest('.del')) {
      curSkills.splice(idx, 1);
      renderSkills();
      toast('已移除 Skill：' + lib.name, 'warn');
    }
  });

  // emoji 选择
  $('#ad-emoji').addEventListener('click', (e) => {
    const b = e.target.closest('.emo');
    if (!b) return;
    $$('#ad-emoji .emo').forEach((x) => x.classList.remove('on'));
    b.classList.add('on');
  });

  // 保存 / 发布
  $('#agent-save').addEventListener('click', () => {
    if (curAgentKey && AGENT_META[curAgentKey]) {
      AGENT_META[curAgentKey].skills = curSkills.map((s) => [s.id, s.enabled ? 1 : 0]);
    }
    toast('智能体编排已保存', 'ok');
  });
  $('#agent-publish').addEventListener('click', () => {
    if (curSkills.length === 0) { toast('请至少添加一个 Skill', 'err'); return; }
    const name = $('#agent-detail-name').textContent;
    const stBadge = $('#agent-detail-status');
    stBadge.textContent = '已发布';
    stBadge.className = 'bdg st teal';
    if (curAgentRow) {
      const rb = $('.st', curAgentRow);
      rb.textContent = '已发布';
      rb.className = 'bdg st teal';
      curAgentRow.dataset.status = '已发布';
      $('.op.freeze', curAgentRow).textContent = '下线';
    }
    toast(name + ' 已发布，C 端立即可调用', 'ok');
  });

  // 添加 Skill 弹窗
  function renderSkillPicker() {
    const box = $('#skill-picker');
    box.innerHTML = '';
    SKILL_LIB.forEach((s) => {
      const added = curSkills.some((c) => c.id === s.id);
      const bc = SKILL_TYPE_BADGE[s.type] || 'teal';
      const card = document.createElement('div');
      card.className = 'skill-card' + (added ? ' added' : '');
      card.dataset.id = s.id;
      card.dataset.type = s.type;
      card.innerHTML =
        '<div class="sc-top"><span class="sc-ico">' + s.ico + '</span><strong>' + s.name + '</strong></div>' +
        '<span class="bdg ' + bc + '">' + s.type + '</span>' +
        '<p>' + s.desc + '</p>' +
        '<button class="sc-add">' + (added ? '已添加' : '添加') + '</button>';
      box.appendChild(card);
    });
    filterSkillPicker();
  }
  function filterSkillPicker() {
    const kw = ($('#skill-search').value || '').trim().toLowerCase();
    const ty = $('#skill-type').value;
    $$('#skill-picker .skill-card').forEach((c) => {
      const okKw = !kw || c.textContent.toLowerCase().includes(kw);
      const okTy = !ty || c.dataset.type === ty;
      c.style.display = (okKw && okTy) ? '' : 'none';
    });
  }
  $('#skill-search').addEventListener('input', filterSkillPicker);
  $('#skill-type').addEventListener('change', filterSkillPicker);
  $('#btn-add-skill').addEventListener('click', () => { renderSkillPicker(); openModal('modal-skill'); });
  $('#skill-picker').addEventListener('click', (e) => {
    const card = e.target.closest('.skill-card');
    if (!card || card.classList.contains('added')) return;
    const id = card.dataset.id;
    curSkills.push({ id: id, enabled: true });
    card.classList.add('added');
    $('.sc-add', card).textContent = '已添加';
    renderSkills();
    toast('已添加 Skill：' + SKILL_MAP[id].name, 'ok');
  });

  // 新建智能体
  $('#btn-agent-add').addEventListener('click', () => {
    $('#ag-name').value = ''; $('#ag-key').value = ''; $('#ag-desc').value = ''; $('#ag-type').value = '营销';
    openModal('modal-agent');
  });
  $('#ag-ok').addEventListener('click', () => {
    const name = $('#ag-name').value.trim();
    if (!name) { toast('请填写智能体名称', 'err'); return; }
    const key = ($('#ag-key').value.trim() || 'agent-' + Date.now().toString().slice(-6));
    const type = $('#ag-type').value;
    const tr = document.createElement('tr');
    tr.dataset.type = type;
    tr.dataset.status = '草稿';
    const catBadge = { '客服': 'blue', '营销': 'teal', '设计': 'pink', '数据分析': 'purple', '其他': 'gold' }[type] || 'teal';
    tr.innerHTML =
      '<td><strong>' + name + '</strong><em>' + key + '</em></td>' +
      '<td><span class="bdg ' + catBadge + '">' + type + '</span></td>' +
      '<td>1</td><td>0</td><td>0</td><td>—</td><td><b class="num">—</b></td>' +
      '<td><span class="bdg gold st">草稿</span></td>' +
      '<td class="ops"><button class="op edit">配置</button><button class="op reset">调试</button><button class="op addc">复制</button><button class="op freeze">发布</button></td>';
    $('#agent-table tbody').appendChild(tr);
    AGENT_META[key] = Object.assign({}, DEFAULT_META, { skills: [] });
    closeModal('modal-agent');
    filterAgents();
    toast('智能体「' + name + '」创建成功（草稿）', 'ok');
  });

  /* ---------- 分页按钮视觉 ---------- */
  $$('.pg-btns').forEach((grp) => {
    grp.addEventListener('click', (e) => {
      const b = e.target.closest('button');
      if (!b || b.textContent === '«' || b.textContent === '»' || b.textContent === '…') return;
      $$('button', grp).forEach((x) => x.classList.remove('on'));
      b.classList.add('on');
    });
  });
})();
