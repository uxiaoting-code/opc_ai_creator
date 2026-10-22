import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/task_model.dart';

/// 任务状态卡：状态、进度、耗时、重试/取消。
class TaskStatusCard extends StatelessWidget {
  const TaskStatusCard({
    super.key,
    required this.task,
    this.onTap,
    this.onRetry,
    this.onCancel,
  });

  final TaskModel? task;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = task;
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _decoration(),
        child: Text('暂无任务', style: theme.textTheme.bodySmall),
      );
    }

    final color = _statusColor(item.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _decoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.sageTint,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    item.type.isVideo
                        ? CupertinoIcons.videocam
                        : CupertinoIcons.photo,
                    size: 18,
                    color: AppColors.sage,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.skillName ?? item.typeLabel ?? 'AI 任务',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.taskNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                _StatusPill(label: item.displayStatusLabel, color: color),
              ],
            ),
            if (item.status.isActive) ...[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: LinearProgressIndicator(
                  value: item.progressRatio,
                  minHeight: 5,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.progress}% · ${item.durationLabel ?? '执行中'}',
                style: theme.textTheme.labelSmall,
              ),
            ],
            if (item.errorMsg != null && item.errorMsg!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.errorMsg!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.statusFailed,
                ),
              ),
            ],
            if (item.canRetry || item.canCancel) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  if (item.canRetry)
                    TextButton(onPressed: onRetry, child: const Text('重试')),
                  if (item.canCancel)
                    TextButton(onPressed: onCancel, child: const Text('取消')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      boxShadow: AppColors.shadowSoft,
    );
  }

  Color _statusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.queued => AppColors.statusQueued,
      TaskStatus.running => AppColors.statusRunning,
      TaskStatus.success => AppColors.statusSuccess,
      TaskStatus.failed => AppColors.statusFailed,
      TaskStatus.canceled => AppColors.statusCanceled,
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
