/* 大模型配置：mock/接口列表 + 搜索 + 上架 + 接入新模型 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const $$ = global.AdminUtil.$$;
  const toast = global.AdminUtil.toast;
  const escape = global.AdminUtil.escapeHtml;

  const typeMeta = {
    CHAT: { label: '聊天', badge: 'teal' },
    IMAGE: { label: '图片', badge: 'purple' },
    VIDEO: { label: '视频', badge: 'pink' },
    AUDIO: { label: '音频', badge: 'gold' },
  };
  const labelToType = {
    聊天: 'CHAT',
    图片: 'IMAGE',
    视频: 'VIDEO',
    音频: 'AUDIO',
  };

  function priceText(value) {
    const n = Number(value);
    return Number.isFinite(n) ? n.toFixed(2) : '—';
  }

  function renderModels(rows) {
    const table = $('#model-table');
    if (!table || !Array.isArray(rows)) return;
    const body = $('tbody', table);
    body.innerHTML = rows
      .map((model) => {
        const type = typeMeta[model.type] || {
          label: model.typeLabel || model.type || '其他',
          badge: 'teal',
        };
        const online = !!model.online;
        const successRate =
          model.successRate == null
            ? '—'
            : Number(model.successRate).toFixed(1) + '%';
        return (
          '<tr data-type="' +
          escape(type.label) +
          '">' +
          '<td><strong>' +
          escape(model.name || '未命名模型') +
          '</strong><em>' +
          escape(model.vendor || '自定义接入') +
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
          escape(priceText(model.inputPrice)) +
          '</td>' +
          '<td>' +
          escape(priceText(model.outputPrice)) +
          '</td>' +
          '<td>' +
          Number(model.todayCalls || 0).toLocaleString('zh-CN') +
          '</td>' +
          '<td><b class="num green">' +
          escape(successRate) +
          '</b></td>' +
          '<td><button class="sw' +
          (online ? ' on' : '') +
          '"></button></td>' +
          '<td class="ops"><button class="op edit">编辑</button><button class="op price">调价</button></td>' +
          '</tr>'
        );
      })
      .join('');
    filterModels();
  }

  function filterModels() {
    const keyword = ($('#model-search').value || '').trim().toLowerCase();
    const type = $('#model-type').value;
    $$('#model-table tbody tr').forEach((row) => {
      const okKeyword =
        !keyword || row.textContent.toLowerCase().includes(keyword);
      const okType = !type || row.dataset.type === type;
      row.style.display = okKeyword && okType ? '' : 'none';
    });
  }

  async function load() {
    try {
      const data = await global.AdminApi.get(
        '/providers?page=1&pageSize=10',
        { mockKey: 'models' },
      );
      if (data && Array.isArray(data.list)) renderModels(data.list);
    } catch (error) {
      // api.js 已提示
    }
  }

  function init() {
    $('#model-search').addEventListener('input', filterModels);
    $('#model-type').addEventListener('change', filterModels);

    $('#btn-model-add').addEventListener('click', () => {
      $('#md-name').value = '';
      $('#md-ch').value = '';
      $('#md-in').value = 80;
      $('#md-out').value = 300;
      global.AdminApp.openModal('modal-model');
    });

    $('#model-table').addEventListener('click', (event) => {
      const switchButton = event.target.closest('.sw');
      if (switchButton) {
        switchButton.classList.toggle('on');
        const name = $('td strong', switchButton.closest('tr')).textContent;
        toast(
          name + (switchButton.classList.contains('on') ? ' 已上架' : ' 已下架'),
          switchButton.classList.contains('on') ? 'ok' : 'warn',
        );
        return;
      }
      const action = event.target.closest('.op');
      if (!action) return;
      const name = $('td strong', action.closest('tr')).textContent;
      if (action.classList.contains('edit')) {
        toast('打开模型配置：' + name);
      } else if (action.classList.contains('price')) {
        toast('打开计费调价：' + name, 'warn');
      }
    });

    $('#md-ok').addEventListener('click', () => {
      const name = $('#md-name').value.trim();
      if (!name) {
        toast('请填写模型名称', 'err');
        return;
      }
      const label = $('#md-type').value;
      const type = labelToType[label] || label;
      const channel = $('#md-ch').value.trim() || 'DE-XX-01';
      const inputPrice = $('#md-in').value || '0';
      const outputPrice = $('#md-out').value || '0';
      const meta = typeMeta[type] || { label, badge: 'teal' };
      const row = document.createElement('tr');
      row.dataset.type = meta.label;
      row.innerHTML =
        '<td><strong>' +
        escape(name) +
        '</strong><em>自定义接入</em></td>' +
        '<td><span class="bdg ' +
        meta.badge +
        '">' +
        escape(meta.label) +
        '</span></td>' +
        '<td>' +
        escape(channel) +
        '</td>' +
        '<td>' +
        escape(inputPrice) +
        '</td>' +
        '<td>' +
        escape(outputPrice) +
        '</td>' +
        '<td>0</td>' +
        '<td><b class="num green">—</b></td>' +
        '<td><button class="sw on"></button></td>' +
        '<td class="ops"><button class="op edit">编辑</button><button class="op price">调价</button></td>';
      $('#model-table tbody').appendChild(row);
      global.AdminApp.closeModal('modal-model');
      filterModels();
      toast('模型 ' + name + ' 接入成功并已上架', 'ok');
    });
  }

  global.AdminPages.models = { init, load };
})(window);
