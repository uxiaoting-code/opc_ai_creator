/* 智能体 Skill 配置：列表 + 编排详情 + Skill 库 + 新建/复制/发布 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const $$ = global.AdminUtil.$$;
  const toast = global.AdminUtil.toast;
  const escape = global.AdminUtil.escapeHtml;

  const SKILL_TYPE_BADGE = {
    模型调用: 'teal',
    联网搜索: 'blue',
    知识库检索: 'purple',
    代码执行: 'gold',
    图像处理: 'pink',
    数据查询: 'teal',
    'HTTP 请求': 'blue',
    人工审核: 'red',
  };

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
    { id: 'sk_review', name: '敏感内容人工复核', type: '人工审核', ico: '🛡', desc: '命中风控规则时转人工复核', cost: 0.0 },
  ];

  const SKILL_MAP = {};
  SKILL_LIB.forEach((skill) => {
    SKILL_MAP[skill.id] = skill;
  });

  const AGENT_META = {
    'cross-border-picker': { emoji: '🛒', model: 'GEM 3.7 flash', base: 2.0, rounds: 8, timeout: 60, quota: 5000, allow: false, log: true, prompt: '你是跨境电商选品专家，熟悉欧美、东南亚主流平台的选品逻辑、合规要求与物流成本。请结合联网搜索、商品库查询与出图能力，为用户输出可落地的选品建议。', greeting: '你好，告诉我目标市场与品类，我来帮你选品。', skills: [['sk_web_search', 1], ['sk_goods_db', 1], ['sk_tt_image', 1], ['sk_http_logistics', 0]] },
    'short-video-script': { emoji: '🎬', model: 'GEM 3.7 flash', base: 1.5, rounds: 6, timeout: 45, quota: 8000, allow: false, log: true, prompt: '你是短视频脚本创作专家，擅长根据选题生成钩子开头、分镜脚本与口播文案。', greeting: '告诉我账号定位与选题，我来生成爆款脚本。', skills: [['sk_gem', 1], ['sk_web_search', 1], ['sk_web_extract', 1]] },
    'cs-xiaoxing': { emoji: '💬', model: 'GEM 3.7 flash', base: 1.0, rounds: 12, timeout: 30, quota: 50000, allow: false, log: true, prompt: '你是智能客服小星，需依据知识库准确回答用户问题，无法回答时转人工。', greeting: '你好，我是小星，有什么可以帮您？', skills: [['sk_gem', 1], ['sk_vector_kb', 1], ['sk_goods_db', 1], ['sk_http_logistics', 1], ['sk_review', 1], ['sk_ocr', 0]] },
    'poster-batch': { emoji: '🎨', model: 'TT Image 2', base: 3.0, rounds: 4, timeout: 120, quota: 3000, allow: true, log: false, prompt: '你是海报批量生成助手，根据商品信息与模板批量产出多尺寸海报。', greeting: '上传商品图与文案，我来批量出海报。', skills: [['sk_tt_image', 1], ['sk_img_crop', 1]] },
    'fin-report-reader': { emoji: '📊', model: 'GEM 3.7 flash', base: 2.5, rounds: 8, timeout: 90, quota: 1500, allow: false, log: true, prompt: '你是财报解读助手，可 OCR 识别财报、运行财务指标计算并输出解读。', greeting: '上传财报，我来为你解读关键指标。', skills: [['sk_gem', 1], ['sk_ocr', 1], ['sk_python', 1], ['sk_vector_kb', 1], ['sk_web_extract', 0]] },
    'copy-localize': { emoji: '🚀', model: 'GEM 3.7 flash', base: 1.2, rounds: 6, timeout: 45, quota: 6000, allow: false, log: true, prompt: '你是多语言文案本地化专家，可将营销文案地道地翻译并本地化到目标语言。', greeting: '提供原文与目标语言，我来本地化。', skills: [['sk_gem', 1], ['sk_web_search', 1], ['sk_vector_kb', 1]] },
    'picker-legacy-v1': { emoji: '🛒', model: 'GEM 3.5 flash', base: 2.0, rounds: 8, timeout: 60, quota: 0, allow: false, log: false, prompt: '（旧版）跨境选品助手，已被 cross-border-picker 取代。', greeting: '你好，请输入选品需求。', skills: [['sk_web_search', 1], ['sk_goods_db', 1], ['sk_tt_image', 1], ['sk_http_logistics', 1]] },
  };

  const DEFAULT_META = {
    emoji: '🤖',
    model: 'GEM 3.7 flash',
    base: 2.0,
    rounds: 8,
    timeout: 60,
    quota: 5000,
    allow: false,
    log: true,
    prompt: '',
    greeting: '',
    skills: [['sk_gem', 1]],
  };

  let curAgentRow = null;
  let curAgentKey = null;
  let curSkills = [];

  function filterAgents() {
    const keyword = ($('#agent-search').value || '').trim().toLowerCase();
    const type = $('#agent-type').value;
    const status = $('#agent-status').value;
    $$('#agent-table tbody tr').forEach((row) => {
      const okKeyword =
        !keyword || row.textContent.toLowerCase().includes(keyword);
      const okType = !type || row.dataset.type === type;
      const okStatus = !status || row.dataset.status === status;
      row.style.display = okKeyword && okType && okStatus ? '' : 'none';
    });
  }

  function toggleAgentStatus(row, name) {
    const badge = $('.st', row);
    const button = $('.op.freeze', row);
    const offline = badge.textContent.trim() === '已下线';
    badge.textContent = offline ? '已发布' : '已下线';
    badge.className = 'bdg st ' + (offline ? 'teal' : 'red');
    row.dataset.status = offline ? '已发布' : '已下线';
    button.textContent = offline ? '下线' : '发布';
    toast(
      offline ? name + ' 已发布，C 端立即可调用' : name + ' 已下线',
      offline ? 'ok' : 'warn',
    );
  }

  function copyAgentRow(row, name) {
    const clone = row.cloneNode(true);
    $('td strong', clone).textContent = name + ' 副本';
    const badge = $('.st', clone);
    badge.textContent = '草稿';
    badge.className = 'bdg st gold';
    clone.dataset.status = '草稿';
    $('.op.freeze', clone).textContent = '发布';
    $('#agent-table tbody').appendChild(clone);
    toast('已复制智能体：' + name + ' 副本（草稿）', 'ok');
  }

  function showAgentList() {
    $('#agents-detail-view').classList.add('hidden');
    $('#agents-list-view').classList.remove('hidden');
    if ($('#pg-title').textContent.indexOf(' / ') > -1) {
      $('#pg-title').textContent = '智能体 Skill 配置';
    }
  }

  function renderSkills() {
    const list = $('#ad-skill-list');
    if (!list) return;
    list.innerHTML = '';
    curSkills.forEach((skill) => {
      const lib = SKILL_MAP[skill.id] || {
        name: skill.id,
        type: '其他',
        ico: '🧩',
        desc: '',
        cost: 0,
      };
      const badge = SKILL_TYPE_BADGE[lib.type] || 'teal';
      const item = document.createElement('div');
      item.className = 'skill-item' + (skill.enabled ? '' : ' off');
      item.dataset.id = skill.id;
      item.innerHTML =
        '<span class="drag">⣿</span>' +
        '<span class="sk-ico">' + escape(lib.ico) + '</span>' +
        '<span class="sk-main"><strong>' + escape(lib.name) + '</strong>' +
        '<em><span class="bdg ' + badge + '">' + escape(lib.type) + '</span>' +
        Number(lib.cost).toFixed(1) + ' 算力/次</em></span>' +
        '<span class="sk-ops">' +
        '<button class="sw' + (skill.enabled ? ' on' : '') + '" title="启用/停用"></button>' +
        '<button class="sk-btn cfg" title="展开配置">⚙</button>' +
        '<button class="sk-btn up" title="上移">▲</button>' +
        '<button class="sk-btn down" title="下移">▼</button>' +
        '<button class="sk-btn del" title="删除">✕</button>' +
        '</span>';
      list.appendChild(item);
    });
    const enabledCount = curSkills.filter((skill) => skill.enabled).length;
    $('#ad-skill-count').textContent =
      curSkills.length + ' 个 Skill · ' + enabledCount + ' 启用';
    const sum = curSkills
      .filter((skill) => skill.enabled)
      .reduce((total, skill) => total + ((SKILL_MAP[skill.id] || {}).cost || 0), 0);
    $('#ad-skill-cost').textContent = sum.toFixed(1) + ' 算力 / 次';
  }

  function openAgentDetail(row) {
    curAgentRow = row;
    const name = $('td strong', row).textContent;
    const key = $('td em', row).textContent;
    const type = row.dataset.type;
    curAgentKey = key;
    const meta = AGENT_META[key] || DEFAULT_META;
    curSkills = (meta.skills || []).map((item) => ({
      id: item[0],
      enabled: !!item[1],
    }));

    $('#agent-detail-name').textContent = name;
    const statusBadge = $('#agent-detail-status');
    const sourceBadge = $('.st', row);
    statusBadge.textContent = sourceBadge.textContent;
    statusBadge.className =
      'bdg st ' + (sourceBadge.className.match(/(teal|gold|red)/) || ['teal'])[0];
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
    $$('#ad-emoji .emo').forEach((button) =>
      button.classList.toggle('on', button.dataset.emo === meta.emoji),
    );
    const toggles = $$('.agent-detail-grid .sw-row .sw');
    if (toggles[0]) toggles[0].classList.toggle('on', meta.allow);
    if (toggles[1]) toggles[1].classList.toggle('on', meta.log);

    renderSkills();
    $('#agents-list-view').classList.add('hidden');
    $('#agents-detail-view').classList.remove('hidden');
    $('#pg-agents').scrollTop = 0;
  }

  function renderSkillPicker() {
    const box = $('#skill-picker');
    if (!box) return;
    box.innerHTML = '';
    SKILL_LIB.forEach((skill) => {
      const added = curSkills.some((item) => item.id === skill.id);
      const badge = SKILL_TYPE_BADGE[skill.type] || 'teal';
      const card = document.createElement('div');
      card.className = 'skill-card' + (added ? ' added' : '');
      card.dataset.id = skill.id;
      card.dataset.type = skill.type;
      card.innerHTML =
        '<div class="sc-top"><span class="sc-ico">' + escape(skill.ico) + '</span><strong>' +
        escape(skill.name) + '</strong></div>' +
        '<span class="bdg ' + badge + '">' + escape(skill.type) + '</span>' +
        '<p>' + escape(skill.desc) + '</p>' +
        '<button class="sc-add">' + (added ? '已添加' : '添加') + '</button>';
      box.appendChild(card);
    });
    filterSkillPicker();
  }

  function filterSkillPicker() {
    const keyword = ($('#skill-search').value || '').trim().toLowerCase();
    const type = $('#skill-type').value;
    $$('#skill-picker .skill-card').forEach((card) => {
      const okKeyword =
        !keyword || card.textContent.toLowerCase().includes(keyword);
      const okType = !type || card.dataset.type === type;
      card.style.display = okKeyword && okType ? '' : 'none';
    });
  }

  function init() {
    $('#agent-search').addEventListener('input', filterAgents);
    $('#agent-type').addEventListener('change', filterAgents);
    $('#agent-status').addEventListener('change', filterAgents);
    $('#btn-agent-import').addEventListener('click', () =>
      toast('请上传符合规范的 agent.config.json', 'warn'),
    );

    $('#agent-table').addEventListener('click', (event) => {
      const action = event.target.closest('.op');
      if (!action) return;
      const row = action.closest('tr');
      const name = $('td strong', row).textContent;
      if (action.classList.contains('edit')) openAgentDetail(row);
      else if (action.classList.contains('reset')) toast('打开调试沙箱：' + name);
      else if (action.classList.contains('addc')) copyAgentRow(row, name);
      else if (action.classList.contains('freeze')) toggleAgentStatus(row, name);
    });

    $('#agent-back').addEventListener('click', showAgentList);

    $('#ad-skill-list').addEventListener('click', (event) => {
      const item = event.target.closest('.skill-item');
      if (!item) return;
      const id = item.dataset.id;
      const index = curSkills.findIndex((skill) => skill.id === id);
      if (index < 0) return;
      const lib = SKILL_MAP[id];
      if (event.target.closest('.sw')) {
        curSkills[index].enabled = !curSkills[index].enabled;
        renderSkills();
        toast(
          'Skill「' + lib.name + '」' +
            (curSkills[index].enabled ? '已启用' : '已停用'),
          curSkills[index].enabled ? 'ok' : 'warn',
        );
      } else if (event.target.closest('.cfg')) {
        toast('展开 Skill 配置：' + lib.name);
      } else if (event.target.closest('.up')) {
        if (index === 0) return toast('已是第一个 Skill', 'warn');
        [curSkills[index - 1], curSkills[index]] = [
          curSkills[index],
          curSkills[index - 1],
        ];
        renderSkills();
      } else if (event.target.closest('.down')) {
        if (index === curSkills.length - 1) return toast('已是最后一个 Skill', 'warn');
        [curSkills[index + 1], curSkills[index]] = [
          curSkills[index],
          curSkills[index + 1],
        ];
        renderSkills();
      } else if (event.target.closest('.del')) {
        curSkills.splice(index, 1);
        renderSkills();
        toast('已移除 Skill：' + lib.name, 'warn');
      }
    });

    $('#ad-emoji').addEventListener('click', (event) => {
      const button = event.target.closest('.emo');
      if (!button) return;
      $$('#ad-emoji .emo').forEach((item) => item.classList.remove('on'));
      button.classList.add('on');
    });

    $('#agent-save').addEventListener('click', () => {
      if (curAgentKey && AGENT_META[curAgentKey]) {
        AGENT_META[curAgentKey].skills = curSkills.map((skill) => [
          skill.id,
          skill.enabled ? 1 : 0,
        ]);
      }
      toast('智能体编排已保存', 'ok');
    });

    $('#agent-publish').addEventListener('click', () => {
      if (curSkills.length === 0) {
        toast('请至少添加一个 Skill', 'err');
        return;
      }
      const name = $('#agent-detail-name').textContent;
      const badge = $('#agent-detail-status');
      badge.textContent = '已发布';
      badge.className = 'bdg st teal';
      if (curAgentRow) {
        const rowBadge = $('.st', curAgentRow);
        rowBadge.textContent = '已发布';
        rowBadge.className = 'bdg st teal';
        curAgentRow.dataset.status = '已发布';
        $('.op.freeze', curAgentRow).textContent = '下线';
      }
      toast(name + ' 已发布，C 端立即可调用', 'ok');
    });

    $('#skill-search').addEventListener('input', filterSkillPicker);
    $('#skill-type').addEventListener('change', filterSkillPicker);
    $('#btn-add-skill').addEventListener('click', () => {
      renderSkillPicker();
      global.AdminApp.openModal('modal-skill');
    });
    $('#skill-picker').addEventListener('click', (event) => {
      const card = event.target.closest('.skill-card');
      if (!card || card.classList.contains('added')) return;
      const id = card.dataset.id;
      curSkills.push({ id, enabled: true });
      card.classList.add('added');
      $('.sc-add', card).textContent = '已添加';
      renderSkills();
      toast('已添加 Skill：' + SKILL_MAP[id].name, 'ok');
    });

    $('#btn-agent-add').addEventListener('click', () => {
      $('#ag-name').value = '';
      $('#ag-key').value = '';
      $('#ag-desc').value = '';
      $('#ag-type').value = '营销';
      global.AdminApp.openModal('modal-agent');
    });
    $('#ag-ok').addEventListener('click', () => {
      const name = $('#ag-name').value.trim();
      if (!name) {
        toast('请填写智能体名称', 'err');
        return;
      }
      const key = $('#ag-key').value.trim() || 'agent-' + Date.now().toString().slice(-6);
      const type = $('#ag-type').value;
      const categoryBadge =
        { 客服: 'blue', 营销: 'teal', 设计: 'pink', 数据分析: 'purple', 其他: 'gold' }[type] || 'teal';
      const row = document.createElement('tr');
      row.dataset.type = type;
      row.dataset.status = '草稿';
      row.innerHTML =
        '<td><strong>' + escape(name) + '</strong><em>' + escape(key) + '</em></td>' +
        '<td><span class="bdg ' + categoryBadge + '">' + escape(type) + '</span></td>' +
        '<td>1</td><td>0</td><td>0</td><td>—</td><td><b class="num">—</b></td>' +
        '<td><span class="bdg gold st">草稿</span></td>' +
        '<td class="ops"><button class="op edit">配置</button><button class="op reset">调试</button><button class="op addc">复制</button><button class="op freeze">发布</button></td>';
      $('#agent-table tbody').appendChild(row);
      AGENT_META[key] = Object.assign({}, DEFAULT_META, { skills: [] });
      global.AdminApp.closeModal('modal-agent');
      filterAgents();
      toast('智能体「' + name + '」创建成功（草稿）', 'ok');
    });
  }

  global.AdminPages.agents = { init, load: () => {}, showList: showAgentList };
})(window);
