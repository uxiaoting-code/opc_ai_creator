import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'pressable_scale.dart';

/// 模板中的轻量筛选/选项胶囊。
///
/// 只负责展示和回调，筛选、排序、请求都由页面自己处理。
class PremiumChoiceChip extends StatelessWidget {
  const PremiumChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = selected ? AppColors.sage : AppColors.taupe;

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.sageTint
                  : (isDark
                        ? AppColors.darkSurface.withValues(alpha: 0.76)
                        : AppColors.glass),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: selected
                    ? AppColors.sage.withValues(alpha: 0.42)
                    : (isDark
                          ? AppColors.darkBorder
                          : Colors.white.withValues(alpha: 0.76)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: foreground),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 12 : 12.5,
                    color: foreground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
