import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class WorkbenchPage extends StatelessWidget {
  const WorkbenchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    final order = flow.currentOrder;

    if (order == null) {
      return CreatorScreen(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        child: ListView(
          children: [
            Text('创作工作台', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '接单后在这里完成图片、视频或音频作品。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 26),
            EmptyPanel(
              icon: Icons.dashboard_customize_outlined,
              title: '还没有进行中的订单',
              subtitle: '先去接单大厅选择一个订单，工作台会自动带入订单要求。',
              actionLabel: '去接单大厅',
              onAction: () => context.go('/market'),
            ),
          ],
        ),
      );
    }

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
                      '创作工作台',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '当前订单：${order.title}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              CreatorTag(label: order.mode.shortLabel, color: AppColors.sage),
            ],
          ),
          const SizedBox(height: 18),
          GlassPanel(
            backgroundColor: AppColors.sage.withValues(alpha: 0.08),
            borderColor: AppColors.sage.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CreationModeIcon(mode: order.mode, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.brand,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '¥${order.reward.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.sage,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: AppColors.sage,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.requirements.join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const CreatorSectionHeader(
            title: '选择创作工具',
            subtitle: '三种工具共享当前订单上下文，提交后会直接进入审核状态',
          ),
          const SizedBox(height: 12),
          for (final mode in CreationMode.values) ...[
            _CreationToolCard(
              mode: mode,
              recommended: mode == order.mode,
              onTap: () {
                final path = switch (mode) {
                  CreationMode.image => '/create/image',
                  CreationMode.video => '/create/video',
                  CreationMode.audio => '/create/audio',
                };
                context.push(path);
              },
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          CreatorSectionHeader(
            title: '接单提示',
            action: TextButton(
              onPressed: () => context.go('/market'),
              child: const Text('返回接单'),
            ),
          ),
          const SizedBox(height: 10),
          GlassPanel(
            child: Column(
              children: [
                _HintRow(
                  icon: Icons.bolt_rounded,
                  text: '生成作品会消耗算力，当前余额 ${flow.credits.toStringAsFixed(0)} 点',
                ),
                const SizedBox(height: 12),
                _HintRow(
                  icon: Icons.cloud_done_outlined,
                  text: '生成成功后进入提交页，可补充作品标题和说明',
                ),
                const SizedBox(height: 12),
                _HintRow(
                  icon: Icons.fact_check_outlined,
                  text: '审核状态在底部「审核」Tab 中随时查看',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreationToolCard extends StatelessWidget {
  const _CreationToolCard({
    required this.mode,
    required this.recommended,
    required this.onTap,
  });

  final CreationMode mode;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = switch (mode) {
      CreationMode.image => '适合商品主图、详情页长图、场景氛围图',
      CreationMode.video => '适合商品展示、数字人口播、短视频素材',
      CreationMode.audio => '适合商品配音、多语言口播、短视频旁白',
    };
    final accent = switch (mode) {
      CreationMode.image => AppColors.sage,
      CreationMode.video => const Color(0xFF7B8EC8),
      CreationMode.audio => AppColors.gold,
    };

    return GlassPanel(
      onTap: onTap,
      borderColor: recommended ? accent.withValues(alpha: 0.45) : null,
      child: Row(
        children: [
          CreationModeIcon(mode: mode, size: 52, color: accent),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mode.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (recommended) ...[
                      const SizedBox(width: 8),
                      CreatorTag(label: '订单推荐', color: accent),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: accent, size: 20),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.sageTint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.sage, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
