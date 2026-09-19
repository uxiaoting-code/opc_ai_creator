import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/state_views.dart';

/// 页面 5：我的任务列表页（Harness 任务状态）
///
/// 这是 Harness 调度系统在前端的主视图：任务创建后进入「排队」，
/// 后端调度器把它推到「生成中」，最终落到「成功」或「失败」。
/// 失败的任务可以一键重试，排队中的可以取消。
///
/// 三个关键设计：
/// - **筛选走后端**：`GET /api/tasks` 本身支持 status 参数，
///   本地过滤的话"只看失败"就得先把所有任务拉下来。
/// - **轮询只更新还在跑的那几条**（原地替换），不重新拉整个列表 ——
///   否则每 3 秒把用户翻出来的分页清掉一次，列表会不停跳回第一页。
/// - **页面销毁时停掉定时器**，否则 Timer 会一直持有 State 引用。
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  /// 每页条数。
  static const int _pageSize = 10;

  /// 顶部筛选。`null` 表示「全部」。
  ///
  /// 顺序与状态机的自然流程一致：排队 → 生成中 → 成功 / 失败。
  static const List<TaskStatus?> _filters = [
    null,
    TaskStatus.queued,
    TaskStatus.running,
    TaskStatus.success,
    TaskStatus.failed,
  ];

  /// 仓库在 initState 里取好，之后所有异步流程都不再碰 context ——
  /// 从根上避免「await 之后用 context」这一类问题。
  late final TaskRepository _repo;

  final ScrollController _scrollController = ScrollController();
  final List<TaskModel> _tasks = [];

  TaskStatus? _status;

  int _page = 0;
  bool _hasMore = true;

  /// 首屏加载中（只有列表还空的时候才整页转圈）。
  bool _loading = true;

  bool _loadingMore = false;

  /// 正在执行重试 / 取消，防止连点。
  bool _acting = false;

  String? _error;
  String? _loadMoreError;

  /// 轮询定时器。**必须在 dispose 里取消**，否则页面销毁后它仍按周期回调，
  /// 持续持有 State 引用（内存泄漏），并对已卸载的页面调 setState 报错刷屏。
  Timer? _pollTimer;

  /// 一轮轮询还没结束，防止后端慢时叠加下一轮。
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    // Provider 的 read 在 initState 里是允许的（只查找、不订阅，
    // 不会在 build 期间标记依赖组件为脏）
    _repo = context.read<TaskRepository>();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstPage());
  }

  @override
  void dispose() {
    _stopPolling();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 加载
  // ===========================================================================

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
      _loadMoreError = null;
    });

    try {
      final result = await _repo.fetchTasks(
        status: _status,
        page: 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(result.list);
        _page = 1;
        _hasMore = result.hasMore;
        _loading = false;
      });
      _syncPolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载任务失败：$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;

    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });

    try {
      final result = await _repo.fetchTasks(
        status: _status,
        page: _page + 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        // 分页期间有新任务落库时两页可能重叠，按 id 去重
        final existing = _tasks.map((t) => t.id).toSet();
        _tasks.addAll(result.list.where((t) => !existing.contains(t.id)));
        _page++;
        _hasMore = result.hasMore;
      });
      _syncPolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadMoreError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadMoreError = '加载更多失败：$e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _changeFilter(TaskStatus? value) {
    if (_status == value) return;
    setState(() => _status = value);
    _loadFirstPage();
  }

  // ===========================================================================
  // 轮询进行中的任务
  // ===========================================================================

  /// 只要有任务没到终态就开着定时器，全跑完就停。
  void _syncPolling() {
    final hasActive = _tasks.any((t) => !t.finished);
    if (!hasActive) {
      _stopPolling();
      return;
    }
    _pollTimer ??= Timer.periodic(
      AppConfig.taskPollInterval,
      (_) => _pollActiveTasks(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// 只轮询「还没结束」的那几条，拿到新状态后**原地替换**。
  ///
  /// 为什么不重新拉整个列表：那样每 3 秒就会把用户已经翻出来的分页清掉一次，
  /// 列表会不停跳回第一页，根本没法用。
  Future<void> _pollActiveTasks() async {
    if (_polling) return;
    _polling = true;

    try {
      final active = _tasks.where((t) => !t.finished).toList();
      for (final task in active) {
        try {
          final fresh = await _repo.fetchDetail(task.id);
          if (!mounted) return;
          final index = _tasks.indexWhere((t) => t.id == fresh.id);
          if (index >= 0) {
            setState(() => _tasks[index] = fresh);
          }
        } on ApiException {
          // 单条失败直接忽略：任务可能刚好被删了，或这一两次请求抖动。
          // 下一轮自然会恢复，不值得打断用户。
        }
      }
      if (!mounted) return;
      // 这一轮下来可能全都跑完了，收掉定时器
      _syncPolling();
    } finally {
      _polling = false;
    }
  }

  // ===========================================================================
  // 重试 / 取消
  // ===========================================================================

  Future<void> _retry(TaskModel task) =>
      _runAction(() => _repo.retryTask(task.id), successMessage: '已重新排队');

  Future<void> _cancel(TaskModel task) async {
    // 取消会让任务终止，属于不可逆操作，先确认
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('取消任务'),
        content: const Text('取消后任务不会产生作品，确定要取消吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('再想想'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确定取消'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(() => _repo.cancelTask(task.id), successMessage: '任务已取消');
  }

  /// 重试 / 取消共用的执行流程：调接口 → 原地更新那条 → 提示。
  ///
  /// 失败一定要弹出来。之前这类操作是静默的，用户点了没反应，
  /// 只能靠反复刷新才看得出到底成没成。
  Future<void> _runAction(
    Future<TaskModel> Function() action, {
    required String successMessage,
  }) async {
    if (_acting) return;
    setState(() => _acting = true);

    try {
      final updated = await action();
      if (!mounted) return;
      final index = _tasks.indexWhere((t) => t.id == updated.id);
      if (index >= 0) {
        setState(() => _tasks[index] = updated);
      }
      _showMessage(successMessage);
      // 重试会把任务丢回队列，需要重新开始轮询
      _syncPolling();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('操作失败：$e');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDetail(TaskModel task) {
    // 任务详情是**任务分支自己的子路由**（`/tasks/:taskId`），
    // 已经在任务列表上要进它的子路由时要用 push，不能 go ——
    // 与画廊页 `_openDetail` 同一个原因：go 到「当前分支路径的子路径」时，
    // 路由匹配表里会出现重复的 RouteMatch，同一个页面 key 被塞进同一个
    // Navigator 两次，触发 `!keyReservation.contains(key)` 断言红屏。
    context.push(RouteNames.taskDetailOf(task.id));
  }

  // ===========================================================================
  // 构建
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的任务'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loading ? null : _loadFirstPage,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFirstPage,
                color: AppColors.primary,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      // 用 Wrap 而不是 Row：芯片在窄屏上会自动折行
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          for (final filter in _filters)
            ChoiceChip(
              label: Text(filter?.label ?? '全部'),
              selected: _status == filter,
              onSelected: (_) => _changeFilter(filter),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // ---- 首次加载 ----
    if (_loading && _tasks.isEmpty) {
      return const LoadingView(message: '正在加载任务…');
    }

    // ---- 加载失败且一条都没有 ----
    if (_error != null && _tasks.isEmpty) {
      return ErrorView(message: _error!, onRetry: _loadFirstPage);
    }

    // ---- 空数据（也要能下拉刷新，所以包一层可滚动）----
    if (_tasks.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.receipt_long_rounded,
              title: _status == null ? '还没有任务' : '没有${_status!.label}的任务',
              description: _status == null
                  ? '去「文生图」或「图生视频」创作第一件作品吧'
                  : '换一个筛选条件试试',
            ),
          ),
        ],
      );
    }

    // ---- 列表 ----
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      itemCount: _tasks.length + 1, // 末尾多一格放「加载更多」状态
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == _tasks.length) return _buildFooter();

        final task = _tasks[index];
        return _TaskCard(
          task: task,
          busy: _acting,
          onTap: () => _openDetail(task),
          onRetry: task.canRetry ? () => _retry(task) : null,
          onCancel: task.canCancel ? () => _cancel(task) : null,
        );
      },
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);

    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            Text(
              _loadMoreError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: _loadMore, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Text('— 没有更多了 —', style: theme.textTheme.bodySmall),
        ),
      );
    }

    return const SizedBox(height: AppSpacing.lg);
  }
}

// =============================================================================
// 任务卡片
// =============================================================================

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.busy,
    required this.onTap,
    this.onRetry,
    this.onCancel,
  });

  final TaskModel task;

  /// 有操作正在执行，禁用按钮防连点。
  final bool busy;

  final VoidCallback onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(task.status);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.lightBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 缩略图：成功后是结果图，没出结果时是渐变占位
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CoverImage(
                        seed: 'task_${task.id}',
                        url: _thumbUrlOf(task),
                        icon: task.type.isVideo
                            ? Icons.movie_outlined
                            : Icons.image_outlined,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 提示词是后端拼过线路模板的最终提示词，取首段当标题
                          Text(
                            _titleOf(task),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              task.typeLabel ?? task.type.label,
                              if (task.skillName != null) task.skillName!,
                              TimeUtils.relative(task.createdAt),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip(label: task.displayStatusLabel, color: color),
                  ],
                ),

                // 生成中：进度条 + 百分比
                if (task.status == TaskStatus.running) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: LinearProgressIndicator(
                      value: task.progressRatio,
                      minHeight: 5,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text('${task.progress}%', style: theme.textTheme.bodySmall),
                      const Spacer(),
                      if (task.durationLabel != null)
                        Text('已耗时 ${task.durationLabel}',
                            style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],

                // 失败原因：直接展示后端给的 errorMsg
                if (task.status == TaskStatus.failed &&
                    task.errorMsg != null &&
                    task.errorMsg!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    task.errorMsg!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.statusFailed,
                    ),
                  ),
                ],

                // 可重试 / 可取消时才出现操作区。
                // 判据用后端给的 canRetry / canCancel ——
                // 状态机规则只有后端一份，前端不要自己再算一遍。
                if (onRetry != null || onCancel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  // 用 Wrap 而不是 Row：按钮含内部 Flexible，
                  // 在 Row 里会拿到无限宽约束而报错
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (onCancel != null)
                        TextButton(
                          onPressed: busy ? null : onCancel,
                          child: const Text('取消任务'),
                        ),
                      if (onRetry != null)
                        FilledButton.tonal(
                          onPressed: busy ? null : onRetry,
                          child: const Text('重新生成'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 缩略图地址。后端给的是 `/upload/xxx.png` 相对路径，要拼成绝对地址。
  static String? _thumbUrlOf(TaskModel task) {
    final raw = task.displayImageUrl;
    if (raw == null || raw.isEmpty) return null;
    return AppConfig.resolveAssetUrl(raw);
  }

  /// 卡片标题：取提示词首段。后端已经把线路模板拼进 prompt 了，
  /// 所以这里展示的就是最终送去生成的那句话。
  static String _titleOf(TaskModel task) {
    final prompt = task.prompt;
    if (prompt == null || prompt.isEmpty) return '未命名任务';
    final trimmed = prompt.trim();
    return trimmed.length > 24 ? '${trimmed.substring(0, 24)}…' : trimmed;
  }
}

/// 状态色映射，与任务详情页、[StatusChip] 保持同一套视觉语言。
Color _statusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.queued:
      return AppColors.statusQueued;
    case TaskStatus.running:
      return AppColors.statusRunning;
    case TaskStatus.success:
      return AppColors.statusSuccess;
    case TaskStatus.failed:
      return AppColors.statusFailed;
    case TaskStatus.canceled:
      return AppColors.statusCanceled;
  }
}
