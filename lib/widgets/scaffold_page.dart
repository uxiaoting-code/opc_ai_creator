import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// 13 个业务页面的统一「空白脚手架」外壳。
///
/// 第 2 步只搭路由骨架，先让每个页面都能独立打开、验证跳转是否通；
/// 第 3 步再逐个把这些页面替换成真实实现。
///
/// 用法（每个页面文件里就是这么一个控件）：
/// ```dart
/// ScaffoldPage(
///   pageNumber: 3,
///   title: '文生图创作',
///   routePath: RouteNames.textToImagePath,
///   icon: Icons.auto_awesome,
///   summary: '输入提示词 + 选线路，提交生成图片任务',
///   plannedFeatures: ['提示词输入框', '线路切换', '参数面板'],
/// )
/// ```
class ScaffoldPage extends StatelessWidget {
  const ScaffoldPage({
    super.key,
    required this.pageNumber,
    required this.title,
    required this.routePath,
    required this.icon,
    required this.summary,
    required this.plannedFeatures,
    this.actions,
    this.body,
    this.footer,
  });

  /// 页面在需求清单里的编号（1~13），方便对照课程设计文档。
  final int pageNumber;

  /// 页面标题，同时作为 AppBar 标题。
  final String title;

  /// 当前页面路由，显示出来便于 Web 调试时核对地址栏。
  final String routePath;

  final IconData icon;

  /// 一句话说明这个页面要做什么。
  final String summary;

  /// 待实现功能清单（第 3 步的开发 checklist）。
  final List<String> plannedFeatures;

  /// AppBar 右侧按钮。
  final List<Widget>? actions;

  /// 自定义正文。传了就不再显示默认的占位说明。
  final Widget? body;

  /// 追加在占位说明下方的内容，用于放路由自检面板等调试组件。
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: MobileScaffoldBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (body != null)
                body!
              else
                _PlaceholderContent(
                  pageNumber: pageNumber,
                  icon: icon,
                  routePath: routePath,
                  summary: summary,
                  plannedFeatures: plannedFeatures,
                ),
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.xl),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 页面正文的通用容器：限制最大宽度 + 统一内边距，避免大屏拉伸。
class MobileScaffoldBody extends StatelessWidget {
  const MobileScaffoldBody({super.key, required this.child, this.scrollable = true});

  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: child,
    );
    return scrollable ? SingleChildScrollView(child: content) : content;
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({
    required this.pageNumber,
    required this.icon,
    required this.routePath,
    required this.summary,
    required this.plannedFeatures,
  });

  final int pageNumber;
  final IconData icon;
  final String routePath;
  final String summary;
  final List<String> plannedFeatures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- 头部卡片：页面身份信息 ----
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: AppColors.shimmerGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Tag(text: '页面 $pageNumber / 13'),
                        const SizedBox(width: AppSpacing.sm),
                        _Tag(text: '开发中', color: AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      summary,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ---- 路由信息（Web 调试时核对用） ----
        _InfoRow(
          icon: Icons.link_rounded,
          label: '路由路径',
          value: routePath,
          monospace: true,
        ),

        const SizedBox(height: AppSpacing.xl),

        // ---- 待实现功能清单 ----
        Text('本页待实现功能', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        ...plannedFeatures.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(feature, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        Center(
          child: Text(
            '脚手架占位页 · 将于后续迭代实现',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.color = AppColors.primary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyLarge?.color,
                fontFamily: monospace ? 'monospace' : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
