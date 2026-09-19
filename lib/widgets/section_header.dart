import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// 区块标题：`标题 ............ 更多 >`
///
/// 首页有 4 个区块（Skill 线路 / 创作入口 / 功能入口 / 最近作品），
/// 统一用它保证标题样式和间距一致。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.pagePadding,
      AppSpacing.xl,
      AppSpacing.pagePadding,
      AppSpacing.md,
    ),
  });

  final String title;

  /// 标题右侧的浅色补充说明。
  final String? subtitle;

  /// 右侧操作文案，如「全部」。
  final String? actionLabel;

  final VoidCallback? onAction;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          // 标题前的品牌色竖条，视觉上把区块切开
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: theme.textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ] else
            const Spacer(),
          if (actionLabel != null && onAction != null)
            // 用 TextButton 而不是 GestureDetector，保证点击热区够大
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 32),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                foregroundColor: AppColors.primary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!, style: const TextStyle(fontSize: 13)),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
