import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

/// 原型中的「生成结果」页。
///
/// 生成成功后的第一站：展示结果摘要、模型与耗时、操作栏，
/// 以及把作品提交到当前订单的主按钮。
class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    final draft = flow.draft;
    final order = flow.currentOrder;

    return CreatorScreen(
      title: '生成结果',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: draft == null
          ? _EmptyResult(
              onBack: () => context.go('/create'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      if (order != null) _OrderContextBar(order: order),
                      _PromptSummary(draft: draft),
                      const SizedBox(height: 12),
                      _ResultMeta(draft: draft),
                      const SizedBox(height: 14),
                      _ResultViewer(draft: draft),
                      const SizedBox(height: 18),
                      const CreatorSectionHeader(title: '试试这些微调'),
                      const SizedBox(height: 10),
                      _RefineRow(mode: draft.mode),
                    ],
                  ),
                ),
                CreatorBottomAction(
                  label: order == null ? '完成' : '提交到订单',
                  icon: order == null
                      ? Icons.check_rounded
                      : Icons.task_alt_rounded,
                  caption: order == null
                      ? '本次生成未绑定接单订单'
                      : '完成后提交至 ${order.brand} · ${order.title}',
                  onPressed: () {
                    if (order == null) {
                      context.go('/create');
                    } else {
                      context.push('/submission');
                    }
                  },
                ),
              ],
            ),
    );
  }
}

class _OrderContextBar extends StatelessWidget {
  const _OrderContextBar({required this.order});

  final MarketOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassPanel(
        backgroundColor: AppColors.sage.withValues(alpha: 0.08),
        borderColor: AppColors.sage.withValues(alpha: 0.2),
        child: Row(
          children: [
            CreationModeIcon(mode: order.mode, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '任务：${order.brand} · ${order.mode.shortLabel}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.taupe),
          ],
        ),
      ),
    );
  }
}

class _PromptSummary extends StatelessWidget {
  const _PromptSummary({required this.draft});

  final GeneratedDraft draft;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.sage),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              draft.prompt.isEmpty ? '（未填写创作描述）' : draft.prompt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMeta extends StatelessWidget {
  const _ResultMeta({required this.draft});

  final GeneratedDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: CreatorMetric(
            label: '模型',
            value: draft.model,
            icon: Icons.auto_awesome_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CreatorMetric(
            label: '实际消耗',
            value: '${_cost(draft.mode)} 算力',
            icon: Icons.bolt_rounded,
            accent: AppColors.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CreatorMetric(
            label: '生成耗时',
            value: '3.2s',
            icon: Icons.timer_outlined,
            accent: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  int _cost(CreationMode mode) => switch (mode) {
    CreationMode.image => 12,
    CreationMode.video => 48,
    CreationMode.audio => 8,
  };
}

class _ResultViewer extends StatefulWidget {
  const _ResultViewer({required this.draft});

  final GeneratedDraft draft;

  @override
  State<_ResultViewer> createState() => _ResultViewerState();
}

class _ResultViewerState extends State<_ResultViewer> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ArtworkPreview(
          mode: widget.draft.mode,
          seed: widget.draft.artworkSeed + _index,
          height: 320,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final selected = index == _index;
            return GestureDetector(
              onTap: () => setState(() => _index = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 22 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected ? AppColors.sage : AppColors.divider,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        const _ResultActions(),
      ],
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.download_rounded, '下载'),
      (Icons.refresh_rounded, '重生'),
      (Icons.hd_rounded, '高清'),
      (Icons.photo_filter_rounded, '参考'),
      (Icons.share_rounded, '分享'),
    ];
    return Row(
      children: [
        for (final action in actions)
          Expanded(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('${action.$2}：演示功能，接入真实结果后开放')),
                  );
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Icon(action.$1, color: AppColors.sage, size: 20),
                    const SizedBox(height: 5),
                    Text(
                      action.$2,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RefineRow extends StatelessWidget {
  const _RefineRow({required this.mode});

  final CreationMode mode;

  @override
  Widget build(BuildContext context) {
    final chips = mode == CreationMode.image
        ? ['换成暖光', '加模特', '换背景色', '生成视频']
        : ['更慢一点', '换背景', '加字幕', '重新生成'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in chips)
          ActionChip(
            label: Text(chip),
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('已应用：$chip')));
            },
          ),
      ],
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return EmptyPanel(
      icon: Icons.image_not_supported_outlined,
      title: '还没有生成结果',
      subtitle: '请先选择一个创作模式并完成一次生成。',
      actionLabel: '返回创作首页',
      onAction: onBack,
    );
  }
}
