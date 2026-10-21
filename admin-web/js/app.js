/* 应用壳：登录、导航、弹窗、页面模块调度 */
(function (global) {
  'use strict';

  const $ = global.AdminUtil.$;
  const $$ = global.AdminUtil.$$;
  const toast = global.AdminUtil.toast;

  const pageTitles = {
    dash: '数据概览',
    users: '用户管理',
    bills: '账单管理',
    models: '大模型配置',
    agents: '智能体 Skill 配置',
    usage: '算力使用',
    settings: '系统设置',
    debug: '调试面板',
    mcp: 'MCP 接入',
    kb: '知识库',
    materials: '素材库',
    gateway: 'API 网关',
  };

  const initialized = new Set();
  let currentPage = 'dash';

  function showApp(user) {
    $('#view-login').classList.add('hidden');
    $('#view-app').classList.remove('hidden');
    const env = $('.adm-env');
    if (env) env.textContent = global.AdminApi.USE_MOCK ? 'Mock 模式' : '生产环境';
    const name = (user && (user.nickname || user.username)) || '超级管理员';
    const target = $('#admin-name');
    if (target) target.textContent = name;
    goPage('dash');
  }

  function showLogin() {
    $('#view-app').classList.add('hidden');
    $('#view-login').classList.remove('hidden');
  }

  function goPage(pg) {
    currentPage = pg;
    $$('.anv').forEach((button) => {
      button.classList.toggle('active', button.dataset.pg === pg);
    });
    $$('.page').forEach((section) => {
      section.classList.toggle('hidden', section.id !== 'pg-' + pg);
    });
    const title = $('#pg-title');
    if (title) title.textContent = pageTitles[pg] || '';

    const page = global.AdminPages && global.AdminPages[pg];
    if (page) {
      if (!initialized.has(pg)) {
        if (typeof page.init === 'function') page.init();
        initialized.add(pg);
      }
      if (pg === 'agents' && typeof page.showList === 'function') {
        page.showList();
      }
      if (typeof page.load === 'function') page.load();
    }

    const main = $('.adm-main .page:not(.hidden)');
    if (main) main.scrollTop = 0;
  }

  function openModal(id) {
    const modal = $('#' + id);
    if (modal) modal.classList.remove('hidden');
  }

  function closeModal(id) {
    const modal = $('#' + id);
    if (modal) modal.classList.add('hidden');
  }

  async function handleLogin() {
    const username = ($('#lg-user').value || '').trim();
    const password = ($('#lg-pass').value || '').trim();
    if (!username || !password) {
      toast('请输入账号与密码', 'err');
      return;
    }

    const button = $('#btn-admin-login');
    button.disabled = true;
    button.textContent = '登录中…';
    try {
      await global.AdminApi.login(username, password);
      const user = await global.AdminApi.profile();
      showApp(user);
      toast(
        global.AdminApi.USE_MOCK
          ? 'Mock 登录成功（切真登录用 ?mock=0）'
          : '登录成功，欢迎回来',
        'ok',
      );
    } catch (error) {
      toast((error && error.message) || '登录失败，请检查后端与账号', 'err');
    } finally {
      button.disabled = false;
      button.textContent = '登 录';
    }
  }

  async function restoreSession() {
    if (!global.AdminApi.getToken()) {
      showLogin();
      return;
    }
    try {
      const user = await global.AdminApi.profile();
      showApp(user);
    } catch (error) {
      global.AdminApi.clearToken();
      showLogin();
    }
  }

  function bind() {
    $$('.anv').forEach((button) => {
      button.addEventListener('click', () => goPage(button.dataset.pg));
    });
    $$('.ph-link[data-goto]').forEach((button) => {
      button.addEventListener('click', () => goPage(button.dataset.goto));
    });

    const loginButton = $('#btn-admin-login');
    if (loginButton) loginButton.addEventListener('click', handleLogin);
    const passwordInput = $('#lg-pass');
    if (passwordInput) {
      passwordInput.addEventListener('keydown', (event) => {
        if (event.key === 'Enter') handleLogin();
      });
    }

    const exitButton = $('#btn-admin-exit');
    if (exitButton) {
      exitButton.addEventListener('click', async () => {
        await global.AdminApi.logout();
        showLogin();
        toast('已安全退出');
      });
    }

    $$('.mask').forEach((mask) => {
      mask.addEventListener('click', (event) => {
        if (event.target === mask) mask.classList.add('hidden');
      });
    });
    $$('[data-close]').forEach((button) => {
      button.addEventListener('click', () => closeModal(button.dataset.close));
    });
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        $$('.mask').forEach((mask) => mask.classList.add('hidden'));
      }
    });

    $$('.pg-btns').forEach((group) => {
      group.addEventListener('click', (event) => {
        const button = event.target.closest('button');
        if (
          !button ||
          button.textContent === '«' ||
          button.textContent === '»' ||
          button.textContent === '…'
        ) {
          return;
        }
        $$('button', group).forEach((item) => item.classList.remove('on'));
        button.classList.add('on');
      });
    });

    global.addEventListener('admin:unauthorized', () => {
      showLogin();
      toast('登录已过期，请重新登录', 'warn');
    });

    restoreSession();
  }

  global.AdminPages = global.AdminPages || {};
  global.AdminApp = {
    goPage,
    showLogin,
    showApp,
    openModal,
    closeModal,
    get currentPage() {
      return currentPage;
    },
  };

  document.addEventListener('DOMContentLoaded', bind);
})(window);
