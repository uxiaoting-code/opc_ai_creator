import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class PremiumModeOption<T> {
  const PremiumModeOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

/// 模板中带滑块指示器的模式切换。
class PremiumModeSwitch<T> extends StatelessWidget {
  const PremiumModeSwitch({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  }) : assert(options.length > 1);

  final List<PremiumModeOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedIndex = options.indexWhere((option) => option.value == value);
    final normalized = options.length == 1
        ? 0.0
        : (selectedIndex.clamp(0, options.length - 1) * 2.0) /
                  (options.length - 1) -
              1;

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.72)
            : AppColors.sageTint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            alignment: Alignment(normalized, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / options.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  boxShadow: AppColors.shadowSoft,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final option in options)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (option.value != value) onChanged(option.value);
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: theme.textTheme.labelLarge!.copyWith(
                          color: option.value == value
                              ? (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.charcoal)
                              : AppColors.taupe,
                          fontWeight: option.value == value
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option.icon,
                              size: 15,
                              color: option.value == value
                                  ? AppColors.sage
                                  : AppColors.taupe,
                            ),
                            const SizedBox(width: 5),
                            Text(option.label),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
