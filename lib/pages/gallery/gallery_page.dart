import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/work_model.dart';
import '../../providers/work_provider.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/state_views.dart';

/// 画廊筛选维度。
///
/// **在前端过滤，不走接口参数**：后端 `GET /api/works` 只支持
/// `page / pageSize / limit / scope`，没有 type 与 sort 参数。
/// 课程设计阶段不值得为它改后端契约，所以在这里做客户端过滤。
/// 代价见 [_GalleryPageState._loadMore] 里的「筛选感知分页」处理。
enum WorkFilter {
  all('全部'),
  image('仅图片'),
  video('仅视频');

  const WorkFilter(this.label);

  final String label;

  /// 这件作品是否命中当前筛选。
  bool matches(WorkModel work) {
    switch (this) {
      case WorkFilter.all:
        return true;
      case WorkFilter.image:
        return !work.isVideo;
      case WorkFilter.video:
        return work.isVideo;
    }
  }
}

/// 排序方式。
enum WorkSort {
  newest('最新'),
  oldest('最早');

  const WorkSort(this.label);

  final String label;
}

/// 页面 6：作品画廊
///
/// 只展示生成成功的作品（后端在任务成功时自动落 `t_work` 记录）。
///
/// 布局用 **双列 Masonry 瀑布流**：作品的宽高比各不相同，
/// 普通 GridView 会把同一行拉到等高，矮卡片下面留出大片空白；
/// Masonry 让每一列独立堆叠，才是画廊该有的样子。
///
/// 数据走全局的 [WorkProvider]（与首页「最近作品」共用同一份），
/// 分页状态也在那边 —— 这样在画廊刷新之后回首页，看到的也是新数据。
///
/// 长按多选批量操作本轮**未实现**，见需求说明。
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  /// 上拉分页用的滚动控制器（需求明确要求用 ScrollController 实现）。
  final ScrollController _scrollController = ScrollController();

  WorkFilter _filter = WorkFilter.all;
  WorkSort _sort = WorkSort.newest;

  /// 距底部还有这么多像素时就开始加载下一页。
  ///
  /// 留出提前量是为了让用户几乎感觉不到"加载"这个动作 ——
  /// 等真正滚到底再请求，一定会先看到一段空白。
  static const double _loadMoreThreshold = 300;

  /// 「筛选感知分页」最多自动往后翻几页，防止极端情况下一次拉光所有数据。
  static const int _maxAutoFillPages = 5;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 放到首帧之后再触发加载：Provider 的 load() 内部会 notifyListeners()，
    // 在 initState 里同步触发会在 build 期间标记依赖组件为脏，直接报错。
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 首页可能已经加载过第一页，loadIfNeeded 会直接跳过，不会重复请求
      await context.read<WorkProvider>().loadIfNeeded();
      if (!mounted) return;
      await _loadMore();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 分页
  // ===========================================================================

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    // 内容不足一屏时 maxScrollExtent 是 0，这里会立刻成立并触发加载 ——
    // 这正是想要的行为：自动把屏幕填满，用户才知道可以往下滚。
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _loadMore();
    }
  }

  /// 加载下一页，并在「当前筛选下仍然没内容」时继续往后取。
  ///
  /// 为什么要循环：筛选是前端做的，某一页可能整页都不匹配
  /// （比如整页都是图片却筛了「仅视频」）。这时如果不继续往后拉，
  /// 用户会看到一个空网格 —— 而且**没有内容就没有滚动**，
  /// 连"上拉加载"都触发不了，直接走进死胡同。
  Future<void> _loadMore() async {
    if (!mounted) return;

    final provider = context.read<WorkProvider>();
    if (provider.isLoadingMore || !provider.hasMore || provider.isLoading) {
      return;
    }

    var guard = 0;
    while (mounted && provider.hasMore && guard < _maxAutoFillPages) {
      final before = provider.works.length;
      await provider.loadMore();
      if (!mounted) return;

      guard++;

      // 攒到内容了，剩下的交给用户滚动
      if (_visibleWorksOf(provider).isNotEmpty) return;
      // 这一页没带来任何新数据（到底了，或请求失败），再循环也是白转
      if (provider.works.length == before) return;
    }
  }

  Future<void> _refresh() async {
    await context.read<WorkProvider>().refresh();
    if (!mounted) return;
    // 刷新后列表回到第一页，需要重新把筛选结果填出来
    await _loadMore();
  }

  // ===========================================================================
  // 筛选与排序（客户端）
  // ===========================================================================

  /// 按当前筛选 + 排序算出要渲染的列表。
  List<WorkModel> _visibleWorksOf(WorkProvider provider) {
    final filtered = provider.works.where(_filter.matches).toList();

    switch (_sort) {
      case WorkSort.newest:
        // 后端本来就是按创建时间倒序返回的，不要再排一遍 ——
        // 多一次排序只会打乱分页追加的顺序，反而出错。
        return filtered;
      case WorkSort.oldest:
        // 这里必须拷贝一份再排：直接 sort 会改动 provider 内部的列表，
        // 首页的「最近作品」会跟着变成最早的 8 条。
        final copy = List<WorkModel>.from(filtered);
        copy.sort((a, b) {
          final ta = a.createdAt;
          final tb = b.createdAt;
          // 时间缺失的排到最后，避免 null 参与比较导致排序结果不稳定
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return ta.compareTo(tb);
        });
        return copy;
    }
  }

  void _changeFilter(WorkFilter value) {
    if (_filter == value) return;
    setState(() => _filter = value);
    // 换筛选后当前攒的数据可能还是不够，补一次
    _loadMore();
  }

  void _changeSort(WorkSort value) {
    if (_sort == value) return;
    setState(() => _sort = value);
  }

  void _openDetail(WorkModel work) {
    // 作品详情是**画廊分支自己的子路由**（`/gallery/:workId`）。
    //
    // ⚠️ 这里必须用 push，不能用 go —— 已经在画廊列表上、要进它的子路由时，
    // go 会重新解析整份路由匹配表，而目标路径恰好是当前分支路径的子路径，
    // 匹配表里会出现**重复的 RouteMatch**，于是同一个页面 key 被塞进同一个
    // Navigator 两次，触发：
    //     Assertion failed: !keyReservation.contains(key)
    //     A GlobalKey was used multiple times inside one widget's child list
    // 报错里点名的 HeroControllerScope 只是出事的现场，不是原因。
    //
    // push 把这条子路由压到**当前（画廊）分支的导航器**上：
    // 底部导航栏依然保留，返回也正好回到画廊列表。
    context.push(RouteNames.workDetailOf(work.id));
  }

  // ===========================================================================
  // 构建
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkProvider>();
    final visible = _visibleWorksOf(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('作品画廊'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: provider.isLoading ? null : _refresh,
            icon: provider.isLoading
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
            _buildFilterBar(provider, visible.length),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                child: CustomScrollView(
                  controller: _scrollController,
                  // 内容不足一屏时也要能下拉刷新
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: _buildSlivers(provider, visible),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 筛选 / 排序栏
  // ---------------------------------------------------------------------------

  Widget _buildFilterBar(WorkProvider provider, int count) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用 Wrap 而不是 Row：芯片在窄屏上会自动折行。
          // （Row 会给子组件无限宽约束，含内部 Flexible 的控件会直接报错）
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final filter in WorkFilter.values)
                ChoiceChip(
                  label: Text(filter.label),
                  selected: _filter == filter,
                  onSelected: (_) => _changeFilter(filter),
                ),

              // 筛选与排序之间的分隔线，避免两组芯片被看成一类
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                color: theme.dividerTheme.color ?? AppColors.lightBorder,
              ),

              for (final sort in WorkSort.values)
                ChoiceChip(
                  label: Text(sort.label),
                  selected: _sort == sort,
                  onSelected: (_) => _changeSort(sort),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            provider.isLoading ? '正在加载…' : '共 $count 件作品',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 滚动内容
  // ---------------------------------------------------------------------------

  List<Widget> _buildSlivers(WorkProvider provider, List<WorkModel> visible) {
    // ---- 首次加载：整页转圈 ----
    if (provider.isLoading && provider.works.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: LoadingView(message: '正在加载作品…'),
        ),
      ];
    }

    // ---- 加载失败且一条都没拿到：整页错误 + 重试 ----
    if (provider.error != null && provider.works.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: provider.error!,
            onRetry: () => provider.load(force: true),
          ),
        ),
      ];
    }

    // ---- 一件作品都没有，或当前筛选下没有 ----
    if (visible.isEmpty) {
      // 筛选是前端做的，可能只是"还没加载到匹配的那一页"。
      // 这时候不能对用户说"没有符合条件的作品" —— 那是假话。
      final canLoadMore = provider.works.isNotEmpty && provider.hasMore;

      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: provider.works.isEmpty
              ? const EmptyView(
                  icon: Icons.grid_view_rounded,
                  title: '还没有作品',
                  description: '去「文生图」或「图生视频」创作第一件作品吧',
                )
              : EmptyView(
                  icon: Icons.filter_alt_off_outlined,
                  title: '当前筛选下暂时没有作品',
                  description: canLoadMore
                      ? '后面还有没加载的作品，可以继续往后翻'
                      : '当前筛选是「${_filter.label}」，换一个试试',
                  actionLabel: canLoadMore ? '继续加载' : null,
                  onAction: canLoadMore ? _loadMore : null,
                ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childCount: visible.length,
          itemBuilder: (context, index) {
            final work = visible[index];
            return _WorkCard(work: work, onTap: () => _openDetail(work));
          },
        ),
      ),
      SliverToBoxAdapter(child: _buildFooter(provider)),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
    ];
  }

  /// 列表底部：加载中 / 加载失败可重试 / 已经到底了。
  Widget _buildFooter(WorkProvider provider) {
    final theme = Theme.of(context);

    if (provider.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              provider.loadMoreError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: _loadMore, child: const Text('重试')),
          ],
        ),
      );
    }

    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
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

    if (!provider.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text('— 没有更多了 —', style: theme.textTheme.bodySmall),
        ),
      );
    }

    return const SizedBox(height: AppSpacing.xl);
  }
}

// =============================================================================
// 作品卡片
// =============================================================================

/// 瀑布流里的一张作品卡片。
///
/// 高度由作品宽高比决定；视频作品额外叠播放角标 + 时长，
/// 让用户在列表里就能区分图片和视频，不用点进去才知道。
class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.work, required this.onTap});

  final WorkModel work;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 视频优先用后端生成的封面图；封面缺失时退回资源地址
    // （视频地址当图片加载会失败，CoverImage 会自动落到渐变占位，不会破图）
    final cover = (work.coverUrl != null && work.coverUrl!.isNotEmpty)
        ? work.coverUrl
        : work.resourceUrl;

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: _aspectRatioOf(work),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CoverImage(
                    seed: 'work_${work.id}',
                    url: cover,
                    icon: work.isVideo
                        ? Icons.movie_outlined
                        : Icons.image_outlined,
                  ),

                  // 底部渐变压暗，保证角标文字在任何封面上都看得清
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),

                  // 右上角：视频时长
                  if (work.isVideo && work.durationLabel != null)
                    Positioned(
                      right: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: _Pill(text: work.durationLabel!),
                    ),

                  // 视频中央播放角标
                  if (work.isVideo)
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.42),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),

                  // 左下角：标题
                  Positioned(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Text(
                      work.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 封面上的小圆角标签（时长 / 类型）。
class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// 工具
// =============================================================================

/// 卡片宽高比。
///
/// 优先用后端回填的真实尺寸；拿不到时按作品 ID 算一个**稳定**的伪随机比例。
///
/// 为什么要"稳定"：瀑布流的高度由比例决定，如果每次重建比例都变，
/// 用户一下拉刷新整个网格就会跳来跳去。用稳定哈希保证同一件作品
/// 在任何时候都是同一个比例。
///
/// （不用 `String.hashCode`：Dart 没有承诺它跨版本稳定，
/// 与 [CoverImage] 里渐变种子的处理方式保持一致。）
double _aspectRatioOf(WorkModel work) {
  final w = work.width;
  final h = work.height;
  if (w != null && h != null && w > 0 && h > 0) {
    return w / h;
  }

  // 一组常见画幅：3:4 / 1:1 / 4:3 / 2:3 / 4:5 / 3:2
  const ratios = <double>[0.75, 1.0, 1.333, 0.667, 0.8, 1.5];

  var hash = 0;
  for (final unit in 'work_${work.id}'.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  return ratios[hash % ratios.length];
}
