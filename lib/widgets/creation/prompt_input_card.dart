import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 提示词输入卡：玻璃底 + 无边框输入 + 标题行。
///
/// 只接收 controller 和回调，不负责发请求。
class PromptInputCard extends StatelessWidget {
  const PromptInputCard({
    super.key,
    required this.controller,
    this.title = '描述画面',
    this.hintText = '描述你想生成的画面…',
    this.maxLength = 2000,
    this.minLines = 4,
    this.maxLines = 6,
    this.enabled = true,
    this.onChanged,
    this.trailing,
  });

  final TextEditingController controller;
  final String title;
  final String hintText;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.darkBorder
        : Colors.white.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.82)
            : AppColors.glass,
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        border: Border.all(color: borderColor),
        boxShadow: AppColors.shadowLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                size: 18,
                color: AppColors.sage,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: minLines,
              maxLines: maxLines,
              maxLength: maxLength,
              textInputAction: TextInputAction.newline,
              onChanged: onChanged,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: theme.textTheme.bodySmall,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
