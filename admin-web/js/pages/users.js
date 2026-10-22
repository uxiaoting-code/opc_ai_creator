/* 用户管理：mock/接口列表 + 搜索 + 加算力 + 冻结 + 重置密码 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const $$ = global.AdminUtil.$$;
  const toast = global.AdminUtil.toast;
  const escape = global.AdminUtil.escapeHtml;
  const formatCredits = global.AdminUtil.formatCredits;
  const formatDate = global.AdminUtil.formatDate;
  const formatDateTime = global.AdminUtil.formatDateTime;

  let userTable = null;
  let addcRow = null;

  function filterUsers() {
    if (!userTable) return;
    const keyword = ($('#user-search').value || '').trim().toLowerCase();
    const status = $('#user-status').value;
    $$('#user-table tbody tr').forEach((row) => {
      const text = row.textContent.toLowerCase();
      const badge = $('.st', row);
      const rowStatus = badge ? badge.textContent.trim() : '';
      const okKeyword = !keyword || text.includes(keyword);
      const okStatus = !status || rowStatus === status;
      row.style.display = okKeyword && okStatus ? '' : 'none';
    });
  }

  function renderUsers(rows) {
    if (!userTable || !Array.isArray(rows)) return;
    const body = $('tbody', userTable);
    body.innerHTML = rows
      .map((user, index) => {
        const nickname = user.nickname || user.username || '未命名';
        const initial = String(nickname).slice(0, 1);
        const active = Number(user.status) === 1;
        const statusLabel = user.statusLabel || (active ? '正常' : '冻结');
        const avatarClass = 'a' + ((index % 6) + 1);
        const credits = Number(user.credits || 0).toLocaleString('zh-CN');
        const spent = Number(user.totalSpent || 0).toLocaleString('zh-CN', {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        });
        return (
          '<tr data-user-id="' +
          escape(user.id) +
          '">' +
          '<td>' +
          escape(user.id) +
          '</td>' +
          '<td><span class="u-cell"><i class="u-ava ' +
          avatarClass +
          '">' +
          escape(initial) +
          '</i><div><strong>' +
          escape(nickname) +
          '</strong><em>' +
          escape(user.phone || '—') +
          '</em></div></span></td>' +
          '<td><b class="num teal">' +
          escape(credits) +
          '</b></td>' +
          '<td>¥ ' +
          escape(spent) +
          '</td>' +
          '<td><span class="bdg ' +
          (active ? 'teal' : 'red') +
          ' st">' +
          escape(statusLabel) +
          '</span></td>' +
          '<td>' +
          escape(formatDate(user.createdAt)) +
          '</td>' +
          '<td>' +
          escape(formatDateTime(user.lastActiveAt)) +
          '</td>' +
          '<td class="ops">' +
          '<button class="op addc">加算力</button>' +
          '<button class="op freeze">' +
          (active ? '冻结' : '解冻') +
          '</button>' +
          '<button class="op reset">重置密码</button>' +
          '</td>' +
          '</tr>'
        );
      })
      .join('');
    filterUsers();
  }

  async function load() {
    try {
      const data = await global.AdminApi.get('/users?page=1&pageSize=10', {
        mockKey: 'users',
      });
      if (!data) return;
      if (Array.isArray(data.list)) renderUsers(data.list);
      const totalEl = $('#pg-users .pager > span');
      if (totalEl && data.total != null) {
        totalEl.textContent =
          '共 ' + Number(data.total).toLocaleString('zh-CN') + ' 条';
      }
    } catch (error) {
      // api.js 已提示，保留静态数据
    }
  }

  function init() {
    userTable = $('#user-table');
    if (!userTable) return;

    $('#user-search').addEventListener('input', filterUsers);
    $('#user-status').addEventListener('change', filterUsers);
    $('#btn-user-export').addEventListener('click', () =>
      toast('用户数据导出任务已提交，完成后将通知下载', 'ok'),
    );
    $('#btn-user-add').addEventListener('click', () =>
      toast('新增用户请在 C 端注册或导入名单', 'warn'),
    );

    userTable.addEventListener('click', (event) => {
      const button = event.target.closest('.op');
      if (!button) return;
      const row = button.closest('tr');
      const name = $('.u-cell strong', row).textContent;
      const uid = row.children[0].textContent;

      if (button.classList.contains('addc')) {
        addcRow = row;
        $('#addc-user').textContent = name + '（UID ' + uid + '）';
        $('#addc-val').value = 100;
        global.AdminApp.openModal('modal-addc');
      } else if (button.classList.contains('freeze')) {
        const badge = $('.st', row);
        const frozen = badge.textContent.trim() === '冻结';
        badge.textContent = frozen ? '正常' : '冻结';
        badge.classList.toggle('red', !frozen);
        badge.classList.toggle('teal', frozen);
        button.textContent = frozen ? '冻结' : '解冻';
        toast(
          frozen ? '已解冻用户 ' + name : '已冻结用户 ' + name,
          frozen ? 'ok' : 'warn',
        );
      } else if (button.classList.contains('reset')) {
        toast('已向 ' + name + ' 的绑定手机发送重置链接', 'ok');
      }
    });

    $('#addc-ok').addEventListener('click', () => {
      const value = parseFloat($('#addc-val').value || '0');
      if (!value || value <= 0) {
        toast('请输入有效的算力值', 'err');
        return;
      }
      if (addcRow) {
        const cell = $('.num.teal', addcRow);
        const current =
          parseFloat((cell.textContent || '0').replace(/,/g, '')) || 0;
        cell.textContent = (current + value).toLocaleString('zh-CN');
        toast(
          '已为 ' + $('#addc-user').textContent + ' 增加 ' + value + ' 算力',
          'ok',
        );
      }
      global.AdminApp.closeModal('modal-addc');
    });
  }

  global.AdminPages.users = { init, load };
})(window);
