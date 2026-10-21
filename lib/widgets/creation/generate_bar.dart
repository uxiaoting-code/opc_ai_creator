import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 底部固定生成栏：算力消耗 + 渐变主按钮。
///
/// 只负责展示和回调，真正的提交由页面完成。
class GenerateBar extends StatelessWidget {
  const GenerateBar({
    super.key,
    required this.creditCost,
    required this.onGenerate,
    this.credits,
    this.submitting = false,
    this.label = '开始生成',
    this.hint,
    this.leading,
  });

  final int creditCost;
  final int? credits;
  final bool submitting;
  final String label;
  final VoidCallback? onGenerate;
  final String? hint;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enough = credits == null || credits! >= creditCost;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.94)
            : AppColors.glassStrong,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        boxShadow: AppColors.shadowSoft,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            10,
            AppSpacing.pagePadding,
            12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (leading != null) leading!,
                  const Spacer(),
                  Text(
                    '预计消耗 $creditCost 算力',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: enough
                        ? AppColors.primaryGradient
                        : const LinearGradient(
                            colors: [Color(0xFFBDB5AA), Color(0xFFA79E92)],
                          ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    boxShadow: enough ? AppColors.shadowButton : null,
                  ),
                  child: FilledButton(
                    onPressed: submitting || !enough ? null : onGenerate,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                    child: submitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Text('正在提交…'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.sparkles, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Text(label),
                            ],
                          ),
                  ),
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 5),
                Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
