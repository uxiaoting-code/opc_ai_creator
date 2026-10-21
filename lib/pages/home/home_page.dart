import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/cover_image.dart';
import '../../widgets/section_header.dart';
import 'widgets/creation_entry_card.dart';
import 'widgets/feature_entry_card.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/notification_sheet.dart';
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
                    // ===== 原型首页的核心：灵感输入 + 模式切换 =====
                    _QuickCreateCard(
                      textToImageSkills: skills.textToImageSkills,
                      imageToVideoSkills: skills.imageToVideoSkills,
                      credits: auth.user?.credits,
                      onGenerate: _handleQuickCreate,
                    ),

                    // ===== 创作工具：一键套用场景提示词 =====
                    _buildSceneSection(),

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
      return const _HorizontalSkeleton(
        count: 3,
        itemWidth: 136,
        itemHeight: 160,
      );
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

  /// 首页快捷创作：把提示词和线路带到对应创作页，参数在创作页继续调。
  void _handleQuickCreate(_QuickCreateRequest request) {
    final query = <String, String>{'prompt': request.prompt};
    if (request.skillId != null) {
      query['skillId'] = '${request.skillId}';
    }
    final path = request.mode == _QuickMode.textToImage
        ? RouteNames.textToImagePath
        : RouteNames.imageToVideoPath;
    context.push(Uri(path: path, queryParameters: query).toString());
  }

  /// 场景卡：套用一段预设提示词，直接进文生图创作页。
  void _openScenePrompt(String prompt) {
    context.push(
      Uri(
        path: RouteNames.textToImagePath,
        queryParameters: {'prompt': prompt},
      ).toString(),
    );
  }

  Widget _buildSceneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '创作工具', subtitle: '一键套用场景提示词'),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            itemCount: _scenePresets.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final preset = _scenePresets[index];
              return _SceneCard(
                preset: preset,
                accent: index.isEven ? AppColors.sage : AppColors.gold,
                onTap: () => _openScenePrompt(preset.prompt),
              );
            },
          ),
        ),
      ],
    );
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Row(
            children: [
              Expanded(
                child: CreationEntryCard(
                  title: '文生图',
                  subtitle: '输入提示词生成图片',
                  icon: CupertinoIcons.sparkles,
                  gradient: AppColors.sageGradient,
                  onTap: () => context.push(RouteNames.textToImagePath),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CreationEntryCard(
                  title: '图生视频',
                  subtitle: '让静态图片动起来',
                  icon: CupertinoIcons.videocam,
                  gradient: AppColors.goldGradient,
                  iconColor: AppColors.charcoal,
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Row(
            children: [
              Expanded(
                child: FeatureEntryCard(
                  title: 'Prompt 知识库',
                  subtitle: '检索 / 收藏提示词',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.gold,
                  onTap: () => context.push(RouteNames.promptsPath),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FeatureEntryCard(
                  title: 'Skill 市场',
                  subtitle: '全部创作线路',
                  icon: Icons.dashboard_customize_rounded,
                  color: AppColors.sage,
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
        _buildRecentWorksContent(provider),
      ],
    );
  }

  Widget _buildRecentWorksContent(WorkProvider provider) {
    final works = provider.recentWorks;

    if (provider.isLoading && works.isEmpty) {
      return _buildGridSkeleton();
    }

    if (provider.isEmpty) {
      return _InlineEmpty(
        message: '还没有作品，去创作第一张吧',
        actionLabel: '去创作',
        onAction: () => context.push(RouteNames.textToImagePath),
      );
    }

    final items = works.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final work = items[index];
          return _WorkGridTile(work: work, onTap: () => _openWorkDetail(work));
        },
      ),
    );
  }

  Widget _buildGridSkeleton() {
    final baseColor = Theme.of(context).dividerTheme.color ?? Colors.black12;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Row(
        children: [
          for (var i = 0; i < 2; i++) ...[
            Expanded(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
            if (i == 0) const SizedBox(width: AppSpacing.md),
          ],
        ],
      ),
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

enum _QuickMode { textToImage, imageToVideo }

class _QuickCreateRequest {
  const _QuickCreateRequest({
    required this.mode,
    required this.prompt,
    this.skillId,
  });

  final _QuickMode mode;
  final String prompt;
  final int? skillId;
}

/// 首页灵感输入卡：对应原型的 Hero 卡。
///
/// 这里只负责“收集意图”，不直接建任务：
/// 点生成后带着 prompt / skillId 跳到对应创作页，
/// 复杂参数、首帧图、提交校验仍在创作页完成。
class _QuickCreateCard extends StatefulWidget {
  const _QuickCreateCard({
    required this.textToImageSkills,
    required this.imageToVideoSkills,
    required this.credits,
    required this.onGenerate,
  });

  final List<SkillModel> textToImageSkills;
  final List<SkillModel> imageToVideoSkills;
  final int? credits;
  final ValueChanged<_QuickCreateRequest> onGenerate;

  @override
  State<_QuickCreateCard> createState() => _QuickCreateCardState();
}

class _QuickCreateCardState extends State<_QuickCreateCard> {
  final TextEditingController _promptController = TextEditingController();
  _QuickMode _mode = _QuickMode.textToImage;
  int? _skillId;

  List<SkillModel> get _skills => _mode == _QuickMode.textToImage
      ? widget.textToImageSkills
      : widget.imageToVideoSkills;

  SkillModel? get _selectedSkill {
    for (final skill in _skills) {
      if (skill.id == _skillId) return skill;
    }
    return null;
  }

  int get _cost => _mode == _QuickMode.textToImage ? 10 : 15;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _switchMode(_QuickMode mode) {
    if (_mode == mode) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      // 线路列表切换了，旧线路 ID 可能不属于新模式
      _skillId = null;
    });
  }

  void _generate() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('先描述一下你想生成什么')));
      return;
    }
    HapticFeedback.lightImpact();
    widget.onGenerate(
      _QuickCreateRequest(mode: _mode, prompt: prompt, skillId: _skillId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.darkBorder
        : Colors.white.withValues(alpha: 0.72);
    final surface = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.82)
        : AppColors.glass;
    final insufficient = widget.credits != null && widget.credits! < _cost;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        border: Border.all(color: borderColor),
        boxShadow: AppColors.shadowLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('灵感输入', style: theme.textTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sageTint,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  'AI 创作',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.sage,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildModeSwitch(theme, isDark),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _promptController,
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: _mode == _QuickMode.textToImage
                    ? '描述你想生成的画面，比如：雨夜霓虹街道，电影感…'
                    : '描述镜头怎么动，比如：镜头缓慢推进，暖光…',
                hintStyle: theme.textTheme.bodySmall,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSkillPicker(theme, isDark),
                const SizedBox(width: AppSpacing.sm),
                _pillContainer(
                  theme,
                  isDark,
                  icon: Icons.aspect_ratio_rounded,
                  label: '尺寸',
                  value: '默认',
                ),
                const SizedBox(width: AppSpacing.sm),
                _pillContainer(
                  theme,
                  isDark,
                  icon: _mode == _QuickMode.textToImage
                      ? Icons.crop_original_rounded
                      : Icons.timelapse_rounded,
                  label: _mode == _QuickMode.textToImage ? '数量' : '时长',
                  value: _mode == _QuickMode.textToImage ? '1 张' : '默认',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: insufficient
                    ? const LinearGradient(
                        colors: [Color(0xFFBDB5AA), Color(0xFFA79E92)],
                      )
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                boxShadow: insufficient ? null : AppColors.shadowButton,
              ),
              child: FilledButton(
                onPressed: _generate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.sparkles, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _mode == _QuickMode.textToImage ? '开始生成图片' : '开始生成视频',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            insufficient
                ? '算力不足（当前 ${widget.credits ?? '—'}）· 预计消耗 $_cost 算力'
                : '预计消耗 $_cost 算力 · 当前 ${widget.credits ?? '—'}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: insufficient ? AppColors.statusFailed : AppColors.taupe,
              fontWeight: insufficient ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.6)
            : AppColors.sageTint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        children: [
          _modePill(
            theme,
            isDark,
            _QuickMode.textToImage,
            '文生图',
            CupertinoIcons.sparkles,
          ),
          _modePill(
            theme,
            isDark,
            _QuickMode.imageToVideo,
            '图生视频',
            CupertinoIcons.videocam,
          ),
        ],
      ),
    );
  }

  Widget _modePill(
    ThemeData theme,
    bool isDark,
    _QuickMode mode,
    String label,
    IconData icon,
  ) {
    final active = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => _switchMode(mode),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? AppColors.darkSurface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: active ? AppColors.shadowSoft : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppColors.sage : AppColors.taupe,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: active ? AppColors.charcoal : AppColors.taupe,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillPicker(ThemeData theme, bool isDark) {
    final label = _selectedSkill?.name ?? '自动线路';
    return PopupMenuButton<int>(
      onSelected: (value) =>
          setState(() => _skillId = value < 0 ? null : value),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<int>(value: -1, child: Text('自动线路')),
        for (final skill in _skills)
          PopupMenuItem<int>(
            value: skill.id,
            child: Text(skill.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      child: _pillContainer(
        theme,
        isDark,
        icon: CupertinoIcons.slider_horizontal_3,
        label: '线路',
        value: label,
        showCaret: true,
      ),
    );
  }

  Widget _pillContainer(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    bool showCaret = false,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.sage),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showCaret) ...[
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: AppColors.taupe,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScenePreset {
  const _ScenePreset({
    required this.label,
    required this.icon,
    required this.prompt,
  });

  final String label;
  final IconData icon;
  final String prompt;
}

const List<_ScenePreset> _scenePresets = [
  _ScenePreset(
    label: '电商主图',
    icon: Icons.shopping_bag_outlined,
    prompt: '白色背景商品主图，柔和棚拍光，高级质感，1:1',
  ),
  _ScenePreset(
    label: '人像写真',
    icon: Icons.person_outline_rounded,
    prompt: '自然人像写真，柔和光线，浅景深，3:4',
  ),
  _ScenePreset(
    label: '促销海报',
    icon: Icons.local_offer_outlined,
    prompt: '促销海报设计，留白排版，醒目标题，3:4',
  ),
  _ScenePreset(
    label: '国风插画',
    icon: Icons.brush_outlined,
    prompt: '国风水墨插画，淡雅配色，留白，3:4',
  ),
];

class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.preset,
    required this.accent,
    required this.onTap,
  });

  final _ScenePreset preset;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: 96,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.8)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : Colors.white.withValues(alpha: 0.7),
          ),
          boxShadow: AppColors.shadowSoft,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(preset.icon, size: 16, color: accent),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  preset.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkGridTile extends StatelessWidget {
  const _WorkGridTile({required this.work, required this.onTap});

  final WorkModel work;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppColors.shadowSoft,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CoverImage(
                seed: 'work_${work.id}',
                url: work.coverUrl?.isNotEmpty == true
                    ? work.coverUrl
                    : work.resourceUrl,
                icon: work.isVideo
                    ? Icons.movie_outlined
                    : Icons.image_outlined,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: work.isVideo
                        ? Colors.black.withValues(alpha: 0.68)
                        : AppColors.glassStrong,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    work.isVideo ? '视频' : '图片',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: work.isVideo ? Colors.white : AppColors.charcoal,
                    ),
                  ),
                ),
              ),
              if (work.isVideo)
                Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 9,
                child: Text(
                  work.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isDark)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          const Icon(
            Icons.error_outline,
            size: 16,
            color: AppColors.statusFailed,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 区块内的空状态。
class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message, this.actionLabel, this.onAction});

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
          Icon(
            Icons.inbox_outlined,
            size: 16,
            color: theme.textTheme.bodySmall?.color,
          ),
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
