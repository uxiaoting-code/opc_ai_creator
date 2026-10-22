import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class PremiumSelectOption<T> {
  const PremiumSelectOption({
    required this.value,
    required this.title,
    this.description,
    this.icon,
    this.badge,
    this.trailing,
    this.highlighted = false,
  });

  final T value;
  final String title;
  final String? description;
  final IconData? icon;
  final String? badge;
  final String? trailing;
  final bool highlighted;
}

Future<T?> showPremiumSelectSheet<T>({
  required BuildContext context,
  required String title,
  required List<PremiumSelectOption<T>> options,
  T? selected,
  String? subtitle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PremiumSelectSheet<T>(
      title: title,
      subtitle: subtitle,
      options: options,
      selected: selected,
    ),
  );
}

class _PremiumSelectSheet<T> extends StatelessWidget {
  const _PremiumSelectSheet({
    required this.title,
    required this.options,
    this.selected,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<PremiumSelectOption<T>> options;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final heightFactor = (0.28 + options.length * 0.09).clamp(0.42, 0.82);

    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.glassStrong,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 32,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.taupe.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                  AppSpacing.pagePadding,
                  AppSpacing.xl,
                ),
                itemCount: options.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option.value == selected;
                  return _OptionRow<T>(
                    option: option,
                    selected: isSelected,
                    onTap: () => Navigator.pop(context, option.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PremiumSelectOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.sageTint
                : (isDark
                      ? AppColors.darkBackground.withValues(alpha: 0.45)
                      : AppColors.glass),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected
                  ? AppColors.sage.withValues(alpha: 0.42)
                  : (isDark
                        ? AppColors.darkBorder
                        : Colors.white.withValues(alpha: 0.8)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: option.highlighted
                      ? AppColors.gold.withValues(alpha: 0.16)
                      : AppColors.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  option.icon ?? Icons.auto_awesome_rounded,
                  size: 19,
                  color: option.highlighted ? AppColors.gold : AppColors.sage,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            option.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (option.badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sage,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill,
                              ),
                            ),
                            child: Text(
                              option.badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (option.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (option.trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  option.trailing!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: option.highlighted ? AppColors.gold : AppColors.sage,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.sm),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: selected ? AppColors.sage : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.sage : AppColors.taupe,
                    width: 1.2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
