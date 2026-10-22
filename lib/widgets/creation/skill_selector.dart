import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/skill_model.dart';

/// 创作线路选择器：横向胶囊列表。
///
/// 只依赖 [SkillModel]，选中结果通过回调交给页面。
class SkillSelector extends StatelessWidget {
  const SkillSelector({
    super.key,
    required this.skills,
    required this.selectedId,
    required this.onChanged,
    this.title = '创作线路',
    this.subtitle = '选一条线路直接开画',
    this.allowAuto = true,
  });

  final List<SkillModel> skills;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final String title;
  final String subtitle;
  final bool allowAuto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(subtitle, style: theme.textTheme.labelSmall)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (skills.isEmpty)
          Text('暂无可用线路', style: theme.textTheme.bodySmall)
        else
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: (allowAuto ? 1 : 0) + skills.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (allowAuto && index == 0) {
                  return _Pill(
                    label: '自动线路',
                    selected: selectedId == null,
                    onTap: () => onChanged(null),
                  );
                }
                final skill = skills[allowAuto ? index - 1 : index];
                return _Pill(
                  label: skill.name,
                  selected: selectedId == skill.id,
                  onTap: () => onChanged(skill.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sageTint
              : (isDark ? AppColors.darkSurface : AppColors.glass),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected
                ? AppColors.sage.withValues(alpha: 0.45)
                : (isDark
                      ? AppColors.darkBorder
                      : Colors.white.withValues(alpha: 0.75)),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12.5,
            color: selected ? AppColors.sage : AppColors.taupe,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
