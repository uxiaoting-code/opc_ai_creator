/* 用户管理：分页检索、加算力、冻结/解冻、重置密码 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const toast = global.AdminUtil.toast;
  const escape = global.AdminUtil.escapeHtml;
  const formatDate = global.AdminUtil.formatDate;
  const formatDateTime = global.AdminUtil.formatDateTime;

  let userTable = null;
  let currentUsers = [];
  let mockAllUsers = [];
  let pendingUser = null;
  let pendingStatus = null;
  let loading = false;
  let currentPage = 1;
  let currentPageSize = 10;

  function queryState() {
    return {
      keyword: ($('#user-search').value || '').trim(),
      status: ($('#user-status').value || '').trim(),
      page: currentPage,
      pageSize: currentPageSize,
    };
  }

  function filteredMockUsers(state) {
    const keyword = state.keyword.toLowerCase();
    const status = state.status === '' ? null : Number(state.status);
    return mockAllUsers.filter((user) => {
      const matchesKeyword =
        !keyword ||
        String(user.username || '').toLowerCase().includes(keyword) ||
        String(user.email || '').toLowerCase().includes(keyword);
      const matchesStatus = status == null || Number(user.status) === status;
      return matchesKeyword && matchesStatus;
    });
  }

  function replaceUser(updated) {
    if (!updated) return;
    const index = currentUsers.findIndex((user) => user.id === updated.id);
    if (index >= 0) currentUsers[index] = Object.assign({}, currentUsers[index], updated);
    const mockIndex = mockAllUsers.findIndex((user) => user.id === updated.id);
    if (mockIndex >= 0) {
      mockAllUsers[mockIndex] = Object.assign({}, mockAllUsers[mockIndex], updated);
    }
    renderUsers(currentUsers);
  }

  function renderUsers(rows) {
    if (!userTable) return;
    const body = $('tbody', userTable);
    if (!Array.isArray(rows) || rows.length === 0) {
      body.innerHTML = '<tr><td colspan="8" class="empty-cell">暂无符合条件的用户</td></tr>';
      return;
    }

    body.innerHTML = rows
      .map((user, index) => {
        const nickname = user.nickname || user.username || '未命名';
        const initial = String(nickname).slice(0, 1);
        const active = Number(user.status) === 1;
        const statusLabel = user.statusLabel || (active ? '正常' : '冻结');
        const avatarClass = 'a' + ((index % 6) + 1);
        const credits = Number(user.credits || 0).toLocaleString('zh-CN');
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
          escape(user.username || '—') +
          '</em></div></span></td>' +
          '<td>' +
          escape(user.email || '—') +
          '</td>' +
          '<td><b class="num teal">' +
          escape(credits) +
          '</b></td>' +
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
  }

  function pageNumbers(current, pages) {
    if (pages <= 7) {
      return Array.from({ length: pages }, (_, index) => index + 1);
    }
    const values = new Set([1, pages, current, current - 1, current + 1]);
    return Array.from(values)
      .filter((page) => page >= 1 && page <= pages)
      .sort((a, b) => a - b);
  }

  function renderPager(total) {
    const pager = $('#pg-users .pager .pg-btns');
    if (!pager) return;
    const pages = Math.max(1, Math.ceil(Number(total || 0) / currentPageSize));
    currentPage = Math.min(Math.max(1, currentPage), pages);

    const parts = [];
    const addButton = (page, label, options) => {
      const opts = options || {};
      parts.push(
        '<button data-page="' +
          page +
          '"' +
          (opts.active ? ' class="on"' : '') +
          (opts.disabled ? ' disabled' : '') +
          '>' +
          label +
          '</button>',
      );
    };

    addButton(currentPage - 1, '«', { disabled: currentPage === 1 });
    let previous = 0;
    pageNumbers(currentPage, pages).forEach((page) => {
      if (previous && page - previous > 1) {
        parts.push('<button disabled>…</button>');
      }
      addButton(page, String(page), { active: page === currentPage });
      previous = page;
    });
    addButton(currentPage + 1, '»', { disabled: currentPage === pages });
    pager.innerHTML = parts.join('');
  }

  async function load() {
    if (loading) return;
    loading = true;
    const state = queryState();
    const query = new URLSearchParams({
      page: String(state.page),
      pageSize: String(state.pageSize),
    });
    if (state.keyword) query.set('keyword', state.keyword);
    if (state.status !== '') query.set('status', state.status);

    try {
      const data = await global.AdminApi.get('/users?' + query.toString(), {
        mockKey: 'users',
      });
      if (!data) return;

      if (global.AdminApi.USE_MOCK) {
        if (!mockAllUsers.length && Array.isArray(data.list)) {
          mockAllUsers = data.list.map((user) => Object.assign({}, user));
        }
        const filtered = filteredMockUsers(state);
        const pages = Math.max(1, Math.ceil(filtered.length / state.pageSize));
        currentPage = Math.min(state.page, pages);
        const start = (currentPage - 1) * state.pageSize;
        currentUsers = filtered.slice(start, start + state.pageSize);
        const totalEl = $('#pg-users .pager > span');
        if (totalEl) totalEl.textContent = '共 ' + filtered.length + ' 条（Mock）';
        renderPager(filtered.length);
      } else {
        currentUsers = Array.isArray(data.list) ? data.list : [];
        if (!Array.isArray(data.list) && Array.isArray(data)) {
          currentUsers = data;
        }
        currentPage = Number(data.page || currentPage);
        currentPageSize = Number(data.pageSize || currentPageSize);
        const total =
          data.total != null
            ? Number(data.total)
            : currentUsers.length;
        const totalEl = $('#pg-users .pager > span');
        if (totalEl && data.total != null) {
          totalEl.textContent =
            '共 ' + total.toLocaleString('zh-CN') + ' 条';
        }
        renderPager(total);
      }
      renderUsers(currentUsers);
    } catch (error) {
      // api.js 已统一提示
    } finally {
      loading = false;
    }
  }

  function findSelectedUser(row) {
    const id = Number(row.dataset.userId);
    return currentUsers.find((user) => Number(user.id) === id) || null;
  }

  async function addCredits(user, delta) {
    if (global.AdminApi.USE_MOCK) {
      return Object.assign({}, user, {
        credits: Math.max(0, Number(user.credits || 0) + delta),
      });
    }
    return global.AdminApi.post('/users/' + user.id + '/credits', {
      delta,
    });
  }

  async function setUserStatus(user, status) {
    if (global.AdminApi.USE_MOCK) {
      return Object.assign({}, user, {
        status,
        statusLabel: status === 1 ? '正常' : '冻结',
      });
    }
    return global.AdminApi.put('/users/' + user.id + '/status', { status });
  }

  async function resetPassword(user) {
    if (global.AdminApi.USE_MOCK) {
      return {
        userId: user.id,
        username: user.username,
        newPassword: 'Temp' + Math.random().toString(36).slice(2, 10),
      };
    }
    return global.AdminApi.post('/users/' + user.id + '/reset-password', {});
  }

  function init() {
    userTable = $('#user-table');
    if (!userTable) return;

    const reloadSearch = global.AdminUtil.debounce(load, 280);
    $('#user-search').addEventListener('input', () => {
      currentPage = 1;
      reloadSearch();
    });
    $('#user-status').addEventListener('change', () => {
      currentPage = 1;
      load();
    });
    $('#btn-user-export').addEventListener('click', () =>
      toast('用户数据导出任务已提交，完成后将通知下载', 'ok'),
    );
    $('#btn-user-add').addEventListener('click', () =>
      toast('新增用户请在 C 端注册，或后续通过导入名单添加', 'warn'),
    );

    $('#pg-users .pager .pg-btns').addEventListener('click', (event) => {
      const button = event.target.closest('button[data-page]');
      if (!button || button.disabled) return;
      const nextPage = Number(button.dataset.page);
      if (!Number.isInteger(nextPage) || nextPage < 1 || nextPage === currentPage) {
        return;
      }
      currentPage = nextPage;
      load();
    });

    userTable.addEventListener('click', async (event) => {
      const button = event.target.closest('.op');
      if (!button) return;
      const row = button.closest('tr');
      const user = findSelectedUser(row);
      if (!user) return;
      const name = user.nickname || user.username;

      if (button.classList.contains('addc')) {
        pendingUser = user;
        $('#addc-user').textContent =
          name + '（UID ' + user.id + '）';
        $('#addc-val').value = 100;
        global.AdminApp.openModal('modal-addc');
        return;
      }

      if (button.classList.contains('freeze')) {
        const active = Number(user.status) === 1;
        const nextStatus = active ? 0 : 1;
        const action = active ? '冻结' : '解冻';
        pendingUser = user;
        pendingStatus = nextStatus;
        $('#user-status-title').textContent = '确认' + action;
        $('#user-status-text').textContent =
          '确定要' + action + '用户「' + name + '」吗？' +
          (active ? '冻结后该账号将无法登录。' : '');
        $('#user-status-ok').textContent = '确认' + action;
        global.AdminApp.openModal('modal-user-status');
        return;
      }

      if (button.classList.contains('reset')) {
        button.disabled = true;
        try {
          const result = await resetPassword(user);
          if (!result || !result.newPassword) {
            toast('重置接口未返回新密码，请检查后端响应', 'err');
            return;
          }
          $('#user-password-user').textContent =
            name + '（' + (user.username || user.id) + '）';
          $('#user-password-value').value =
            result.newPassword;
          global.AdminApp.openModal('modal-user-password');
          toast('用户密码已重置', 'ok');
        } catch (error) {
          // api.js 已提示
        } finally {
          button.disabled = false;
        }
      }
    });

    $('#addc-ok').addEventListener('click', async () => {
      if (!pendingUser) return;
      const delta = parseInt($('#addc-val').value || '0', 10);
      if (!Number.isInteger(delta) || delta <= 0) {
        toast('请输入大于 0 的整数算力值', 'err');
        return;
      }
      const button = $('#addc-ok');
      button.disabled = true;
      button.textContent = '提交中…';
      try {
        const updated = await addCredits(pendingUser, delta);
        replaceUser(updated);
        global.AdminApp.closeModal('modal-addc');
        toast('已增加 ' + delta.toLocaleString('zh-CN') + ' 算力', 'ok');
      } catch (error) {
        // api.js 已提示
      } finally {
        button.disabled = false;
        button.textContent = '确认加算力';
        pendingUser = null;
      }
    });

    $('#user-status-ok').addEventListener('click', async () => {
      if (!pendingUser || pendingStatus == null) return;
      const user = pendingUser;
      const status = pendingStatus;
      const name = user.nickname || user.username;
      const button = $('#user-status-ok');
      button.disabled = true;
      button.textContent = '提交中…';
      try {
        const updated = await setUserStatus(user, status);
        replaceUser(updated);
        global.AdminApp.closeModal('modal-user-status');
        toast(
          (status === 1 ? '已解冻用户 ' : '已冻结用户 ') + name,
          status === 1 ? 'ok' : 'warn',
        );
      } catch (error) {
        // api.js 已提示
      } finally {
        button.disabled = false;
        pendingUser = null;
        pendingStatus = null;
      }
    });

    $('#user-password-copy').addEventListener('click', async () => {
      const password = $('#user-password-value').value;
      if (!password) return;
      try {
        await global.navigator.clipboard.writeText(password);
        toast('新密码已复制', 'ok');
      } catch (error) {
        $('#user-password-value').select();
        toast('复制失败，请手动复制', 'warn');
      }
    });
  }

  global.AdminPages.users = { init, load };
})(window);
