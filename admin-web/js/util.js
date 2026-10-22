/* 公共工具：DOM、Toast、算力/日期格式化、转义、防抖 */
(function (global) {
  'use strict';

  const $ = (selector, scope) =>
    (scope || document).querySelector(selector);
  const $$ = (selector, scope) =>
    Array.from((scope || document).querySelectorAll(selector));

  let toastWrap = null;
  function toast(message, type) {
    if (!toastWrap) {
      toastWrap = document.createElement('div');
      toastWrap.className = 'toast-wrap';
      document.body.appendChild(toastWrap);
    }
    const item = document.createElement('div');
    item.className = 'toast' + (type ? ' ' + type : '');
    item.textContent = message == null ? '' : String(message);
    toastWrap.appendChild(item);
    requestAnimationFrame(() => item.classList.add('in'));
    setTimeout(() => {
      item.classList.remove('in');
      setTimeout(() => item.remove(), 260);
    }, 2400);
  }

  /**
   * 接口永远返回原始“点数”，这里只负责显示：
   * 9260000 -> 926 万；128000000 -> 1.28 亿；27 -> 27
   */
  function formatCredits(value) {
    if (value === null || value === undefined || value === '') return '—';
    const n = Number(value);
    if (!Number.isFinite(n)) return '—';
    const abs = Math.abs(n);
    if (abs >= 1e8) {
      return (n / 1e8).toFixed(2).replace(/\.?0+$/, '') + ' 亿';
    }
    if (abs >= 1e4) {
      return (n / 1e4).toFixed(1).replace(/\.0$/, '') + ' 万';
    }
    return n.toLocaleString('zh-CN', { maximumFractionDigits: 2 });
  }

  function formatDateTime(value) {
    if (!value) return '—';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return String(value);
    const pad = (n) => String(n).padStart(2, '0');
    return (
      date.getFullYear() +
      '-' +
      pad(date.getMonth() + 1) +
      '-' +
      pad(date.getDate()) +
      ' ' +
      pad(date.getHours()) +
      ':' +
      pad(date.getMinutes())
    );
  }

  function formatDate(value) {
    if (!value) return '—';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return String(value);
    const pad = (n) => String(n).padStart(2, '0');
    return date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate());
  }

  function escapeHtml(value) {
    return String(value == null ? '' : value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function debounce(fn, wait) {
    let timer = null;
    return function () {
      const args = arguments;
      clearTimeout(timer);
      timer = setTimeout(() => fn.apply(this, args), wait || 200);
    };
  }

  global.AdminUtil = {
    $,
    $$,
    toast,
    formatCredits,
    formatDateTime,
    formatDate,
    escapeHtml,
    debounce,
  };
})(window);
