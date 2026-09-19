import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../widgets/media/media_viewers.dart';
import '../../widgets/scaffold_page.dart';
import '../../widgets/state_views.dart';

/// 页面 13：任务详情页
///
/// 路由带参：`/tasks/:taskId`
/// 因为是「任务」这个 Tab 分支下的子路由，push 进来后底部导航栏仍在，
/// 用户在详情页也能直接切到画廊 —— 这是 StatefulShellRoute 带来的体验。
///
/// **这个页面是 Harness 在用户侧最直接的体现**：
/// 提交任务时后端只返回一个「排队中」的任务，真正的生成过程在这里被看见 ——
/// 页面按 [AppConfig.taskPollInterval] 定时拉 `GET /api/tasks/{id}`，
/// 把「排队 → 生成中 → 成功/失败」的流转实时画出来。
///
/// 轮询的停止条件有两个，缺一不可：
/// 1. 任务到达终态（后端返回的 `finished == true`）；
/// 2. 页面被销毁（`dispose` 里取消 Timer）。
class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.taskId});

  /// 从路径参数拿到的任务 ID。
  final String taskId;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  /// 轮询定时器。**必须在 dispose 里取消**，
  /// 否则页面销毁后 Timer 依然按周期回调，持续持有 State 引用
  /// （内存泄漏），并且会一直对已销毁的页面调 setState 而报错刷屏。
  Timer? _pollTimer;

  TaskModel? _task;

  /// 首屏加载中（只有第一次进页面显示整页 loading，轮询刷新不显示）。
  bool _loading = true;

  /// 轮询请求进行中：防止后端响应慢时上一轮还没回来就叠加下一次，
  /// 否则请求会越堆越多。
  bool _polling = false;

  /// 首屏加载失败的错误信息。轮询期间的偶发失败不覆盖页面内容。
  String? _error;

  /// 轮询连续失败次数。> 0 表示「页面上显示的状态可能已经不是最新的」。
  int _pollFailures = 0;

  /// 最近一次轮询失败的原因，展示在页面顶部的提示条里。
  ///
  /// 为什么必须有这个：轮询是后台行为，失败时如果只 debugPrint，
  /// 用户看到的会是一个永远停在「生成中」的页面 —— 既不知道网络断了，
  /// 也不知道服务端其实早就报错了。**失败必须可见。**
  String? _pollError;

  /// 任务 ID 解析失败时的提示（用户手改地址栏会走到这里）。
  String? _invalidIdMessage;

  int? _taskIdValue;

  @override
  void initState() {
    super.initState();
    _taskIdValue = int.tryParse(widget.taskId);
    if (_taskIdValue == null) {
      _invalidIdMessage = '任务 ID 不合法：${widget.taskId}';
      _loading = false;
      return;
    }
    _loadFirstTime();
  }

  @override
  void dispose() {
    // 关键：一定要停掉轮询。这是「轮询不泄漏」的唯一保障点。
    _stopPolling();
    super.dispose();
  }

  // ===========================================================================
  // 数据加载
  // ===========================================================================

  /// 首屏加载：显示整页 loading，失败时显示整页错误 + 重试。
  ///
  /// 也用于 AppBar 上的手动刷新，此时页面上已经有内容了 ——
  /// 这两种情况的失败**必须区别对待**：
  /// - 首屏失败 → 整页 [ErrorView]（页面上本来就没东西，直接把错误铺满）；
  /// - 刷新失败 → SnackBar 弹窗（有内容时不能整页覆盖，但更不能什么都不说）。
  Future<void> _loadFirstTime() async {
    // 判据放在开头：后面 setState 会改 _loading，别把它当成"这是首屏"的依据
    final isRefresh = _task != null;

    setState(() {
      _loading = true;
      // 首屏才清错误，刷新时清掉会让已有的 ErrorView 闪一下
      if (!isRefresh) _error = null;
    });

    try {
      final task = await _fetch();
      if (!mounted) return;
      setState(() {
        _task = task;
        _loading = false;
        _error = null;
      });
      _clearPollFailure();
      _syncPolling(task);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (isRefresh) {
        _showMessage(e.message);
      } else {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (isRefresh) {
        _showMessage('刷新失败：$e');
      } else {
        setState(() => _error = '加载任务失败：$e');
      }
    }
  }

  /// 轮询一次：静默刷新，不显示 loading，但也**不能把错误吞掉**。
  Future<void> _pollOnce() async {
    if (_polling) return;
    _polling = true;

    try {
      final task = await _fetch();
      if (!mounted) return;
      setState(() => _task = task);
      // 这一轮通了，说明之前的中断已经恢复，提示条要收掉
      _clearPollFailure();
      _syncPolling(task);
    } on ApiException catch (e) {
      if (!mounted) return;
      // 任务不存在属于「永久性失败」：再轮询一万次也还是 404，
      // 直接停掉定时器，避免页面在后台空转刷请求。
      final permanent = e.code == _taskNotFoundCode || e.statusCode == 404;
      _registerPollFailure(e.message, permanent: permanent);
    } catch (e) {
      if (!mounted) return;
      _registerPollFailure('刷新任务状态失败：$e');
    } finally {
      _polling = false;
    }
  }

  // ===========================================================================
  // 错误提示
  // ===========================================================================

  /// 后端 `ErrorCode.TASK_NOT_FOUND`，与 ErrorCode.java 保持一致。
  static const int _taskNotFoundCode = 3001;

  /// 记一次轮询失败，并保证**用户看得见**。
  ///
  /// 弹窗只在「从正常掉到失败」的那一刻弹一次（`wasHealthy`）：
  /// 轮询是每 3 秒一次的后台行为，每次都弹会把屏幕刷爆，
  /// 反而盖住真正有用的信息。持续失败期间靠页面顶部的提示条常驻提醒。
  void _registerPollFailure(String message, {bool permanent = false}) {
    if (!mounted) return;

    final wasHealthy = _pollFailures == 0;
    setState(() {
      _pollFailures++;
      _pollError = message;
    });

    if (wasHealthy) {
      _showMessage(permanent ? message : '$message（正在自动重试）');
    }
    if (permanent) {
      _stopPolling();
    }
  }

  /// 轮询恢复正常：清掉失败计数与提示条。
  void _clearPollFailure() {
    if (_pollFailures == 0 && _pollError == null) return;
    setState(() {
      _pollFailures = 0;
      _pollError = null;
    });
  }

  /// 统一的提示弹窗。全项目的错误提示都走 SnackBar，
  /// 保证「同一个错误在哪个页面看起来都一样」。
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<TaskModel> _fetch() {
    final id = _taskIdValue;
    if (id == null) {
      throw const ApiException(message: '任务 ID 不合法');
    }
    return context.read<TaskRepository>().fetchDetail(id);
  }

  // ===========================================================================
  // 轮询开关
  // ===========================================================================

  /// 根据任务当前状态决定「继续轮询」还是「停止」。
  ///
  /// 判定只用后端返回的 `finished` 字段 ——
  /// 状态机规则在后端只有一份（`TaskStatus.isTerminal()`），
  /// 前端不再自己实现一遍，避免两端对「什么算结束」理解不一致。
  void _syncPolling(TaskModel task) {
    if (task.finished) {
      _stopPolling();
    } else {
      _startPolling();
    }
  }

  void _startPolling() {
    if (_pollTimer != null) return; // 已经在轮询了，不要重复起
    _pollTimer = Timer.periodic(
      AppConfig.taskPollInterval,
      (_) => _pollOnce(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ===========================================================================
  // 构建
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // 已有内容时的手动刷新不会整页转圈（那会把结果图盖掉），
    // 所以把"正在刷新"画在刷新按钮本身上，否则点了会像没反应。
    final refreshing = _loading && _task != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          // 手动刷新：轮询间隔内想立刻看结果时用，也方便演示
          IconButton(
            tooltip: '刷新',
            onPressed: (_taskIdValue == null || refreshing)
                ? null
                : () {
                    _loadFirstTime();
                  },
            icon: refreshing
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
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    // ---- 非法 ID ----
    if (_invalidIdMessage != null) {
      return ErrorView(message: _invalidIdMessage!);
    }

    // ---- 首屏加载中 ----
    if (_loading && _task == null) {
      return const LoadingView(message: '正在加载任务…');
    }

    // ---- 首屏加载失败 ----
    if (_error != null && _task == null) {
      return ErrorView(message: _error!, onRetry: _loadFirstTime);
    }

    final task = _task;
    if (task == null) {
      return const EmptyView(
        icon: Icons.receipt_long_rounded,
        title: '任务不存在',
        description: '它可能已被删除',
      );
    }

    // 底部留出空间，避免最后一个卡片贴着屏幕边
    return MobileScaffoldBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 轮询失败提示条：置顶显示，因为它意味着「下面这些内容可能已经过期」。
          // 不清空页面内容是对的（任务大概率已经生成完了，只是这一两次请求抖动），
          // 但必须让用户知道看到的状态不是最新的。
          if (_pollError != null) ...[
            _PollErrorBanner(
              message: _pollError!,
              failures: _pollFailures,
              onRetry: _loading ? null : _loadFirstTime,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _StatusCard(task: task),
          const SizedBox(height: AppSpacing.lg),
          ..._buildStateSection(task),
          const SizedBox(height: AppSpacing.lg),
          _PromptsCard(task: task),
          const SizedBox(height: AppSpacing.lg),
          _MetaCard(task: task),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// 按状态渲染可变区域：生成中显示进度、成功显示结果图、失败显示错误原因。
  List<Widget> _buildStateSection(TaskModel task) {
    switch (task.status) {
      case TaskStatus.success:
        return [
          // 产出物按任务类型分流：图生视频给出的是 MP4，
          // 拿 AppNetworkImage 去加载会渲染成破图。
          if (task.type.isVideo)
            _VideoResultSection(task: task)
          else
            _ResultSection(task: task),
          const SizedBox(height: AppSpacing.lg),
        ];

      case TaskStatus.failed:
        return [
          _ErrorSection(task: task),
          const SizedBox(height: AppSpacing.lg),
        ];

      case TaskStatus.canceled:
        return [
          _NoticeSection(
            icon: Icons.cancel_outlined,
            color: AppColors.statusCanceled,
            title: '任务已取消',
            message: '取消的任务不会产生作品。需要的话可以回到创作页重新提交。',
          ),
          const SizedBox(height: AppSpacing.lg),
        ];

      case TaskStatus.queued:
        return [
          _NoticeSection(
            icon: Icons.hourglass_empty_rounded,
            color: AppColors.statusQueued,
            title: '排队等待调度',
            message: 'Harness 调度器每 3 秒扫描一次队列，'
                '当前有并发上限，稍等片刻就会开始生成。',
          ),
          const SizedBox(height: AppSpacing.lg),
        ];

      case TaskStatus.running:
        // 生成中：进度条 + 等待动画由 _StatusCard 负责，这里只补一句说明
        return [
          _NoticeSection(
            icon: Icons.auto_awesome,
            color: AppColors.statusRunning,
            title: 'AI 正在生成',
            message: '页面每 ${AppConfig.taskPollInterval.inSeconds} 秒'
                '自动刷新一次状态，可以直接离开，任务在后台继续跑。',
          ),
          const SizedBox(height: AppSpacing.lg),
        ];
    }
  }
}

// =============================================================================
// 状态大卡：状态标签 + 进度 + 任务号
// =============================================================================

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(task.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusChip(
                label: task.displayStatusLabel,
                color: color,
              ),
              const Spacer(),
              Text(
                task.typeLabel ?? task.type.label,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 进度条：生成中显示真实进度，终态显示满格或空
          if (task.status == TaskStatus.running) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: LinearProgressIndicator(
                value: task.progressRatio,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('${task.progress}%', style: theme.textTheme.bodySmall),
                const Spacer(),
                if (task.durationLabel != null)
                  Text('已耗时 ${task.durationLabel}',
                      style: theme.textTheme.bodySmall),
              ],
            ),
          ] else
            Text(
              '${task.progress}%',
              style: theme.textTheme.bodySmall,
            ),

          const Divider(height: AppSpacing.xl),

          _KvRow(label: '任务编号', value: task.taskNo, monospace: true),
          const SizedBox(height: AppSpacing.sm),
          _KvRow(
            label: '创建时间',
            value: _formatTime(task.createdAt),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 结果区：成功时展示生成的图片
// =============================================================================

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final raw = task.displayImageUrl;
    // 后端返回的是 /upload/xxx.png 这种相对路径，
    // 必须用 resolveAssetUrl 拼成完整地址才加载得到
    final url = AppConfig.resolveAssetUrl(raw);

    if (url.isEmpty) {
      return _NoticeSection(
        icon: Icons.image_not_supported_outlined,
        color: AppColors.statusFailed,
        title: '没有拿到结果图',
        message: '任务已成功但结果地址为空，请到「我的任务」重新查看。',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 16, color: AppColors.statusSuccess),
            const SizedBox(width: AppSpacing.sm),
            Text('生成结果', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              '点击可放大查看',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          // 用项目自带的图片预览页（InteractiveViewer 实现，支持双指缩放）
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ImagePreviewPage(
                imageUrl: url,
                title: '生成结果',
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            // 用 BoxFit.contain 而不是 cover：生成图里画着提示词文字，
            // cover 会把边缘裁掉。这里固定高度、按比例缩放，画面完整可见。
            // （TaskResponse 没有返回宽高，所以不能按真实宽高比撑开盒子）
            child: SizedBox(
              height: 320,
              child: AppNetworkImage(url: url, fit: BoxFit.contain),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 结果区（视频）：成功时展示可播放的视频
// =============================================================================

/// 图生视频任务的结果区。
///
/// **刻意做成独立的 StatefulWidget 而不是把播放器塞进 `_TaskDetailPageState`。**
/// 原因：视频控制器的生命周期和「轮询」完全是两回事 —— 轮询属于页面，
/// 播放器只属于「结果区在不在屏幕上」。放在一起的话，页面销毁、任务从成功
/// 被改成失败、重试后换了新链接……每种情况都要在页面里额外判断一次要不要
/// 释放控制器，很容易漏掉一个分支就把 controller 泄漏掉。
/// 独立成组件后，Flutter 自己的挂载/卸载语义就是它的生命周期，天然不会漏。
class _VideoResultSection extends StatefulWidget {
  const _VideoResultSection({required this.task});

  final TaskModel task;

  @override
  State<_VideoResultSection> createState() => _VideoResultSectionState();
}

class _VideoResultSectionState extends State<_VideoResultSection> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  /// 正在初始化播放器（拉取视频头、准备解码器）。
  bool _initializing = true;

  /// 初始化失败原因。播放器本身报的错由 Chewie 的 errorBuilder 呈现。
  String? _error;

  /// 拼好的完整视频地址。后端给的是 `/upload/xxx.mp4` 相对路径。
  String get _url => AppConfig.resolveAssetUrl(widget.task.resultUrl);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _VideoResultSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 轮询期间父组件会反复重建这个区块。只有**地址真的变了**才重新初始化
    // （比如重试后又生成了一段新的），否则每 3 秒就把播放器重建一次，
    // 画面会不停跳回第一帧 —— 看起来像播放器坏了。
    if (oldWidget.task.resultUrl != widget.task.resultUrl) {
      _disposeControllers();
      _initialize();
    }
  }

  Future<void> _initialize() async {
    if (_url.isEmpty) {
      setState(() {
        _error = '任务已成功，但服务端没有返回视频地址';
        _initializing = false;
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(_url));
      _videoController = controller;

      await controller.initialize();
      // await 期间用户可能已经离开页面，此时 controller 已被 dispose
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        // 演示用的模拟视频只有 3 秒，循环播放才看得出「它在动」
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        aspectRatio: controller.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.secondary,
          bufferedColor: AppColors.primary.withValues(alpha: 0.3),
          backgroundColor: Colors.white24,
        ),
        // 播放器内部的错误（解码失败、404）走这里，和下面的初始化失败分开呈现
        errorBuilder: (context, message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              '视频播放失败\n$message',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ),
        ),
      );

      setState(() => _initializing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '视频加载失败：$e';
        _initializing = false;
      });
    }
  }

  /// 释放两个控制器。顺序不能反：Chewie 持有底层 VideoPlayerController 的引用，
  /// 先放底层会留下悬空引用。
  void _disposeControllers() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 16, color: AppColors.statusSuccess),
            const SizedBox(width: AppSpacing.sm),
            Text('生成结果', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text('点击画面可全屏', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildPlayer(theme),
      ],
    );
  }

  Widget _buildPlayer(ThemeData theme) {
    if (_error != null) {
      return _NoticeSection(
        icon: Icons.videocam_off_outlined,
        color: AppColors.statusFailed,
        title: '视频无法播放',
        message: _error!,
      );
    }

    if (_initializing) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text('正在准备播放器…'),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        // 播放器自带黑色背景与控制条，不再包一层装饰
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}

// =============================================================================
// 失败区：展示后端返回的 errorMsg
// =============================================================================

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // errorMsg 是后端为了让用户看懂而写的（不是异常堆栈），
    // 直接展示即可；为空时才回退到通用文案。
    final message = (task.errorMsg != null && task.errorMsg!.isNotEmpty)
        ? task.errorMsg!
        : '生成失败，但服务端没有返回具体原因';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusFailed.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.statusFailed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 18, color: AppColors.statusFailed),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '生成失败',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.statusFailed,
                ),
              ),
              const Spacer(),
              if (task.retryCount > 0)
                Text(
                  '已重试 ${task.retryCount}/${task.maxRetry}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: theme.textTheme.bodyMedium),
          if (task.canRetry) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '剩余可重试次数：${task.maxRetry - task.retryCount}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 通用提示块
// =============================================================================

class _NoticeSection extends StatelessWidget {
  const _NoticeSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 轮询中断提示条
// =============================================================================

/// 轮询失败时常驻在页面顶部的提示条。
///
/// 与 SnackBar 分工：SnackBar 只在「由好变坏」的那一刻弹一次，会自己消失；
/// 这个条子只要还在失败就一直挂着 —— 用户任何时候抬眼看，
/// 都知道下面的状态不是最新的，而不是被一个静止的「生成中」骗着干等。
class _PollErrorBanner extends StatelessWidget {
  const _PollErrorBanner({
    required this.message,
    required this.failures,
    this.onRetry,
  });

  /// 网络层归一后的错误原文（后端业务 message 或网络提示），直接上屏。
  final String message;

  /// 连续失败次数，让用户对「断了多久」有个量感。
  final int failures;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusFailed.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.statusFailed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_problem_rounded,
                  size: 18, color: AppColors.statusFailed),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '状态刷新中断',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.statusFailed,
                  ),
                ),
              ),
              if (failures > 1)
                Text('已失败 $failures 次', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '下方内容可能不是最新的，恢复后会自动刷新。',
            style: theme.textTheme.bodySmall,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: const Text('立即重试'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 输入参数回显
// =============================================================================

class _PromptsCard extends StatelessWidget {
  const _PromptsCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('生成参数', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),

          // 注意：这里展示的 prompt 是后端拼过线路模板之后的最终提示词
          // （任务创建时后端把用户输入套进了线路的风格前缀/后缀）。
          Text('最终提示词', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            (task.prompt == null || task.prompt!.isEmpty) ? '（空）' : task.prompt!,
            style: theme.textTheme.bodyMedium,
          ),

          if (task.negativePrompt != null && task.negativePrompt!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('反向提示词', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(task.negativePrompt!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('执行信息', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          if (task.skillName != null)
            _KvRow(label: '创作线路', value: task.skillName!),
          if (task.provider != null)
            _KvRow(label: 'AI 服务商', value: task.provider!),
          _KvRow(label: '排队时间', value: _formatTime(task.queueAt)),
          _KvRow(label: '开始时间', value: _formatTime(task.startAt)),
          _KvRow(label: '结束时间', value: _formatTime(task.finishAt)),
          if (task.durationLabel != null)
            _KvRow(label: '总耗时', value: task.durationLabel!),
        ],
      ),
    );
  }
}

// =============================================================================
// 小工具
// =============================================================================

/// 键值行。
class _KvRow extends StatelessWidget {
  const _KvRow({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyLarge?.color,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 状态色映射。
///
/// 颜色取自 [AppColors] 的语义色，与后端 `TaskStatus` 一一对应，
/// 也和任务列表页用的 [StatusChip] 保持同一套视觉语言。
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

/// 时间格式化：`09-15 21:30:05`。为空显示 `—`。
String _formatTime(DateTime? time) {
  if (time == null) return '—';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}
