import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/work_model.dart';
import '../../providers/work_provider.dart';
import '../../widgets/media/media_viewers.dart';
import '../../widgets/state_views.dart';

/// 页面 10：作品详情页
///
/// 路由带参：`/gallery/:workId`。Web 上地址栏会显示 `/gallery/12`，
/// 直接粘贴访问或刷新页面都能定位到同一件作品 ——
/// 这是选 go_router 而不是 Navigator 命名路由的直接收益。
///
/// 布局是「上媒体 + 下信息」：
/// - 媒体区固定占屏幕上半部分，黑底。图片用 [InteractiveViewer] 支持缩放，
///   视频用 chewie 播放器；
/// - 下方信息区可滚动，展示提示词与元信息。
///
/// 这样分的好处是**媒体区不参与滚动**，看图/看视频时不会有内容跟着晃。
///
/// 本轮只做「查看」：删除、分享、重新生成等操作不在范围内。
class WorkDetailPage extends StatefulWidget {
  const WorkDetailPage({super.key, required this.workId});

  /// 从路径参数拿到的作品 ID（字符串，需要自己解析）。
  final String workId;

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  /// 解析后的作品 ID，null 表示地址栏里的值不合法。
  int? _workId;

  bool _loading = true;
  String? _error;

  /// 本地列表里没有时，单独从后端拉到的那一份。
  ///
  /// 为什么不直接把它塞进 State 当唯一数据源：画廊的列表随时可能刷新，
  /// 而那才是"活的"数据。这里只作为**回退**，能在列表里找到就用列表里的。
  WorkModel? _fetched;

  @override
  void initState() {
    super.initState();

    // 地址栏是可编辑的，解析失败要给出提示而不是崩掉
    _workId = int.tryParse(widget.workId);
    if (_workId == null) {
      _error = '作品 ID 不合法：${widget.workId}';
      _loading = false;
      return;
    }

    // 放到首帧之后再触发：ensureWork 命中缓存时也会 notifyListeners()，
    // 在 initState 里同步触发会在 build 期间标记依赖组件为脏。
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = _workId;
    if (id == null || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final work = await context.read<WorkProvider>().ensureWork(id);
      if (!mounted) return;
      setState(() {
        _fetched = work;
        _loading = false;
        if (work == null) _error = '作品不存在或已被删除';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载作品失败：$e';
        _loading = false;
      });
    }
  }

  /// 返回画廊列表。
  ///
  /// 不能只依赖 AppBar 的自动返回键：Web 上直接粘贴 `/gallery/12` 打开、
  /// 或者刷新页面时，导航栈里根本没有上一页，自动返回键不会出现。
  /// 这里显式给一个，栈里有就 pop，没有就直接回画廊 —— 保证它永远可用。
  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.galleryPath);
    }
  }

  // ===========================================================================
  // 分享链接
  // ===========================================================================

  /// 当前页面在浏览器里的完整地址。
  ///
  /// ⚠️ **不能用 `Uri.base`**：它只在页面加载那一刻求值一次，
  /// SPA 内部跳转（从 `/gallery` 点进 `/gallery/12`）根本不会更新它，
  /// 复制出来的会是"进入应用时"的地址，而不是"现在看的这件作品"。
  ///
  /// 所以这里取两段拼：
  /// - `Uri.base.origin` —— 站点前缀（`http://localhost:1234`），这部分是稳定的；
  /// - `GoRouterState.uri` —— 当前路由（`/gallery/12`），跟着跳转实时更新。
  ///
  /// Flutter Web 默认走 **hash 路由策略**（地址栏形如 `/#/gallery/12`），
  /// 除非显式调用过 `usePathUrlStrategy()` —— 本项目没有调用，
  /// 所以中间要补一个 `/#`，否则拼出来的链接在浏览器里打不开。
  String _shareUrl(BuildContext context) {
    final route = GoRouterState.of(context).uri.toString();

    // 非 Web 平台没有"地址栏"这个概念，无法给出可分享的公网地址，
    // 退化成应用内路径，至少贴出来能看出是哪件作品。
    if (!kIsWeb) return route;

    return '${Uri.base.origin}/#$route';
  }

  /// 复制当前作品的分享链接到剪贴板。
  Future<void> _copyLink() async {
    final url = _shareUrl(context);

    try {
      await Clipboard.setData(ClipboardData(text: url));
    } catch (e) {
      // 浏览器可能因为"非用户手势触发"或权限策略拒绝写剪贴板。
      // 不能装作成功，要如实告诉用户并让他手动复制。
      if (!mounted) return;
      _showMessage('复制失败，请手动复制地址栏链接');
      if (kDebugMode) debugPrint('复制链接失败: $e');
      return;
    }

    if (!mounted) return;
    _showMessage('链接已复制，可以分享');
  }

  /// 统一提示（SnackBar）。全项目错误/成功提示都走这里，视觉一致。
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // 列表里找到就用列表里那份（跟着刷新走），否则用单独拉到的那份
    final provider = context.watch<WorkProvider>();
    final work = provider.findById(_workId) ?? _fetched;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回画廊',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
        ),
        title: Text(
          work?.displayTitle ?? '作品详情',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 复制分享链接
          IconButton(
            tooltip: '复制链接',
            icon: const Icon(Icons.link_rounded),
            onPressed: work == null ? null : _copyLink,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _buildBody(work),
      ),
    );
  }

  Widget _buildBody(WorkModel? work) {
    // ---- ID 不合法 ----
    if (_workId == null) {
      return ErrorView(message: _error ?? '作品 ID 不合法');
    }

    // ---- 还没有数据：区分"加载中"和"加载失败" ----
    if (work == null) {
      if (_error != null) {
        return ErrorView(message: _error!, onRetry: _load);
      }
      if (_loading) {
        return const LoadingView(message: '正在加载作品…');
      }
      return const EmptyView(
        icon: Icons.image_not_supported_outlined,
        title: '作品不存在',
        description: '它可能已被删除',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------- 媒体区（不参与滚动）----------
        SizedBox(
          height: _mediaHeight(context),
          child: ColoredBox(
            color: Colors.black,
            child: work.isVideo
                ? _WorkVideoPlayer(
                    url: AppConfig.resolveAssetUrl(work.resourceUrl),
                  )
                : _ZoomableImage(
                    url: AppConfig.resolveAssetUrl(work.resourceUrl),
                  ),
          ),
        ),

        // ---------- 信息区（可滚动）----------
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPromptCard(work),
                if (work.negativePrompt != null &&
                    work.negativePrompt!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InfoCard(
                    title: '反向提示词',
                    child: SelectableText(
                      work.negativePrompt!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _buildMetaCard(work),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 媒体区高度：占屏幕高度的 48%，并夹在一个合理区间里。
  ///
  /// 夹紧是为了两端都不难看：太矮（小屏）看不清楚，太高（Web 高窗口）
  /// 会把下面的提示词挤到屏幕外。
  double _mediaHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight * 0.48).clamp(220.0, 520.0);
  }

  Widget _buildPromptCard(WorkModel work) {
    final theme = Theme.of(context);
    final prompt = work.prompt;

    return _InfoCard(
      title: '提示词',
      // 提示用户这段文字可以选中复制（Web 上尤其有用）
      trailing: prompt == null || prompt.isEmpty
          ? null
          : Text('可选中复制', style: theme.textTheme.bodySmall),
      child: (prompt == null || prompt.isEmpty)
          ? Text('这件作品没有记录提示词', style: theme.textTheme.bodyMedium)
          // 用 SelectableText 而不是 Text：提示词是用户最想复制走的东西，
          // Web 上能直接框选复制，Android 上长按也能选。
          : SelectableText(prompt, style: theme.textTheme.bodyMedium),
    );
  }

  Widget _buildMetaCard(WorkModel work) {
    final theme = Theme.of(context);

    final size = (work.width != null && work.height != null)
        ? '${work.width} × ${work.height}'
        : null;

    final createdAt = TimeUtils.full(work.createdAt);

    return _InfoCard(
      title: '作品信息',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KvRow(label: '类型', value: work.type.label),
          if (work.skillName != null)
            _KvRow(label: '创作线路', value: work.skillName!),
          if (work.durationLabel != null)
            _KvRow(label: '视频时长', value: work.durationLabel!),
          if (size != null) _KvRow(label: '尺寸', value: size),
          _KvRow(label: '创建时间', value: createdAt.isEmpty ? '—' : createdAt),
          if (work.isPublic)
            _KvRow(label: '可见性', value: '已发布到公开画廊'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            work.isVideo ? '长按画面可全屏播放' : '双指缩放 / 滚轮可放大查看细节',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 图片：可缩放的预览
// =============================================================================

/// 可缩放的大图预览。
///
/// 用 Flutter 内置的 [InteractiveViewer]，**不引入任何第三方预览库**，
/// 天然同时支持 Android（双指）与 Web（触控板捏合 / Ctrl + 滚轮）。
class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const _MediaMessage(
        icon: Icons.image_not_supported_outlined,
        message: '没有可预览的图片地址',
      );
    }

    return InteractiveViewer(
      // 从原始大小开始，最多放大 5 倍
      minScale: 1,
      maxScale: 5,
      // 放大后允许拖动查看细节
      panEnabled: true,
      child: SizedBox.expand(
        // BoxFit.contain：完整显示画面，不裁掉任何部分
        child: AppNetworkImage(url: url, fit: BoxFit.contain),
      ),
    );
  }
}

// =============================================================================
// 视频：chewie 播放器
// =============================================================================

/// 作品视频播放器。
///
/// **独立成一个 StatefulWidget**，让控制器的生命周期跟着媒体区走。
/// 塞进页面的 State 里会和外层状态纠缠：页面重建、作品切换、
/// 提前返回……每个分支都得记得释放，漏一个就泄漏一个解码器。
class _WorkVideoPlayer extends StatefulWidget {
  const _WorkVideoPlayer({required this.url});

  /// 完整视频地址（已用 AppConfig.resolveAssetUrl 拼过）。
  final String url;

  @override
  State<_WorkVideoPlayer> createState() => _WorkVideoPlayerState();
}

class _WorkVideoPlayerState extends State<_WorkVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _WorkVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 地址变了才重建播放器，否则列表刷新导致的重建会把播放进度冲掉
    if (oldWidget.url != widget.url) {
      _disposeControllers();
      _initializing = true;
      _error = null;
      _initialize();
    }
  }

  Future<void> _initialize() async {
    if (widget.url.isEmpty) {
      setState(() {
        _error = '没有可播放的视频地址';
        _initializing = false;
      });
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _videoController = controller;

      await controller.initialize();
      // await 期间用户可能已经返回，此时 controller 已被 dispose
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: controller,

        // ⚠️ Web 兼容的关键一行：浏览器会拦截「带声音的自动播放」，
        // autoPlay: true 在 Chrome 上会静默失败 —— 视频停在第一帧不动，
        // 用户会以为播放器坏了。统一关掉自动播放，交给用户点播放键，
        // 两端行为一致，也不需要为了自动播放去静音。
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        aspectRatio: controller.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.secondary,
          bufferedColor: AppColors.primary.withValues(alpha: 0.3),
          backgroundColor: Colors.white24,
        ),
        // 解码失败 / 404 走这里，和下面的初始化失败分开呈现
        errorBuilder: (context, message) => _MediaMessage(
          icon: Icons.error_outline,
          message: '视频播放失败\n$message',
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
    if (_error != null) {
      return _MediaMessage(
        icon: Icons.videocam_off_outlined,
        message: _error!,
      );
    }

    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        // 按视频真实宽高比撑开，避免画面被拉伸
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}

/// 黑底媒体区里的居中提示（加载失败 / 地址为空）。
class _MediaMessage extends StatelessWidget {
  const _MediaMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.white70),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 信息卡片
// =============================================================================

/// 详情页统一的白色信息卡。
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;

  /// 标题行右侧的附加说明（比如"可选中复制"）。
  final Widget? trailing;

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
          Row(
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// 键值行。
class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});

  final String label;
  final String value;

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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
