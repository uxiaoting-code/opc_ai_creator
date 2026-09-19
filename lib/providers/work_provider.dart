import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/work_model.dart';
import '../data/repositories/work_repository.dart';

/// 作品状态管理。
///
/// 首页「最近生成作品」横滑区与作品画廊页共用。
///
/// **分页状态放在这里而不是画廊页里**：两个页面看的是同一份作品列表，
/// 如果画廊自己再维护一份，用户在画廊刷新后回首页会看到旧数据。
/// 放在 Provider 里就是单一数据源，首页的 `recentWorks`（取前 8 条）
/// 天然跟着更新。
class WorkProvider extends ChangeNotifier {
  WorkProvider({required this._repository});

  final WorkRepository _repository;

  /// 每页条数。首屏与「上拉加载下一页」共用，保证分页边界一致。
  static const int pageSize = 20;

  List<WorkModel> _works = const [];
  bool _isLoading = false;
  String? _error;

  /// 已加载到第几页。0 表示还没成功加载过首页。
  int _page = 0;

  /// 是否还有下一页。
  bool _hasMore = true;

  /// 是否正在加载下一页（画廊底部转圈用）。
  bool _isLoadingMore = false;

  /// 加载下一页时的错误。**单独一个字段**，不写进 [_error] ——
  /// 那个字段会让首页以为整份列表都挂了，而实际上只是"下一页没拉到"。
  String? _loadMoreError;

  List<WorkModel> get works => _works;

  bool get isLoading => _isLoading;

  String? get error => _error;

  /// 是否还有下一页。
  bool get hasMore => _hasMore;

  /// 是否正在加载下一页。
  bool get isLoadingMore => _isLoadingMore;

  /// 加载下一页失败的原因，画廊底部展示 + 重试。
  String? get loadMoreError => _loadMoreError;

  /// 首页横滑区展示的最近作品。
  List<WorkModel> get recentWorks => _works.take(8).toList();

  /// 是否一件作品都没有（区分「空列表」和「加载失败」两种状态）。
  bool get isEmpty => !_isLoading && _error == null && _works.isEmpty;

  Future<void> loadIfNeeded() async {
    if (_works.isNotEmpty || _isLoading) return;
    await load();
  }

  /// 加载第一页（刷新）。会把分页状态重置回起点。
  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _works.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    _loadMoreError = null;
    notifyListeners();

    try {
      final list = await _repository.fetchMyWorks(page: 1, pageSize: pageSize);
      _works = list;
      _page = 1;
      // 返回条数不足一页，说明后面没有了
      _hasMore = list.length >= pageSize;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      if (force && _works.isEmpty) _works = const [];
    } catch (e) {
      _error = '加载作品失败：$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);

  /// 加载下一页并追加（画廊上拉分页）。
  ///
  /// 重复调用是安全的：`_isLoadingMore` 挡住并发，`_hasMore` 挡住到底之后再拉。
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _page == 0) return;

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final next = await _repository.fetchMyWorks(
        page: _page + 1,
        pageSize: pageSize,
      );

      if (next.isEmpty) {
        _hasMore = false;
      } else {
        // 按 id 去重：分页期间如果有新作品落库，下一页可能和上一页有重叠，
        // 不去重的话网格里会出现两张一模一样的卡片。
        final existing = _works.map((w) => w.id).toSet();
        final fresh = next.where((w) => !existing.contains(w.id)).toList();
        _works = [..._works, ...fresh];
        _page++;
        _hasMore = next.length >= pageSize;
      }
    } on ApiException catch (e) {
      _loadMoreError = e.message;
    } catch (e) {
      _loadMoreError = '加载更多失败：$e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 本地插入一件新作品（生成成功后立即看到），避免等下一次刷新。
  void insertWork(WorkModel work) {
    _works = [work, ..._works];
    notifyListeners();
  }

  /// 按 id 在**已加载的作品**里找。找不到返回 null。
  ///
  /// 注意 null 只表示"本地这份列表里没有"，**不代表这件作品不存在** ——
  /// 它可能还在后面没翻到的分页里。要确认是否存在请用 [ensureWork]。
  WorkModel? findById(int? id) {
    if (id == null) return null;
    for (final work in _works) {
      if (work.id == id) return work;
    }
    return null;
  }

  /// 取指定作品，本地没有就回后端拉一次。
  ///
  /// 为什么需要单独拉：Web 上 `/gallery/12` 是可以直接粘贴访问的深链接，
  /// 也能直接刷新浏览器。这两种情况下作品列表可能压根还没加载，
  /// 或者那件作品被分页到了后面几页 —— 只查本地列表会得出
  /// "作品不存在"这种**假结论**。
  ///
  /// 拉到之后并进列表，用户返回画廊时数据也是全的。
  /// 作品确实不存在时返回 null（后端抛的 NOT_FOUND 由调用方处理）。
  Future<WorkModel?> ensureWork(int id) async {
    final cached = findById(id);
    if (cached != null) return cached;

    final work = await _repository.fetchWorkDetail(id);
    if (work == null) return null;



    // 拉到之后再查一次：并发两次 ensureWork 时避免插入重复项
    if (findById(work.id) == null) {
      _works = [work, ..._works];
      notifyListeners();
    }
    return work;
  }
}
