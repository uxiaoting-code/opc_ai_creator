import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// 首页两大创作入口卡片：文生图 / 图生视频。
///
/// 原型是 Light Premium 的毛玻璃卡片：
/// 渐变只放在左上角的图标块里，整张卡保持暖白半透明，
/// 这样两张入口卡不会像两个高饱和色块一样抢走主流程的注意力。
class CreationEntryCard extends StatelessWidget {
  const CreationEntryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color iconColor;
  final VoidCallback onTap;

  static const double height = 128;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.8)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : Colors.white.withValues(alpha: 0.65),
          ),
          boxShadow: AppColors.shadowSoft,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          boxShadow: AppColors.shadowSoft,
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 18,
                        color: AppColors.taupe.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
