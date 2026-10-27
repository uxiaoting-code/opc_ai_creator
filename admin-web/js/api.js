/* 管理端请求层：baseURL + Authorization + 统一错误 + Mock 开关 */
(function (global) {
  'use strict';

  const API_BASE = 'http://localhost:8080/api/admin';
  const TOKEN_KEY = 'opc_admin_token';
  const MOCK_ADMIN = {
    id: 2,
    username: 'admin',
    nickname: '超级管理员',
    role: 'ADMIN',
    avatar: null,
  };

  // 管理后台已经进入真实接口联调阶段，不再默认回退到静态 Mock。
  const USE_MOCK = false;

  const mockCache = new Map();

  function getToken() {
    return global.localStorage.getItem(TOKEN_KEY) || '';
  }

  function setToken(token) {
    global.localStorage.setItem(TOKEN_KEY, token || '');
  }

  function clearToken() {
    global.localStorage.removeItem(TOKEN_KEY);
  }

  async function loadMock(key) {
    if (mockCache.has(key)) return mockCache.get(key);
    const url = 'mock/' + key + '.json';
    try {
      const response = await fetch(url, { cache: 'no-store' });
      if (!response.ok) throw new Error('HTTP ' + response.status);
      const data = await response.json();
      mockCache.set(key, data);
      return data;
    } catch (error) {
      const message =
        'Mock 数据加载失败：' + url + '。请用 Live Server 打开 admin-web，不要直接双击 index.html。';
      global.AdminUtil.toast(message, 'err');
      throw new Error(message);
    }
  }

  async function request(path, options) {
    const opts = options || {};
    const method = opts.method || 'GET';
    const silent = opts.silent === true;

    if (USE_MOCK && opts.mockKey) {
      return loadMock(opts.mockKey);
    }

    const headers = Object.assign(
      { 'Content-Type': 'application/json' },
      opts.headers || {},
    );
    const token = getToken();
    if (token) headers.Authorization = 'Bearer ' + token;

    try {
      const response = await fetch(API_BASE + path, {
        method,
        headers,
        body: opts.body === undefined ? undefined : JSON.stringify(opts.body),
      });

      if (response.status === 401) {
        clearToken();
        global.dispatchEvent(new CustomEvent('admin:unauthorized'));
        throw new Error('登录已过期，请重新登录');
      }

      const text = await response.text();
      let payload = null;
      if (text) {
        try {
          payload = JSON.parse(text);
        } catch (error) {
          payload = null;
        }
      }

      if (!response.ok) {
        throw new Error(
          (payload && payload.message) || 'HTTP ' + response.status,
        );
      }
      if (payload && payload.code !== 200) {
        throw new Error(payload.message || '请求失败');
      }
      return payload ? payload.data : null;
    } catch (error) {
      const message =
        error && error.message
          ? error.message
          : '后端未连接或网络不可用，请先启动 server';
      if (!silent) global.AdminUtil.toast(message, 'err');
      throw error instanceof Error ? error : new Error(message);
    }
  }

  async function login(username, password) {
    if (USE_MOCK) {
      // Mock 模式：不跑后端也能进后台；真登录请用 ?mock=0
      const token = 'mock-admin-token';
      setToken(token);
      return { token, user: MOCK_ADMIN };
    }
    const data = await request('/auth/login', {
      method: 'POST',
      body: { username, password },
      silent: true,
    });
    setToken(data.token);
    return data;
  }

  async function profile() {
    if (USE_MOCK && getToken() === 'mock-admin-token') return MOCK_ADMIN;
    return request('/auth/profile', { silent: true });
  }

  async function logout() {
    if (!USE_MOCK) {
      await request('/auth/logout', {
        method: 'POST',
        silent: true,
      }).catch(() => {});
    }
    clearToken();
  }

  const get = (path, opts) =>
    request(path, Object.assign({ method: 'GET' }, opts || {}));
  const post = (path, body, opts) =>
    request(
      path,
      Object.assign({ method: 'POST', body }, opts || {}),
    );
  const put = (path, body, opts) =>
    request(path, Object.assign({ method: 'PUT', body }, opts || {}));
  const del = (path, opts) =>
    request(path, Object.assign({ method: 'DELETE' }, opts || {}));

  global.AdminApi = {
    API_BASE,
    USE_MOCK,
    getToken,
    setToken,
    clearToken,
    login,
    profile,
    logout,
    get,
    post,
    put,
    del,
    request,
  };
})(window);
