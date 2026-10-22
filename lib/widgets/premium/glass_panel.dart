import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 模板中的基础毛玻璃面板。
///
/// 不直接使用 [BackdropFilter]：模板在固定底栏和弹层里使用真实模糊，
/// 但如果每张列表卡都加模糊层，Flutter Web 和低端 Android 会出现明显掉帧。
/// 这里用半透明白、白色细边和柔和阴影还原主要质感，关键区域仍可单独使用模糊。
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.borderRadius = AppSpacing.radiusCard,
    this.backgroundColor,
    this.borderColor,
    this.shadow = AppColors.shadowSoft,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final surface =
        backgroundColor ??
        (isDark
            ? AppColors.darkSurface.withValues(alpha: 0.86)
            : AppColors.glass);
    final stroke =
        borderColor ??
        (isDark ? AppColors.darkBorder : Colors.white.withValues(alpha: 0.72));

    final content = Padding(padding: padding, child: child);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: Border.all(color: stroke),
        boxShadow: shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}
