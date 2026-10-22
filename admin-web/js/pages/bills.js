/* 账单管理：mock/接口列表 + 类型分段筛选 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const $$ = global.AdminUtil.$$;
  const toast = global.AdminUtil.toast;
  const escape = global.AdminUtil.escapeHtml;
  const formatDateTime = global.AdminUtil.formatDateTime;

  const typeMeta = {
    RECHARGE: { label: '充值', badge: 'teal' },
    CONSUME: { label: '消耗', badge: 'gold' },
    REFUND: { label: '退款', badge: 'red' },
  };
  const statusMeta = {
    SUCCESS: { label: '成功', badge: 'teal' },
    PENDING: { label: '处理中', badge: 'gold' },
    FAILED: { label: '失败', badge: 'red' },
  };

  function renderBills(rows) {
    const table = $('#bill-table');
    if (!table || !Array.isArray(rows)) return;
    const body = $('tbody', table);
    body.innerHTML = rows
      .map((bill) => {
        const type = typeMeta[bill.type] || {
          label: bill.typeLabel || bill.type || '其他',
          badge: 'teal',
        };
        const status = statusMeta[bill.status] || {
          label: bill.statusLabel || bill.status || '—',
          badge: 'teal',
        };
        const amount = Number(bill.amount || 0).toLocaleString('zh-CN', {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        });
        const delta = Number(bill.creditsDelta || 0);
        const amountText =
          bill.type === 'CONSUME' || bill.type === 'REFUND'
            ? '-¥ ' + amount
            : '¥ ' + amount;
        return (
          '<tr data-type="' +
          escape(type.label) +
          '">' +
          '<td>' +
          escape(bill.orderNo || '—') +
          '</td>' +
          '<td>' +
          escape(bill.userName || '—') +
          '</td>' +
          '<td><span class="bdg ' +
          type.badge +
          '">' +
          escape(type.label) +
          '</span></td>' +
          '<td>' +
          escape(amountText) +
          '</td>' +
          '<td class="' +
          (delta >= 0 ? 'pos' : 'neg') +
          '">' +
          (delta >= 0 ? '+' : '') +
          escape(delta.toFixed(2)) +
          '</td>' +
          '<td>' +
          escape(bill.channel || '—') +
          '</td>' +
          '<td><span class="bdg ' +
          status.badge +
          '">' +
          escape(status.label) +
          '</span></td>' +
          '<td>' +
          escape(formatDateTime(bill.createdAt)) +
          '</td>' +
          '</tr>'
        );
      })
      .join('');
  }

  function applyFilter(type) {
    $$('#bill-table tbody tr').forEach((row) => {
      row.style.display = !type || row.dataset.type === type ? '' : 'none';
    });
  }

  async function load() {
    try {
      const data = await global.AdminApi.get('/bills?page=1&pageSize=10', {
        mockKey: 'bills',
      });
      if (!data) return;
      if (Array.isArray(data.list)) renderBills(data.list);
      const summaryEl = $('#pg-bills .pager > span');
      if (summaryEl && data.summary) {
        summaryEl.textContent =
          '共 ' +
          Number(data.summary.count || 0).toLocaleString('zh-CN') +
          ' 笔 · 合计 +¥' +
          Number(data.summary.totalRecharge || 0).toLocaleString('zh-CN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          }) +
          ' / -¥' +
          Number(data.summary.totalConsume || 0).toLocaleString('zh-CN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          });
      }
    } catch (error) {
      // api.js 已提示
    }
  }

  function init() {
    $$('#bill-tabs button').forEach((button) => {
      button.addEventListener('click', () => {
        $$('#bill-tabs button').forEach((item) =>
          item.classList.remove('on'),
        );
        button.classList.add('on');
        applyFilter(button.dataset.type);
      });
    });
    const exportButton = $('#pg-bills .toolbar .btn.ghost');
    if (exportButton) {
      exportButton.addEventListener('click', () =>
        toast('对账单导出任务已提交，完成后将通知下载', 'ok'),
      );
    }
  }

  global.AdminPages.bills = { init, load };
})(window);
