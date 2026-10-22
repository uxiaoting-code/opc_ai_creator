import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium/glass_panel.dart';
import '../../widgets/premium/pressable_scale.dart';
import '../../widgets/premium/premium_top_bar.dart';

/// 页面 11：个人中心
///
/// 数据来源分两处：
/// - **账号信息**（昵称 / 头像 / 算力点）来自全局 [AuthProvider]，
///   与首页右上角是同一个来源 —— 这里改了，首页也跟着变，不会两套数据打架；
/// - **任务统计**来自 `GET /api/tasks/stats`，返回各状态的任务数量。
///
/// 本轮只做「查看 + 导航」。编辑资料需要后端支持 `PUT /api/auth/profile`，
/// 目前没有这个接口；「我的收藏」也没有对应的后端字段/接口
/// （全库只有 `t_prompt_favorite`，而且没有 PromptController），
/// 所以这两个入口都没有放 —— 放上去点了报错比不放更糟。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// 仓库在 initState 里取好，异步流程里就不再碰 context。
  late final TaskRepository _repo;

  /// 状态名 → 数量，例如 `{"SUCCESS": 12, "FAILED": 2}`。
  Map<String, int> _stats = const {};

  bool _loadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _repo = context.read<TaskRepository>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 顺手刷一遍账号信息：算力点会被创作任务扣掉，
      // 不能让用户进个人中心看到的还是过期的数。
      context.read<AuthProvider>().loadProfile();
      _loadStats();
    });
  }

  // ===========================================================================
  // 数据
  // ===========================================================================

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });

    try {
      final stats = await _repo.fetchTaskStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.message;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = '加载统计失败：$e';
        _loadingStats = false;
      });
    }
  }

  Future<void> _refresh() async {
    // context.read 在 await 之前求值，不会踩「await 之后用 context」
    await context.read<AuthProvider>().loadProfile();
    if (!mounted) return;
    await _loadStats();
  }

  // 统计口径：只算任务，作品数是另一回事。
  int get _totalTasks => _stats.values.fold(0, (sum, v) => sum + v);

  int get _successTasks => _stats['SUCCESS'] ?? 0;

  /// 成功率。一个任务都没有时显示 `—`，而不是刺眼的 `0%`。
  String get _successRate => _totalTasks == 0
      ? '—'
      : '${(_successTasks * 100 / _totalTasks).toStringAsFixed(0)}%';

  // ===========================================================================
  // 构建
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: premiumTopBar(
        title: '个人中心',
        actions: [
          PremiumCircleAction(
            icon: CupertinoIcons.gear,
            tooltip: '设置',
            onPressed: () => context.push(RouteNames.settingsPath),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              _buildHeader(user),
              const SizedBox(height: AppSpacing.lg),
              _buildCreditsCard(user),
              const SizedBox(height: AppSpacing.lg),
              _buildStatsCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildEntries(),
              const SizedBox(height: AppSpacing.xl),
              _buildLogoutButton(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  /// 头像 + 昵称 + 账号 + 角色。
  Widget _buildHeader(UserModel? user) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: AppColors.shadowSoft,
          ),
          child: Text(
            user?.avatarInitial ?? '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? '未登录',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                user == null ? '—' : '@${user.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              if (user?.isAdmin == true) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '管理员',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 算力点卡片。数值与首页右上角同源（都读 AuthProvider）。
  Widget _buildCreditsCard(UserModel? user) {
    final theme = Theme.of(context);
    final credits = user?.credits;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: AppColors.shadowButton,
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.bolt_fill, color: Colors.white, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '剩余算力点',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          Text(
            // 还没从后端取到时显示 —，而不是骗人的 0
            credits?.toString() ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// 任务统计卡片。
  Widget _buildStatsCard() {
    final theme = Theme.of(context);

    return _Card(
      title: '数据统计',
      child: _statsError != null
          ? Row(
              children: [
                Expanded(
                  child: Text(_statsError!, style: theme.textTheme.bodySmall),
                ),
                TextButton(onPressed: _loadStats, child: const Text('重试')),
              ],
            )
          : _loadingStats
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: _StatTile(label: '累计任务', value: '$_totalTasks'),
                ),
                Expanded(
                  child: _StatTile(label: '生成成功', value: '$_successTasks'),
                ),
                Expanded(
                  child: _StatTile(label: '成功率', value: _successRate),
                ),
              ],
            ),
    );
  }

  /// 功能入口。都指向底部导航的其它 Tab 或顶层路由。
  Widget _buildEntries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('快捷入口', style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.55,
          children: [
            _QuickEntryTile(
              icon: CupertinoIcons.square_list,
              title: '我的任务',
              subtitle: '查看生成状态',
              color: AppColors.sage,
              onTap: () => context.go(RouteNames.taskListPath),
            ),
            _QuickEntryTile(
              icon: CupertinoIcons.square_grid_2x2,
              title: '我的作品',
              subtitle: '图片与视频',
              color: const Color(0xFF6E8B9A),
              onTap: () => context.go(RouteNames.galleryPath),
            ),
            _QuickEntryTile(
              icon: CupertinoIcons.photo,
              title: '我的素材',
              subtitle: '参考图素材',
              color: const Color(0xFF8A7E9A),
              onTap: () => context.go(RouteNames.materialsPath),
            ),
            _QuickEntryTile(
              icon: CupertinoIcons.gear,
              title: '设置',
              subtitle: '主题与环境',
              color: AppColors.gold,
              onTap: () => context.push(RouteNames.settingsPath),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      // 放在 Column 里独占一行。含内部 Flexible 的按钮塞进 Row
      // 会拿到无限宽约束而报错，这个坑前面踩过。
      onPressed: () => context.read<AuthProvider>().logout(),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('退出登录'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.statusFailed,
        side: BorderSide(color: AppColors.statusFailed.withValues(alpha: 0.4)),
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
      ),
    );
  }
}

// =============================================================================
// 内部小组件
// =============================================================================

/// 统一的白色信息卡。
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// 统计卡片里的单格。
class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _QuickEntryTile extends StatelessWidget {
  const _QuickEntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      child: GlassPanel(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
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
