import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 模板顶栏：居中标题，左右为毛玻璃圆形按钮。
AppBar premiumTopBar({
  required String title,
  VoidCallback? onBack,
  List<Widget> actions = const [],
}) {
  return AppBar(
    automaticallyImplyLeading: false,
    leadingWidth: onBack == null ? 0 : 64,
    leading: onBack == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: AppSpacing.pagePadding),
            child: PremiumCircleAction(
              icon: Icons.arrow_back_rounded,
              tooltip: '返回',
              onPressed: onBack,
            ),
          ),
    title: Text(title),
    actions: [
      if (actions.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Row(mainAxisSize: MainAxisSize.min, children: actions),
        ),
    ],
  );
}

class PremiumCircleAction extends StatelessWidget {
  const PremiumCircleAction({
    super.key,
    this.icon,
    this.content,
    required this.tooltip,
    required this.onPressed,
    this.badge,
  });

  final IconData? icon;
  final Widget? content;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.9)
              : AppColors.glass,
          shape: const CircleBorder(side: BorderSide(color: Color(0xBFFFFFFF))),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  content ?? Icon(icon ?? Icons.circle_outlined, size: 19),
                  if (badge != null)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 14),
                        height: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.statusFailed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
