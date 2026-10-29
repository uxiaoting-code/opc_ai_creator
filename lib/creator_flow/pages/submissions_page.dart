import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class SubmissionsPage extends StatefulWidget {
  const SubmissionsPage({super.key});

  @override
  State<SubmissionsPage> createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    final items = switch (_filter) {
      1 =>
        flow.submissions
            .where((s) => s.status == ReviewStatus.pending)
            .toList(),
      2 =>
        flow.submissions
            .where((s) => s.status == ReviewStatus.approved)
            .toList(),
      3 =>
        flow.submissions
            .where((s) => s.status == ReviewStatus.rejected)
            .toList(),
      _ => flow.submissions,
    };

    return CreatorScreen(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '作品审核',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '查看图片、视频和音频的审核进度',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              CreatorTag(
                label: '${flow.pendingReviewCount} 个待审核',
                color: flow.pendingReviewCount > 0
                    ? AppColors.gold
                    : AppColors.sage,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CreatorMetric(
                  label: '全部提交',
                  value: '${flow.submissions.length}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CreatorMetric(
                  label: '审核通过',
                  value: '${flow.approvedCount}',
                  icon: Icons.verified_outlined,
                  accent: AppColors.sage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CreatorMetric(
                  label: '待审核',
                  value: '${flow.pendingReviewCount}',
                  icon: Icons.hourglass_top_rounded,
                  accent: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const CreatorSectionHeader(
            title: '审核记录',
            subtitle: '点开作品可查看媒体预览和审核意见',
          ),
          const SizedBox(height: 12),
          FilterBar(
            labels: const ['全部', '审核中', '已通过', '未通过'],
            selectedIndex: _filter,
            onChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const EmptyPanel(
              icon: Icons.fact_check_outlined,
              title: '暂无审核记录',
              subtitle: '完成一次创作并提交后，审核记录会显示在这里。',
            )
          else
            for (final item in items) ...[
              _SubmissionCard(
                item: item,
                onTap: () => context.push('/submissions/${item.id}'),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.item, required this.onTap});

  final SubmissionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 82,
              height: 82,
              child: ArtworkPreview(
                mode: item.mode,
                seed: item.artworkSeed,
                height: 82,
                showLabel: false,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ReviewStatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.mode.shortLabel} · ${item.model}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '¥${item.reward.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.sage,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.taupe,
                      size: 19,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
