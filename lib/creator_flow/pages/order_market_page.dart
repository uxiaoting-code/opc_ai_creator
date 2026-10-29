import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class OrderMarketPage extends StatefulWidget {
  const OrderMarketPage({super.key});

  @override
  State<OrderMarketPage> createState() => _OrderMarketPageState();
}

class _OrderMarketPageState extends State<OrderMarketPage> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    final auth = context.watch<AuthProvider>();
    final filtered = switch (_filter) {
      1 => flow.orders.where((o) => o.mode == CreationMode.image).toList(),
      2 => flow.orders.where((o) => o.mode == CreationMode.video).toList(),
      3 => flow.orders.where((o) => o.mode == CreationMode.audio).toList(),
      _ => flow.orders,
    };

    return CreatorScreen(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: RefreshIndicator(
        onRefresh: () async =>
            Future<void>.delayed(const Duration(milliseconds: 450)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '你好，${auth.user?.nickname ?? auth.user?.username ?? '创作者'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '今天也有新的电商创作订单',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${flow.credits.toStringAsFixed(0)} 算力',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            CreatorHeroCard(
              eyebrow: 'CREATOR MARKET',
              title: '接一个订单，\\n开始今天的创作。',
              subtitle: '图片、视频、音频三类订单持续更新，按你的创作能力自由选择。',
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${flow.orders.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '可接订单',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (flow.currentOrder != null) ...[
              const SizedBox(height: 16),
              _ActiveOrderCard(
                order: flow.currentOrder!,
                onTap: () => context.go('/workbench'),
              ),
            ],
            const SizedBox(height: 24),
            CreatorSectionHeader(
              title: '接单大厅',
              subtitle: '选择一个适合你的真实创作需求',
              action: TextButton(
                onPressed: () => setState(() => _filter = 0),
                child: const Text('全部'),
              ),
            ),
            const SizedBox(height: 12),
            FilterBar(
              labels: const ['全部', '图片', '视频', '音频'],
              selectedIndex: _filter,
              onChanged: (index) => setState(() => _filter = index),
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              const EmptyPanel(
                icon: Icons.inbox_outlined,
                title: '暂无符合条件的订单',
                subtitle: '切换分类看看其他创作需求。',
              )
            else
              for (final order in filtered) ...[
                OrderCard(
                  order: order,
                  onTap: () => context.push('/market/${order.id}'),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order, required this.onTap});

  final MarketOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      onTap: onTap,
      backgroundColor: AppColors.sage.withValues(alpha: 0.08),
      borderColor: AppColors.sage.withValues(alpha: 0.24),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: AppColors.sage,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('进行中的订单', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  order.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const CreatorTag(label: '继续创作', color: AppColors.sage),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.sage),
        ],
      ),
    );
  }
}
