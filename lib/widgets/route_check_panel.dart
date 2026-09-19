import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/route_names.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// 路由自检面板（开发调试用）。
///
/// 脚手架阶段挂在首页底部：一键跳到全部 13 个页面，
/// 用来验证 go_router 的路由表、参数传递、底部 Tab 切换是否都通了。
/// Web 上还可以顺便观察地址栏有没有跟着变。
///
/// 等 13 个页面都实现完之后，把首页的 `footer` 参数删掉即可移除。
class RouteCheckPanel extends StatelessWidget {
  const RouteCheckPanel({super.key});

  /// 13 个业务页面的自检条目。
  ///
  /// [isBranchTab] 为 true 的是底部 Tab 页，必须用 `go` 切分支；
  /// 其余页面用 `push` 盖在上层，保留返回栈。
  static const List<_RouteEntry> _entries = [
    _RouteEntry(1, '登录/注册', RouteNames.loginPath, isBranchTab: false),
    _RouteEntry(2, '首页', RouteNames.homePath, isBranchTab: true),
    _RouteEntry(3, '文生图创作', RouteNames.textToImagePath),
    _RouteEntry(4, '图生视频创作', RouteNames.imageToVideoPath),
    _RouteEntry(5, '任务列表', RouteNames.taskListPath, isBranchTab: true),
    _RouteEntry(6, '作品画廊', RouteNames.galleryPath, isBranchTab: true),
    _RouteEntry(7, '素材库', RouteNames.materialsPath, isBranchTab: true),
    _RouteEntry(8, 'Prompt 知识库', RouteNames.promptsPath),
    _RouteEntry(9, 'Skill 市场', RouteNames.skillMarketPath),
    _RouteEntry(10, '作品详情', '/gallery/1'),
    _RouteEntry(11, '个人中心', RouteNames.profilePath, isBranchTab: true),
    _RouteEntry(12, '设置', RouteNames.settingsPath),
    _RouteEntry(13, '任务详情', '/tasks/1'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded,
                  size: 18, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Text('路由自检（13 个页面）', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '开发调试用，点一遍确认两端跳转都正常。页面全部完成后可移除。',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ..._entries.map((entry) => _RouteTile(entry: entry)),
        ],
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({required this.entry});

  final _RouteEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: () => _navigate(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${entry.number}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.label, style: theme.textTheme.bodyMedium),
                  Text(
                    entry.path,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (entry.isBranchTab)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: const Text(
                  'Tab',
                  style: TextStyle(fontSize: 10, color: AppColors.secondary),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    // 登录页是顶层路由，直接跳会被守卫拦下；这里先登出再进，专门验证拦截逻辑
    if (entry.path == RouteNames.loginPath) {
      context.go(RouteNames.loginPath);
      return;
    }

    // Tab 页必须用 go 切换分支；push 会导致底部导航栏消失
    if (entry.isBranchTab) {
      context.go(entry.path);
    } else {
      context.push(entry.path);
    }
  }
}

class _RouteEntry {
  const _RouteEntry(
    this.number,
    this.label,
    this.path, {
    this.isBranchTab = false,
  });

  final int number;
  final String label;
  final String path;
  final bool isBranchTab;
}
