import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 算力余额胶囊：大数字自动显示成“万 / 亿”。
class CreditChip extends StatelessWidget {
  const CreditChip({super.key, required this.credits, this.onTap});

  final int? credits;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.bolt_fill,
              size: 14,
              color: AppColors.gold,
            ),
            const SizedBox(width: 4),
            Text(
              _formatCredits(credits),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCredits(int? value) {
    if (value == null) return '—';
    final n = value.toDouble();
    if (n.abs() >= 100000000) {
      return '${(n / 100000000).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} 亿';
    }
    if (n.abs() >= 10000) {
      return '${(n / 10000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} 万';
    }
    return value.toString();
  }
}
