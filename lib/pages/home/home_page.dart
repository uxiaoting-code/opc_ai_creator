import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/skill_model.dart';
import '../../data/models/work_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/skill_provider.dart';
import '../../providers/work_provider.dart';
import '../../widgets/section_header.dart';
import 'widgets/creation_entry_card.dart';
import 'widgets/feature_entry_card.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/notification_sheet.dart';
import 'widgets/recent_work_card.dart';
import 'widgets/skill_card.dart';

/// 页面 2：首页（Skill 选择入口）
///
/// 页面结构（对应需求 1~5）：
/// ```
/// ┌────────────────────────────────┐
/// │ 顶部栏：头像 问候 ⚡算力 🔔消息  │  ← 固定，不滚动
/// │ 🔍 搜索提示词、创作线路          │
/// ├────────────────────────────────┤
/// │ ▍创作线路              市场 >   │
/// │ [二次元][写实][电商][国风]...    │  ← 横向滑动
/// ├────────────────────────────────┤
/// │ ▍开始创作                       │
/// │ [ 文生图  ][ 图生视频 ]          │
/// ├────────────────────────────────┤
/// │ ▍更多功能                       │
/// │ [Prompt知识库][Skill市场]        │
/// ├────────────────────────────────┤
/// │ ▍最近作品              全部 >   │
/// │ [封面][封面][封面]...            │  ← 横向滑动
/// └────────────────────────────────┘
/// ```
///
/// 数据全部来自 Provider（SkillProvider / WorkProvider / NotificationProvider），
/// 页面本身不直接碰网络层 —— 后端接口一接上，这里不用改任何代码。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // 放到首帧之后再加载：
    // Provider 的 load() 内部会 notifyListeners()，
    // 如果在 initState 里同步触发，会在 build 期间标记依赖组件为脏，直接报错。
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  /// 首次进入时按需加载各数据源（已加载过的会直接跳过）。
  ///
  /// 用户信息每次都要拉：算力点会被「提交生成任务」扣减，
  /// 不属于可以长期缓存的静态数据。
  Future<void> _loadAll() async {
    if (!mounted) return;
    await Future.wait([
      context.read<AuthProvider>().loadProfile(),
      context.read<SkillProvider>().loadIfNeeded(),
      context.read<WorkProvider>().loadIfNeeded(),
      context.read<NotificationProvider>().loadIfNeeded(),
    ]);
  }

  /// 下拉刷新：忽略缓存，强制重新拉取全部数据。
  Future<void> _refresh() async {
    await Future.wait([
      context.read<AuthProvider>().loadProfile(),
      context.read<SkillProvider>().refresh(),
      context.read<WorkProvider>().refresh(),
      context.read<NotificationProvider>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifications = context.watch<NotificationProvider>();
    final skills = context.watch<SkillProvider>();
    final works = context.watch<WorkProvider>();

    return Scaffold(
      body: SafeArea(
        // 底部留给 MainShell 的导航栏，这里不再额外留白
        bottom: false,
        child: Column(
          children: [
            // ---------- 需求 1：固定顶部栏 ----------
            HomeTopBar(
              nickname: auth.user?.displayName ?? '创作者',
              credits: auth.user?.credits,
              unreadCount: notifications.unreadCount,
              unreadLabel: notifications.badgeLabel,
              // 个人中心是底部 Tab，必须用 go 切分支，push 会让底部导航栏消失
              onCreditsTap: () => context.go(RouteNames.profilePath),
              onMessagesTap: () => NotificationSheet.show(context),
              onSearchTap: () => context.push(RouteNames.promptsPath),
            ),

            // ---------- 可滚动内容区 ----------
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                child: ListView(
                  // 内容不足一屏时也要能下拉刷新
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  children: [
                    // ===== 需求 2：Skill 线路横滑列表 =====
                    _buildSkillsSection(skills),

                    // ===== 需求 3：两大创作入口 =====
                    _buildCreationSection(),

                    // ===== 需求 4：功能入口 =====
                    _buildFeatureSection(),

                    // ===== 需求 5：最近作品横滑 =====
                    _buildRecentWorksSection(works),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 需求 2：Skill 线路
  // ===========================================================================

  Widget _buildSkillsSection(SkillProvider provider) {
    final skills = provider.featuredSkills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '创作线路',
          subtitle: '选一条线路直接开画',
          actionLabel: '市场',
          onAction: () => context.push(RouteNames.skillMarketPath),
        ),
        SizedBox(
          // 封面 104 + 文字区 ≈ 58 + 卡片描边，留一点余量防溢出
          height: 168,
          child: _buildSkillsContent(provider, skills),
        ),
      ],
    );
  }

  Widget _buildSkillsContent(SkillProvider provider, List<SkillModel> skills) {
    // 首次加载：骨架屏
    if (provider.isLoading && skills.isEmpty) {
      return const _HorizontalSkeleton(count: 3, itemWidth: 136, itemHeight: 160);
    }

    // 加载失败且没有旧数据：内联错误 + 重试
    if (skills.isEmpty && provider.error != null) {
      return _InlineError(
        message: provider.error!,
        onRetry: () => provider.load(force: true),
      );
    }

    if (skills.isEmpty) {
      return const _InlineEmpty(message: '暂无可用线路');
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      itemCount: skills.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (context, index) {
        final skill = skills[index];
        return SkillCard(
          skill: skill,
          onTap: () => _openCreationWithSkill(skill),
        );
      },
    );
  }

  /// 点线路卡片 → 带着 skillId 进入对应类型的创作页。
  ///
  /// 创作页会读 `?skillId=` 参数自动预选这条线路，
  /// 用户不需要进页面之后再选一次。
  void _openCreationWithSkill(SkillModel skill) {
    context.push('${skill.type.creationRoute}?skillId=${skill.id}');
  }

  // ===========================================================================
  // 需求 3：两大创作入口
  // ===========================================================================

  Widget _buildCreationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '开始创作'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Row(
            children: [
              Expanded(
                child: CreationEntryCard(
                  title: '文生图',
                  subtitle: '输入提示词生成图片',
                  icon: Icons.auto_awesome,
                  gradient: AppColors.primaryGradient,
                  onTap: () => context.push(RouteNames.textToImagePath),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CreationEntryCard(
                  title: '图生视频',
                  subtitle: '让静态图片动起来',
                  icon: Icons.movie_creation_outlined,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF5A9E), Color(0xFF8B5CF6)],
                  ),
                  onTap: () => context.push(RouteNames.imageToVideoPath),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 需求 4：功能入口
  // ===========================================================================

  Widget _buildFeatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '更多功能'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Row(
            children: [
              Expanded(
                child: FeatureEntryCard(
                  title: 'Prompt 知识库',
                  subtitle: '检索 / 收藏提示词',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.secondary,
                  onTap: () => context.push(RouteNames.promptsPath),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FeatureEntryCard(
                  title: 'Skill 市场',
                  subtitle: '全部创作线路',
                  icon: Icons.dashboard_customize_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push(RouteNames.skillMarketPath),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 需求 5：最近作品
  // ===========================================================================

  Widget _buildRecentWorksSection(WorkProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: '最近作品',
          subtitle: '你的创作足迹',
          actionLabel: '全部',
          // 作品画廊是底部 Tab，用 go 切换分支
          onAction: () => context.go(RouteNames.galleryPath),
        ),
        SizedBox(
          height: 112,
          child: _buildRecentWorksContent(provider),
        ),
      ],
    );
  }

  Widget _buildRecentWorksContent(WorkProvider provider) {
    final works = provider.recentWorks;

    if (provider.isLoading && works.isEmpty) {
      return const _HorizontalSkeleton(count: 3, itemWidth: 112, itemHeight: 112);
    }

    if (provider.isEmpty) {
      return _InlineEmpty(
        message: '还没有作品，去创作第一张吧',
        actionLabel: '去创作',
        onAction: () => context.push(RouteNames.textToImagePath),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      itemCount: works.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        final work = works[index];
        return RecentWorkCard(
          work: work,
          onTap: () => _openWorkDetail(work),
        );
      },
    );
  }

  /// 打开作品详情。
  ///
  /// 作品详情是**画廊 Tab 分支下的子路由**（`/gallery/:workId`），
  /// 不是顶层路由。从首页点它属于「跨分支跳转」，go_router 里必须用 `go`：
  /// `go` 会把画廊分支的页面栈设为 [画廊列表, 作品详情]，
  /// 用户从详情返回就回到画廊列表，底部导航也跟着切到「画廊」。
  ///
  /// 用 `push` 则会把详情压进首页分支的栈里，导致底部导航高亮与页面内容对不上。
  void _openWorkDetail(WorkModel work) {
    context.go(RouteNames.workDetailOf(work.id));
  }
}

// =============================================================================
// 内部复用小组件
// =============================================================================

/// 横向列表的骨架屏。
///
/// 比直接转圈好看，也让用户对「这里会有几张卡片」有预期。
class _HorizontalSkeleton extends StatelessWidget {
  const _HorizontalSkeleton({
    required this.count,
    required this.itemWidth,
    required this.itemHeight,
  });

  final int count;
  final double itemWidth;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).dividerTheme.color ?? Colors.black12;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      // 骨架屏不可交互，直接禁掉滚动手势
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (context, index) => Container(
        width: itemWidth,
        height: itemHeight,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}

/// 区块内的错误提示（不是整页错误，只影响这一个区块）。
class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.statusFailed),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 区块内的空状态。
class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              message,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
