import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class ReviewStatusPage extends StatelessWidget {
  const ReviewStatusPage({super.key, required this.submissionId});

  final String submissionId;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    final item = flow.submissionById(submissionId);
    if (item == null) {
      return CreatorScreen(
        title: '审核状态',
        onBack: () => context.pop(),
        child: const EmptyPanel(
          icon: Icons.search_off_rounded,
          title: '找不到提交记录',
          subtitle: '这条审核记录可能已经失效。',
        ),
      );
    }

    final statusColor = switch (item.status) {
      ReviewStatus.pending => AppColors.gold,
      ReviewStatus.approved => AppColors.sage,
      ReviewStatus.rejected => AppColors.statusFailed,
    };
    final headline = switch (item.status) {
      ReviewStatus.pending => '作品已提交，等待订单方审核',
      ReviewStatus.approved => '审核通过，报酬已入账',
      ReviewStatus.rejected => '审核未通过，请根据意见调整',
    };

    return CreatorScreen(
      title: '审核状态',
      onBack: () => context.pop(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
              border: Border.all(color: statusColor.withValues(alpha: 0.24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    switch (item.status) {
                      ReviewStatus.pending => Icons.hourglass_top_rounded,
                      ReviewStatus.approved => Icons.verified_rounded,
                      ReviewStatus.rejected => Icons.close_rounded,
                    },
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  item.status == ReviewStatus.pending
                      ? '预计 2 小时内完成审核，请耐心等待'
                      : item.reviewNote ?? '状态已更新',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ArtworkPreview(mode: item.mode, seed: item.artworkSeed, height: 220),
          const SizedBox(height: 18),
          CreatorSectionHeader(title: '审核进度'),
          const SizedBox(height: 10),
          GlassPanel(
            child: Column(
              children: [
                _TimelineStep(
                  title: '作品已提交',
                  subtitle: _formatTime(item.createdAt),
                  done: true,
                  active: false,
                ),
                _TimelineStep(
                  title: '订单方审核',
                  subtitle: item.status == ReviewStatus.pending
                      ? '正在进行中'
                      : '审核已完成',
                  done: item.status != ReviewStatus.pending,
                  active: item.status == ReviewStatus.pending,
                ),
                _TimelineStep(
                  title: item.status == ReviewStatus.rejected
                      ? '等待修改后重新提交'
                      : '审核结果',
                  subtitle: item.status == ReviewStatus.pending
                      ? '审核通过后自动入账'
                      : item.status == ReviewStatus.approved
                      ? '报酬 ¥${item.reward.toStringAsFixed(2)} 已进入可提现余额'
                      : '可返回工作台重新生成',
                  done: item.status != ReviewStatus.pending,
                  active: false,
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CreatorSectionHeader(title: '作品信息'),
          const SizedBox(height: 10),
          GlassPanel(
            child: Column(
              children: [
                _KeyValue(label: '作品标题', value: item.title),
                const SizedBox(height: 12),
                _KeyValue(label: '关联订单', value: item.orderTitle),
                const SizedBox(height: 12),
                _KeyValue(label: '生成模型', value: item.model),
                const SizedBox(height: 12),
                _KeyValue(label: '审核状态', value: item.status.label),
              ],
            ),
          ),
          if (item.status == ReviewStatus.pending) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('演示操作', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 5),
                  Text(
                    '后台审核接口接入前，可用下面两个按钮模拟审核结果。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              flow.reviewSubmission(item.id, approved: false),
                          child: const Text('模拟驳回'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              flow.reviewSubmission(item.id, approved: true),
                          child: const Text('模拟通过'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/submissions'),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('查看全部审核记录'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.active,
    this.last = false,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.sage
        : active
        ? AppColors.gold
        : AppColors.taupe;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: done || active ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
              if (!last)
                Container(
                  width: 1.5,
                  height: 38,
                  color: color.withValues(alpha: 0.28),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: color),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
