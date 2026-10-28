/* 素材库后台：分类树、多级标签、卡片检索、详情、编辑与版本历史 */
(function (global) {
  'use strict';

  const util = global.AdminUtil;
  const $ = util.$;
  const esc = util.escapeHtml;
  const toast = util.toast;
  const API_ORIGIN = global.AdminApi.API_BASE.replace(/\/api\/admin\/?$/, '');

  const state = {
    initialized: false,
    loading: false,
    page: 1,
    pageSize: 12,
    total: 0,
    keyword: '',
    type: '',
    categoryId: null,
    tagIds: new Set(),
    editorTagIds: new Set(),
    categories: [],
    tags: [],
    categoryFlat: [],
    tagFlat: [],
    categoryMap: new Map(),
    tagMap: new Map(),
    items: [],
    mockItems: null,
    mockVersions: new Map(),
    editId: null,
    detailId: null,
  };

  function flattenTree(nodes, path) {
    const result = [];
    (nodes || []).forEach((node) => {
      const nodePath = path ? path + ' / ' + node.name : node.name;
      result.push({ node, path: nodePath });
      result.push.apply(result, flattenTree(node.children, nodePath));
    });
    return result;
  }

  function collectDescendantIds(roots) {
    const map = new Map();
    roots.forEach((item) => map.set(Number(item.node.id), item.node));
    return function (id) {
      const ids = new Set([Number(id)]);
      let changed = true;
      while (changed) {
        changed = false;
        map.forEach((node, nodeId) => {
          if (ids.has(Number(node.parentId)) && !ids.has(nodeId)) {
            ids.add(nodeId);
            changed = true;
          }
        });
      }
      return ids;
    };
  }

  function mediaUrl(url) {
    if (!url) return '';
    if (/^(https?:)?\/\//i.test(url) || /^data:/i.test(url)) return url;
    return API_ORIGIN + (url.charAt(0) === '/' ? url : '/' + url);
  }

  function mediaLabel(type) {
    return (
      {
        IMAGE: '图片',
        VIDEO: '视频',
        AUDIO: '音频',
        OTHER: '其他',
      }[type] || '其他'
    );
  }

  function mediaIcon(type) {
    return (
      {
        IMAGE: '🖼',
        VIDEO: '▶',
        AUDIO: '♫',
        OTHER: '◈',
      }[type] || '◈'
    );
  }

  function formatBytes(value) {
    const size = Number(value);
    if (!Number.isFinite(size) || size <= 0) return '—';
    if (size < 1024) return size + ' B';
    if (size < 1024 * 1024) return (size / 1024).toFixed(1) + ' KB';
    if (size < 1024 * 1024 * 1024) {
      return (size / 1024 / 1024).toFixed(1) + ' MB';
    }
    return (size / 1024 / 1024 / 1024).toFixed(1) + ' GB';
  }

  function tagNames(item) {
    return Array.isArray(item.tags)
      ? item.tags.map((tag) => tag.name).filter(Boolean)
      : [];
  }

  function tagIdsOf(item) {
    return Array.isArray(item.tags)
      ? item.tags.map((tag) => Number(tag.id)).filter(Number.isFinite)
      : [];
  }

  function materialTitle(item) {
    return item.title || item.name || '未命名素材';
  }

  function escapeAttribute(value) {
    return esc(value).replace(/\n/g, ' ');
  }

  async function loadTaxonomy() {
    const data = await global.AdminApi.get('/material-categories', {
      mockKey: 'material-categories',
    });
    state.categories = (data && data.categories) || [];
    state.tags = (data && data.tags) || [];
    state.categoryFlat = flattenTree(state.categories, '');
    state.tagFlat = flattenTree(state.tags, '');
    state.categoryMap = new Map(
      state.categoryFlat.map((entry) => [Number(entry.node.id), entry]),
    );
    state.tagMap = new Map(
      state.tagFlat.map((entry) => [Number(entry.node.id), entry]),
    );
    renderCategoryTree();
    renderTagTree();
    renderTagPicker();
  }

  function renderCategoryTree() {
    const root = $('#material-category-tree');
    if (!root) return;
    root.innerHTML =
      '<button class="material-tree-row' +
      (state.categoryId === null ? ' on' : '') +
      '" type="button" data-category-id=""><span>全部素材</span><b>' +
      state.total +
      '</b></button>' +
      renderCategoryNodes(state.categories, 0);
  }

  function renderCategoryNodes(nodes, depth) {
    return (nodes || [])
      .map((node) => {
        const active = Number(node.id) === Number(state.categoryId);
        return (
          '<button class="material-tree-row' +
          (active ? ' on' : '') +
          '" type="button" data-category-id="' +
          esc(node.id) +
          '" style="padding-left:' +
          (8 + depth * 10) +
          'px"><span>' +
          esc(node.name) +
          '</span></button>' +
          (node.children && node.children.length
            ? '<div class="material-tree-children">' +
              renderCategoryNodes(node.children, depth + 1) +
              '</div>'
            : '')
        );
      })
      .join('');
  }

  function renderTagTree() {
    const root = $('#material-tag-tree');
    if (!root) return;
    if (!(state.tags || []).length) {
      root.innerHTML = '<div class="material-tree-empty">暂无标签</div>';
      return;
    }
    root.innerHTML = renderTagCheckNodes(state.tags, 0, false);
  }

  function renderTagCheckNodes(nodes, depth, pickerMode) {
    return (nodes || [])
      .map((node) => {
        const selected = pickerMode ? state.editorTagIds : state.tagIds;
        const checked = selected.has(Number(node.id));
        return (
          '<label class="material-tree-row' +
          (checked ? ' on' : '') +
          '" style="padding-left:' +
          (pickerMode ? 4 + depth * 12 : 8 + depth * 10) +
          'px"><input type="checkbox" data-tag-id="' +
          esc(node.id) +
          '"' +
          (checked ? ' checked' : '') +
          ' /><span>' +
          esc(node.name) +
          '</span></label>' +
          (node.children && node.children.length
            ? '<div class="material-tree-children">' +
              renderTagCheckNodes(node.children, depth + 1, pickerMode) +
              '</div>'
            : '')
        );
      })
      .join('');
  }

  function renderTagPicker() {
    const root = $('#material-edit-tags');
    if (!root) return;
    root.innerHTML = state.tags.length
      ? renderTagCheckNodes(state.tags, 0, true)
      : '<span class="material-tree-empty">暂无可用标签</span>';
  }

  function renderFilterSummary() {
    const root = $('#material-filter-summary');
    if (!root) return;
    const chips = [];
    if (state.categoryId !== null) {
      const category = state.categoryMap.get(Number(state.categoryId));
      chips.push(
        '<span class="material-filter-chip">分类：' +
          esc(category ? category.path : '未知分类') +
          '</span>',
      );
    }
    state.tagIds.forEach((id) => {
      const tag = state.tagMap.get(Number(id));
      if (tag) {
        chips.push(
          '<span class="material-filter-chip">标签：' +
            esc(tag.path) +
            '</span>',
        );
      }
    });
    if (state.keyword) {
      chips.push(
        '<span class="material-filter-chip">关键词：' +
          esc(state.keyword) +
          '</span>',
      );
    }
    if (state.type) {
      chips.push(
        '<span class="material-filter-chip">类型：' +
          esc(mediaLabel(state.type)) +
          '</span>',
      );
    }
    root.innerHTML = chips.length
      ? chips.join('')
      : '<span>全部素材 · 父级分类和多级标签筛选会自动包含后代节点</span>';
  }

  function renderGrid() {
    const grid = $('#material-grid');
    if (!grid) return;
    if (state.loading) {
      grid.innerHTML =
        '<div class="material-empty"><i>◌</i><span>正在加载素材…</span></div>';
      return;
    }
    if (!state.items.length) {
      grid.innerHTML =
        '<div class="material-empty"><i>🖼</i><span>当前筛选条件下暂无素材</span><span>可以点击右上角「新增素材」录入文件地址</span></div>';
      return;
    }
    grid.innerHTML = state.items.map(renderCard).join('');
  }

  function renderCard(item) {
    const type = item.mediaType || 'OTHER';
    const tags = tagNames(item);
    return (
      '<article class="material-card" data-material-id="' +
      esc(item.id) +
      '"><div class="material-thumb">' +
      renderPreview(item, false) +
      '<span class="material-kind">' +
      esc(mediaLabel(type)) +
      '</span><span class="material-version">v' +
      esc(item.version || 1) +
      '</span></div><div class="material-card-body">' +
      '<button class="material-card-title" type="button" data-material-action="detail">' +
      esc(materialTitle(item)) +
      '</button><div class="material-card-meta"><span>' +
      esc(item.categoryPath || '未分类') +
      '</span><span>' +
      esc(formatBytes(item.fileSize)) +
      '</span></div><div class="material-card-tags">' +
      (tags.length
        ? tags
            .slice(0, 3)
            .map((tag) => '<span>' + esc(tag) + '</span>')
            .join('')
        : '<span>无标签</span>') +
      '</div><div class="material-card-ops">' +
      '<button type="button" data-material-action="detail">查看</button>' +
      '<button type="button" data-material-action="edit">编辑</button>' +
      '<button class="danger" type="button" data-material-action="delete">下架</button>' +
      '</div></div></article>'
    );
  }

  function renderPreview(item, detailMode) {
    const type = item.mediaType || 'OTHER';
    const url = item.thumbUrl || item.fileUrl;
    const fallback =
      '<div class="material-thumb-fallback"' +
      (url ? ' style="display:none"' : '') +
      '><span>' +
      mediaIcon(type) +
      '</span><em>' +
      esc(mediaLabel(type)) +
      '</em></div>';
    if (type === 'IMAGE' && url) {
      return (
        '<img src="' +
        escapeAttribute(mediaUrl(url)) +
        '" alt="' +
        escapeAttribute(materialTitle(item)) +
        '" onerror="this.style.display=\'none\';var f=this.nextElementSibling;if(f){f.style.display=\'flex\';}" />' +
        fallback
      );
    }
    if (type === 'VIDEO' && item.fileUrl) {
      return detailMode
        ? '<video src="' +
            escapeAttribute(mediaUrl(item.fileUrl)) +
            '" controls preload="metadata"></video>'
        : fallback;
    }
    return fallback;
  }

  function renderPagination() {
    const count = $('#material-result-count');
    const root = $('#material-pagination-buttons');
    if (count) count.textContent = '共 ' + state.total + ' 条';
    if (!root) return;
    const pages = Math.max(1, Math.ceil(state.total / state.pageSize));
    const current = Math.min(state.page, pages);
    const pageSet = new Set([
      1,
      pages,
      current - 2,
      current - 1,
      current,
      current + 1,
      current + 2,
    ]);
    const sorted = Array.from(pageSet)
      .filter((page) => page >= 1 && page <= pages)
      .sort((a, b) => a - b);
    let last = 0;
    const buttons = [
      '<button type="button" data-material-page="' +
        (current - 1) +
        '"' +
        (current <= 1 ? ' disabled' : '') +
        '>«</button>',
    ];
    sorted.forEach((page) => {
      if (last && page - last > 1) buttons.push('<button disabled>…</button>');
      buttons.push(
        '<button type="button" data-material-page="' +
          page +
          '" class="' +
          (page === current ? 'on' : '') +
          '">' +
          page +
          '</button>',
      );
      last = page;
    });
    buttons.push(
      '<button type="button" data-material-page="' +
        (current + 1) +
        '"' +
        (current >= pages ? ' disabled' : '') +
        '>»</button>',
    );
    root.innerHTML = buttons.join('');
  }

  function buildQuery() {
    const params = new URLSearchParams();
    params.set('page', state.page);
    params.set('pageSize', state.pageSize);
    if (state.keyword) params.set('keyword', state.keyword);
    if (state.categoryId !== null) params.set('categoryId', state.categoryId);
    if (state.type) params.set('type', state.type);
    state.tagIds.forEach((id) => params.append('tagIds', id));
    return params;
  }

  async function ensureMockData() {
    if (state.mockItems !== null) return;
    const data = await global.AdminApi.get('/materials', {
      mockKey: 'materials',
    });
    state.mockItems = (
      Array.isArray(data) ? data : data && data.list ? data.list : []
    ).map((item) => Object.assign({}, item));
    state.mockItems.forEach((item) => {
      if (!state.mockVersions.has(Number(item.id))) {
        state.mockVersions.set(Number(item.id), [
          {
            id: Number(item.id) * 1000 + Number(item.version || 1),
            materialId: Number(item.id),
            version: Number(item.version || 1),
            title: materialTitle(item),
            categoryId: item.categoryId,
            categoryName: item.categoryName,
            tagIds: tagIdsOf(item),
            tagNames: tagNames(item),
            fileUrl: item.fileUrl,
            thumbUrl: item.thumbUrl,
            mimeType: item.mimeType,
            mediaType: item.mediaType,
            fileSize: item.fileSize,
            width: item.width,
            height: item.height,
            changeNote: '初始版本',
            createdAt: item.updatedAt || item.createdAt,
          },
        ]);
      }
    });
  }

  function filterMockData() {
    const categoryIds =
      state.categoryId === null
        ? null
        : collectDescendantIds(state.categoryFlat)(state.categoryId);
    const tagLookup = collectDescendantIds(state.tagFlat);
    const expandedTags = new Set();
    state.tagIds.forEach((id) => {
      tagLookup(id).forEach((childId) => expandedTags.add(childId));
    });
    const keyword = state.keyword.toLowerCase();
    return state.mockItems.filter((item) => {
      if (categoryIds && !categoryIds.has(Number(item.categoryId))) return false;
      if (
        expandedTags.size &&
        !tagIdsOf(item).some((id) => expandedTags.has(Number(id)))
      ) {
        return false;
      }
      if (state.type && item.mediaType !== state.type) return false;
      if (!keyword) return true;
      return [materialTitle(item), item.categoryPath, item.fileUrl]
        .concat(tagNames(item))
        .filter(Boolean)
        .join(' ')
        .toLowerCase()
        .includes(keyword);
    });
  }

  async function loadMaterials() {
    state.loading = true;
    renderGrid();
    renderFilterSummary();
    try {
      if (global.AdminApi.USE_MOCK) {
        await ensureMockData();
        const filtered = filterMockData().sort(
          (a, b) =>
            new Date(b.updatedAt || b.createdAt || 0) -
            new Date(a.updatedAt || a.createdAt || 0),
        );
        state.total = filtered.length;
        const start = (state.page - 1) * state.pageSize;
        state.items = filtered.slice(start, start + state.pageSize);
      } else {
        const data = await global.AdminApi.get(
          '/materials?' + buildQuery().toString(),
        );
        state.items = (data && data.list) || [];
        state.total = (data && data.total) || 0;
      }
      const pages = Math.max(1, Math.ceil(state.total / state.pageSize));
      if (state.page > pages) {
        state.page = pages;
        state.loading = false;
        return loadMaterials();
      }
    } catch (error) {
      state.items = [];
      state.total = 0;
    } finally {
      state.loading = false;
    }
    renderGrid();
    renderPagination();
    renderCategoryTree();
    renderFilterSummary();
  }

  function findItem(id) {
    return state.items.find((item) => Number(item.id) === Number(id));
  }

  function openDetail(id) {
    const item = findItem(id);
    if (!item) return;
    state.detailId = Number(id);
    const body = $('#material-detail-body');
    if (!body) return;
    const tags = tagNames(item);
    body.innerHTML =
      '<div class="material-detail-preview">' +
      renderPreview(item, true) +
      '</div><dl class="material-detail-list">' +
      '<div><dt>素材名称</dt><dd>' +
      esc(materialTitle(item)) +
      '</dd></div><div><dt>分类</dt><dd>' +
      esc(item.categoryPath || '未分类') +
      '</dd></div><div><dt>多级标签</dt><dd class="material-detail-tags">' +
      (tags.length
        ? tags.map((tag) => '<span>' + esc(tag) + '</span>').join('')
        : '无') +
      '</dd></div><div><dt>当前版本</dt><dd>v' +
      esc(item.version || 1) +
      '</dd></div><div><dt>文件类型</dt><dd>' +
      esc(item.mimeType || '—') +
      '</dd></div><div><dt>文件大小</dt><dd>' +
      esc(formatBytes(item.fileSize)) +
      (item.width && item.height
        ? ' · ' + esc(item.width) + '×' + esc(item.height)
        : '') +
      '</dd></div><div><dt>文件地址</dt><dd>' +
      esc(item.fileUrl || '—') +
      '</dd></div><div><dt>更新时间</dt><dd>' +
      esc(util.formatDateTime(item.updatedAt || item.createdAt)) +
      '</dd></div></dl>';
    global.AdminApp.openModal('modal-material-detail');
  }

  function setSelectValue(select, value) {
    if (!select) return;
    const text = value == null ? '' : String(value);
    if (text && !Array.from(select.options).some((option) => option.value === text)) {
      const option = document.createElement('option');
      option.value = text;
      option.textContent = text;
      select.appendChild(option);
    }
    select.value = text;
  }

  function fillCategorySelect() {
    const select = $('#material-edit-category');
    if (!select) return;
    select.innerHTML =
      '<option value="0">未分类</option>' +
      state.categoryFlat
        .map(
          (entry) =>
            '<option value="' +
            esc(entry.node.id) +
            '">' +
            esc(entry.path) +
            '</option>',
        )
        .join('');
  }

  function openEditor(id) {
    const item = id ? findItem(id) : null;
    state.editId = item ? Number(item.id) : null;
    fillCategorySelect();
    $('#material-edit-title-label').textContent = item
      ? '编辑素材'
      : '新增素材';
    $('#material-edit-title').value = item ? materialTitle(item) : '';
    $('#material-edit-url').value = item ? item.fileUrl || '' : '/upload/';
    $('#material-edit-thumb').value = item ? item.thumbUrl || '' : '';
    $('#material-edit-size').value =
      item && item.fileSize != null ? item.fileSize : '';
    setSelectValue(
      $('#material-edit-category'),
      item && item.categoryId != null ? item.categoryId : 0,
    );
    setSelectValue(
      $('#material-edit-mime'),
      item && item.mimeType ? item.mimeType : 'image/png',
    );
    state.editorTagIds = new Set(item ? tagIdsOf(item) : []);
    renderTagPicker();
    $('#material-edit-new-version').checked = false;
    $('#material-version-option').classList.toggle('hidden', !item);
    $('#material-change-note-label').classList.toggle('hidden', !item);
    $('#material-change-note').value = '';
    global.AdminApp.openModal('modal-material-edit');
  }

  function readEditor(tagIds) {
    const sizeValue = $('#material-edit-size').value.trim();
    return {
      title: $('#material-edit-title').value.trim(),
      fileUrl: $('#material-edit-url').value.trim(),
      thumbUrl: $('#material-edit-thumb').value.trim(),
      mimeType: $('#material-edit-mime').value,
      fileSize: sizeValue === '' ? null : Number(sizeValue),
      categoryId: Number($('#material-edit-category').value || 0),
      tagIds: tagIds,
      newVersion: Boolean($('#material-edit-new-version').checked),
      changeNote: $('#material-change-note').value.trim(),
    };
  }

  function tagsFromIds(ids) {
    return (ids || [])
      .map((id) => state.tagMap.get(Number(id)))
      .filter(Boolean)
      .map((entry) => ({
        id: Number(entry.node.id),
        name: entry.node.name,
        parentId: entry.node.parentId,
      }));
  }

  function mediaTypeFromMime(mime) {
    const value = String(mime || '').toLowerCase();
    if (value.startsWith('image/')) return 'IMAGE';
    if (value.startsWith('video/')) return 'VIDEO';
    if (value.startsWith('audio/')) return 'AUDIO';
    return 'OTHER';
  }

  function saveMockMaterial(payload, explicitEditId) {
    const now = new Date().toISOString();
    const category = state.categoryMap.get(Number(payload.categoryId));
    const tags = tagsFromIds(payload.tagIds);
    const editId =
      explicitEditId === undefined ? state.editId : explicitEditId;
    if (editId) {
      const item = findItem(editId);
      if (!item) throw new Error('素材不存在或已下架');
      const newVersion = payload.newVersion
        ? Number(item.version || 1) + 1
        : Number(item.version || 1);
      Object.assign(item, payload, {
        id: item.id,
        name: payload.title,
        categoryId: payload.categoryId || null,
        categoryPath: category ? category.path : null,
        categoryName: category ? category.node.name : null,
        tags: tags,
        mediaType: mediaTypeFromMime(payload.mimeType),
        version: newVersion,
        updatedAt: now,
      });
      const versions = state.mockVersions.get(Number(item.id)) || [];
      const versionItem = {
        id: Date.now(),
        materialId: Number(item.id),
        version: newVersion,
        title: payload.title,
        categoryId: payload.categoryId || null,
        categoryName: category ? category.node.name : null,
        tagIds: payload.tagIds,
        tagNames: tags.map((tag) => tag.name),
        fileUrl: payload.fileUrl,
        thumbUrl: payload.thumbUrl,
        mimeType: payload.mimeType,
        mediaType: mediaTypeFromMime(payload.mimeType),
        fileSize: payload.fileSize,
        changeNote:
          payload.changeNote ||
          (payload.newVersion ? '更新素材' : '同步当前版本'),
        createdAt: now,
      };
      if (payload.newVersion) versions.unshift(versionItem);
      else if (versions.length) Object.assign(versions[0], versionItem);
      else versions.push(versionItem);
      state.mockVersions.set(Number(item.id), versions);
      return item;
    }

    const nextId =
      Math.max(0, ...state.mockItems.map((item) => Number(item.id) || 0)) + 1;
    const item = {
      id: nextId,
      title: payload.title,
      name: payload.title,
      categoryId: payload.categoryId || null,
      categoryName: category ? category.node.name : null,
      categoryPath: category ? category.path : null,
      tags: tags,
      fileUrl: payload.fileUrl,
      thumbUrl: payload.thumbUrl || null,
      mimeType: payload.mimeType,
      mediaType: mediaTypeFromMime(payload.mimeType),
      fileSize: payload.fileSize,
      width: null,
      height: null,
      version: 1,
      createdAt: now,
      updatedAt: now,
    };
    state.mockItems.unshift(item);
    state.mockVersions.set(nextId, [
      {
        id: Date.now(),
        materialId: nextId,
        version: 1,
        title: item.title,
        categoryId: item.categoryId,
        categoryName: item.categoryName,
        tagIds: item.tags.map((tag) => tag.id),
        tagNames: item.tags.map((tag) => tag.name),
        fileUrl: item.fileUrl,
        thumbUrl: item.thumbUrl,
        mimeType: item.mimeType,
        mediaType: item.mediaType,
        fileSize: item.fileSize,
        width: item.width,
        height: item.height,
        changeNote: payload.changeNote || '创建素材',
        createdAt: now,
      },
    ]);
    return item;
  }

  async function saveMaterial() {
    const payload = readEditor(Array.from(state.editorTagIds));
    if (!payload.title) {
      toast('请填写素材名称', 'err');
      return;
    }
    if (
      !payload.fileUrl ||
      (payload.fileUrl.indexOf('/upload/') !== 0 &&
        payload.fileUrl.indexOf('http://') !== 0 &&
        payload.fileUrl.indexOf('https://') !== 0)
    ) {
      toast('文件地址需以 /upload/、http:// 或 https:// 开头', 'err');
      return;
    }
    if (
      payload.fileSize !== null &&
      (!Number.isFinite(payload.fileSize) || payload.fileSize < 0)
    ) {
      toast('文件大小必须是非负数字', 'err');
      return;
    }
    const button = $('#material-save');
    button.disabled = true;
    button.textContent = '保存中…';
    try {
      if (global.AdminApi.USE_MOCK) {
        await ensureMockData();
        saveMockMaterial(payload);
      } else if (state.editId) {
        await global.AdminApi.put('/materials/' + state.editId, payload, {
          silent: true,
        });
      } else {
        await global.AdminApi.post('/materials', payload, { silent: true });
      }
      global.AdminApp.closeModal('modal-material-edit');
      toast(state.editId ? '素材已更新' : '素材已创建', 'ok');
      state.editId = null;
      state.editorTagIds.clear();
      await loadMaterials();
    } catch (error) {
      if (error && error.message) toast(error.message, 'err');
    } finally {
      button.disabled = false;
      button.textContent = '保存素材';
    }
  }

  async function deleteMaterial(id) {
    const item = findItem(id);
    if (!item) return;
    if (!global.confirm('确定下架「' + materialTitle(item) + '」吗？')) return;
    try {
      if (global.AdminApi.USE_MOCK) {
        await ensureMockData();
        state.mockItems = state.mockItems.filter(
          (material) => Number(material.id) !== Number(id),
        );
      } else {
        await global.AdminApi.del('/materials/' + id, { silent: true });
      }
      toast('素材已下架', 'ok');
      await loadMaterials();
    } catch (error) {
      if (error && error.message) toast(error.message, 'err');
    }
  }

  async function openVersions(id) {
    const materialId = Number(id || state.detailId);
    if (!materialId) return;
    const root = $('#material-version-list');
    if (root) {
      root.innerHTML =
        '<div class="material-tree-empty">正在加载版本…</div>';
    }
    global.AdminApp.openModal('modal-material-versions');
    try {
      let versions;
      if (global.AdminApi.USE_MOCK) {
        await ensureMockData();
        versions = state.mockVersions.get(materialId) || [];
      } else {
        versions = await global.AdminApi.get(
          '/materials/' + materialId + '/versions',
        );
      }
      renderVersions(materialId, versions || []);
    } catch (error) {
      if (root) {
        root.innerHTML =
          '<div class="material-tree-empty">版本历史加载失败</div>';
      }
    }
  }

  function renderVersions(materialId, versions) {
    const root = $('#material-version-list');
    if (!root) return;
    if (!versions.length) {
      root.innerHTML =
        '<div class="material-tree-empty">暂无版本记录</div>';
      return;
    }
    root.innerHTML = versions
      .map(
        (version) =>
          '<div class="material-version-item"><div class="material-version-top"><strong>v' +
          esc(version.version) +
          '</strong><span>' +
          esc(util.formatDateTime(version.createdAt)) +
          '</span><button class="btn ghost" type="button" data-restore-version="' +
          esc(version.version) +
          '" data-material-id="' +
          esc(materialId) +
          '">恢复此版本</button></div><p>' +
          esc(version.title || '未命名素材') +
          ' · ' +
          esc(version.categoryName || '未分类') +
          (version.tagNames && version.tagNames.length
            ? ' · ' + esc(version.tagNames.join(' / '))
            : '') +
          '</p><em>' +
          esc(version.changeNote || '无版本说明') +
          '</em></div>',
      )
      .join('');
  }

  async function restoreVersion(materialId, versionNo) {
    const item = findItem(materialId);
    if (
      !global.confirm(
        '确定恢复到 v' +
          versionNo +
          ' 吗？系统会以该版本内容生成一个新的当前版本。',
      )
    ) {
      return;
    }
    try {
      if (global.AdminApi.USE_MOCK) {
        await ensureMockData();
        const versions = state.mockVersions.get(Number(materialId)) || [];
        const source = versions.find(
          (version) => Number(version.version) === Number(versionNo),
        );
        if (!source || !item) throw new Error('素材版本不存在');
        saveMockMaterial(
          {
            title: source.title,
            fileUrl: source.fileUrl,
            thumbUrl: source.thumbUrl || '',
            mimeType: source.mimeType,
            fileSize: source.fileSize,
            categoryId: source.categoryId || 0,
            tagIds: source.tagIds || [],
            newVersion: true,
            changeNote: '恢复到版本 v' + versionNo,
          },
          materialId,
        );
      } else {
        await global.AdminApi.post(
          '/materials/' +
            materialId +
            '/versions/' +
            versionNo +
            '/restore',
          { changeNote: '恢复到版本 v' + versionNo },
          { silent: true },
        );
      }
      global.AdminApp.closeModal('modal-material-versions');
      toast('已恢复并生成新版本', 'ok');
      await loadMaterials();
    } catch (error) {
      if (error && error.message) toast(error.message, 'err');
    }
  }

  function resetPageAndLoad() {
    state.page = 1;
    loadMaterials();
  }

  function bind() {
    if (state.initialized) return;
    state.initialized = true;

    const search = $('#material-search');
    if (search) {
      search.addEventListener(
        'input',
        util.debounce(() => {
          state.keyword = search.value.trim();
          resetPageAndLoad();
        }, 220),
      );
    }
    const type = $('#material-type-filter');
    if (type) {
      type.addEventListener('change', () => {
        state.type = type.value;
        resetPageAndLoad();
      });
    }
    const categoryTree = $('#material-category-tree');
    if (categoryTree) {
      categoryTree.addEventListener('click', (event) => {
        const row = event.target.closest('[data-category-id]');
        if (!row) return;
        const value = row.getAttribute('data-category-id');
        state.categoryId = value === '' ? null : Number(value);
        resetPageAndLoad();
      });
    }
    const tagTree = $('#material-tag-tree');
    if (tagTree) {
      tagTree.addEventListener('change', (event) => {
        const input = event.target.closest('[data-tag-id]');
        if (!input) return;
        const id = Number(input.getAttribute('data-tag-id'));
        if (input.checked) state.tagIds.add(id);
        else state.tagIds.delete(id);
        resetPageAndLoad();
      });
    }
    const editTags = $('#material-edit-tags');
    if (editTags) {
      editTags.addEventListener('change', (event) => {
        const input = event.target.closest('[data-tag-id]');
        if (!input) return;
        const id = Number(input.getAttribute('data-tag-id'));
        if (input.checked) state.editorTagIds.add(id);
        else state.editorTagIds.delete(id);
        input.closest('.material-tree-row').classList.toggle(
          'on',
          input.checked,
        );
      });
    }
    const grid = $('#material-grid');
    if (grid) {
      grid.addEventListener('click', (event) => {
        const button = event.target.closest('[data-material-action]');
        if (!button) return;
        const card = button.closest('[data-material-id]');
        const id = card ? Number(card.getAttribute('data-material-id')) : null;
        const action = button.getAttribute('data-material-action');
        if (!id) return;
        if (action === 'detail') openDetail(id);
        if (action === 'edit') openEditor(id);
        if (action === 'delete') deleteMaterial(id);
      });
    }
    const pages = $('#material-pagination-buttons');
    if (pages) {
      pages.addEventListener('click', (event) => {
        const button = event.target.closest('[data-material-page]');
        if (!button || button.disabled) return;
        state.page = Number(button.getAttribute('data-material-page')) || 1;
        loadMaterials();
      });
    }
    const clear = $('#material-clear-filters');
    if (clear) {
      clear.addEventListener('click', () => {
        state.keyword = '';
        state.type = '';
        state.categoryId = null;
        state.tagIds.clear();
        if (search) search.value = '';
        if (type) type.value = '';
        renderTagTree();
        resetPageAndLoad();
      });
    }
    const refresh = $('#material-refresh');
    if (refresh) refresh.addEventListener('click', loadMaterials);
    const add = $('#material-add');
    if (add) add.addEventListener('click', () => openEditor(null));
    const save = $('#material-save');
    if (save) save.addEventListener('click', saveMaterial);
    const detailEdit = $('#material-detail-edit');
    if (detailEdit) {
      detailEdit.addEventListener('click', () => {
        global.AdminApp.closeModal('modal-material-detail');
        openEditor(state.detailId);
      });
    }
    const detailHistory = $('#material-detail-history');
    if (detailHistory) {
      detailHistory.addEventListener('click', () =>
        openVersions(state.detailId),
      );
    }
    const versionList = $('#material-version-list');
    if (versionList) {
      versionList.addEventListener('click', (event) => {
        const button = event.target.closest('[data-restore-version]');
        if (!button) return;
        restoreVersion(
          Number(button.getAttribute('data-material-id')),
          Number(button.getAttribute('data-restore-version')),
        );
      });
    }
  }

  async function init() {
    bind();
    state.loading = true;
    renderGrid();
    try {
      await loadTaxonomy();
    } catch (error) {
      const fallback =
        '<div class="material-tree-empty">分类字典加载失败，请刷新重试</div>';
      const category = $('#material-category-tree');
      const tags = $('#material-tag-tree');
      if (category) category.innerHTML = fallback;
      if (tags) tags.innerHTML = fallback;
    }
    state.loading = false;
  }

  global.AdminPages.materials = { init, load: loadMaterials, state };
})(window);
