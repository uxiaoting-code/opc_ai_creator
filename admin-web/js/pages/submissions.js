/* 作品审核：待审核列表、结果预览、通过 / 驳回 */
(function (global) {
  'use strict';

  const util = global.AdminUtil;
  const $ = util.$;
  const esc = util.escapeHtml;
  const toast = util.toast;
  const API_ORIGIN = global.AdminApi.API_BASE.replace(/\/api\/admin\/?$/, '');

  const state = {
    page: 1,
    pageSize: 20,
    total: 0,
    status: 'PENDING',
    mediaType: '',
    currentId: null,
    currentDetail: null,
    loading: false,
  };

  function mediaUrl(url) {
    if (!url) return '';
    if (/^(https?:)?\/\//i.test(url) || /^data:/i.test(url)) return url;
    return API_ORIGIN + (url.charAt(0) === '/' ? url : '/' + url);
  }

  function statusBadge(status, label) {
    const cls = status === 'APPROVED' ? 'teal' : status === 'REJECTED' ? 'red' : 'gold';
    return '<span class="bdg ' + cls + '">' + esc(label || status) + '</span>';
  }

  function render(rows) {
    const body = $('#submission-table tbody');
    if (!body) return;
    if (!Array.isArray(rows) || rows.length === 0) {
      body.innerHTML = '<tr><td colspan="7" class="empty-cell">暂无作品</td></tr>';
      return;
    }
    body.innerHTML = rows
      .map((item) =>
        '<tr data-submission-id="' + esc(item.id) + '">' +
          '<td>' + esc(item.submissionNo || item.id) + '</td>' +
          '<td><strong>' + esc(item.title || '未命名作品') + '</strong></td>' +
          '<td>' + esc(item.orderTitle || '—') + '</td>' +
          '<td>' + esc(item.mediaTypeLabel || item.mediaType || '—') + '</td>' +
          '<td>' + esc(util.formatDateTime(item.submittedAt)) + '</td>' +
          '<td>' + statusBadge(item.status, item.statusLabel) + '</td>' +
          '<td><button class="btn ghost btn-submission-view" data-id="' + esc(item.id) + '" type="button">查看审核</button></td>' +
        '</tr>',
      )
      .join('');
  }

  function renderPager() {
    const pages = Math.max(1, Math.ceil(state.total / state.pageSize));
    const box = $('#submission-pager');
    if (!box) return;
    box.innerHTML =
      '<button type="button" data-page="' + Math.max(1, state.page - 1) + '"' +
        (state.page <= 1 ? ' disabled' : '') + '>«</button>' +
      '<button class="on" type="button">' + state.page + ' / ' + pages + '</button>' +
      '<button type="button" data-page="' + Math.min(pages, state.page + 1) + '"' +
        (state.page >= pages ? ' disabled' : '') + '>»</button>';
    const count = $('#submission-count');
    if (count) count.textContent = '共 ' + state.total + ' 条';
  }

  async function load() {
    if (state.loading) return;
    state.loading = true;
    const body = $('#submission-table tbody');
    if (body) body.innerHTML = '<tr><td colspan="7" class="empty-cell">正在加载作品…</td></tr>';
    try {
      const query = new URLSearchParams({
        page: String(state.page),
        pageSize: String(state.pageSize),
      });
      if (state.status) query.set('status', state.status);
      if (state.mediaType) query.set('mediaType', state.mediaType);
      const data = await global.AdminApi.get('/submissions?' + query.toString());
      state.total = Number(data && data.total) || 0;
      render((data && data.list) || []);
      renderPager();
    } catch (_) {
      render([]);
    } finally {
      state.loading = false;
    }
  }

  function mediaPreview(detail) {
    const submission = detail && detail.submission;
    if (!submission) return '<div class="material-tree-empty">没有作品数据</div>';
    const url = mediaUrl(submission.thumbnailUrl || submission.resultUrl);
    if (submission.mediaType === 'VIDEO') {
      return url
        ? '<video controls preload="metadata" style="width:100%;max-height:420px;background:#111" src="' + esc(url) + '"></video>'
        : '<div class="material-tree-empty">视频地址为空</div>';
    }
    if (submission.mediaType === 'AUDIO') {
      return url
        ? '<audio controls style="width:100%" src="' + esc(url) + '"></audio>'
        : '<div class="material-tree-empty">音频地址为空</div>';
    }
    return url
      ? '<img src="' + esc(url) + '" alt="作品预览" style="width:100%;max-height:420px;object-fit:contain;background:#111" />'
      : '<div class="material-tree-empty">图片地址为空</div>';
  }

  async function openDetail(id) {
    try {
      const detail = await global.AdminApi.get('/submissions/' + encodeURIComponent(id) + '/result');
      state.currentId = Number(id);
      state.currentDetail = detail;
      const submission = detail.submission || {};
      $('#submission-dialog-title').textContent = submission.title || '作品审核';
      $('#submission-review-comment').value = submission.reviewNote || '';
      $('#submission-dialog-content').innerHTML =
        mediaPreview(detail) +
        '<div class="panel" style="margin-top:14px">' +
          '<div class="panel-head"><strong>提交信息</strong>' + statusBadge(submission.status, submission.statusLabel) + '</div>' +
          '<p><strong>订单：</strong>' + esc(submission.orderTitle || '—') + '</p>' +
          '<p><strong>提交号：</strong>' + esc(submission.submissionNo || '—') + '</p>' +
          '<p><strong>交付说明：</strong>' + esc(submission.note || '—') + '</p>' +
        '</div>';
      const disabled = submission.status !== 'PENDING';
      $('#submission-approve').disabled = disabled;
      $('#submission-reject').disabled = disabled;
      global.AdminApp.openModal('modal-submission-review');
    } catch (_) {
      // AdminApi 已提示错误
    }
  }

  async function review(decision) {
    if (!state.currentId) return;
    const comment = ($('#submission-review-comment').value || '').trim();
    if (decision === 'REJECTED' && !comment) {
      toast('驳回时请填写审核意见', 'warn');
      return;
    }
    try {
      await global.AdminApi.put(
        '/submissions/' + state.currentId + '/review',
        { decision, comment },
      );
      toast(decision === 'APPROVED' ? '作品已通过' : '作品已驳回', 'ok');
      global.AdminApp.closeModal('modal-submission-review');
      await load();
    } catch (_) {
      // AdminApi 已提示错误
    }
  }

  function bind() {
    $('#submission-refresh')?.addEventListener('click', () => {
      state.page = 1;
      load();
    });
    $('#submission-status')?.addEventListener('change', (event) => {
      state.status = event.target.value;
      state.page = 1;
      load();
    });
    $('#submission-media')?.addEventListener('change', (event) => {
      state.mediaType = event.target.value;
      state.page = 1;
      load();
    });
    $('#submission-table')?.addEventListener('click', (event) => {
      const button = event.target.closest('.btn-submission-view');
      if (button) openDetail(button.dataset.id);
    });
    $('#submission-pager')?.addEventListener('click', (event) => {
      const button = event.target.closest('button[data-page]');
      if (!button || button.disabled) return;
      state.page = Number(button.dataset.page) || 1;
      load();
    });
    $('#submission-approve')?.addEventListener('click', () => review('APPROVED'));
    $('#submission-reject')?.addEventListener('click', () => review('REJECTED'));
  }

  global.AdminPages = global.AdminPages || {};
  global.AdminPages.submissions = {
    init: bind,
    load,
  };
})(window);
