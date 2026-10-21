import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 尺寸 / 比例选择器：一排胶囊，适合放在参数区。
class SizePicker extends StatelessWidget {
  const SizePicker({
    super.key,
    required this.sizes,
    required this.selected,
    required this.onChanged,
    this.label = '比例',
  });

  final List<String> sizes;
  final String selected;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final size in sizes)
              InkWell(
                onTap: () => onChanged(size),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: size == selected
                        ? AppColors.sageTint
                        : AppColors.glass,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(
                      color: size == selected
                          ? AppColors.sage.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  child: Text(
                    size,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: size == selected
                          ? AppColors.sage
                          : AppColors.taupe,
                      fontWeight: size == selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
