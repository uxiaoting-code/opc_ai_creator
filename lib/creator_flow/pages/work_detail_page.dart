import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class WorkDetailPage extends StatelessWidget {
  const WorkDetailPage({super.key, required this.submissionId});

  final String submissionId;

  @override
  Widget build(BuildContext context) {
    final item = context.watch<CreatorFlowProvider>().submissionById(
      submissionId,
    );
    if (item == null) {
      return CreatorScreen(
        title: '作品详情',
        onBack: () => context.pop(),
        child: const EmptyPanel(
          icon: Icons.search_off_rounded,
          title: '作品不存在',
          subtitle: '该作品可能已被移除。',
        ),
      );
    }

    return CreatorScreen(
      title: '作品详情',
      onBack: () => context.pop(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: ListView(
        children: [
          ArtworkPreview(mode: item.mode, seed: item.artworkSeed, height: 280),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.orderTitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ReviewStatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            child: Column(
              children: [
                _DetailRow(label: '作品类型', value: item.mode.label),
                const SizedBox(height: 12),
                _DetailRow(label: '生成模型', value: item.model),
                const SizedBox(height: 12),
                _DetailRow(
                  label: '订单报酬',
                  value: '¥${item.reward.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _DetailRow(label: '提交时间', value: _formatDate(item.createdAt)),
              ],
            ),
          ),
          if (item.status == ReviewStatus.approved) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.sage.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.sage,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '订单报酬已入账，可前往「我的」页面提现。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/withdraw'),
                    child: const Text('去提现'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const CreatorSectionHeader(title: '创作内容'),
          const SizedBox(height: 10),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('生成描述', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  item.prompt,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('交付说明', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    item.note,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (item.reviewNote != null) ...[
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('审核意见', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    item.reviewNote!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: item.status == ReviewStatus.rejected
                          ? AppColors.statusFailed
                          : AppColors.sage,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.push('/review/${item.id}'),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const Text('查看审核进度'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day $hour:$minute';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
