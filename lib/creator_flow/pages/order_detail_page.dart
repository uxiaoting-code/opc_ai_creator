import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    final order = flow.orderById(orderId);
    if (order == null) {
      return CreatorScreen(
        title: '订单详情',
        onBack: () => context.pop(),
        child: const EmptyPanel(
          icon: Icons.search_off_rounded,
          title: '订单不存在',
          subtitle: '该订单可能已经下架。',
        ),
      );
    }

    final isCurrent = flow.currentOrder?.id == order.id;
    final canAccept = order.status == MarketOrderStatus.open || isCurrent;
    final title = isCurrent ? '进入工作台' : '立即接单';

    return CreatorScreen(
      title: '订单详情',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                CreatorHeroCard(
                  eyebrow: '${order.brand} · ${order.mode.shortLabel}',
                  title: order.title,
                  subtitle: order.description,
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${order.reward.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '订单报酬',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: CreatorMetric(
                        label: '截止时间',
                        value: order.deadline.replaceFirst('剩余 ', ''),
                        icon: Icons.schedule_rounded,
                        accent: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CreatorMetric(
                        label: '剩余名额',
                        value: '${order.tasksLeft} 个',
                        icon: Icons.groups_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CreatorSectionHeader(title: '订单要求'),
                const SizedBox(height: 10),
                GlassPanel(
                  child: Column(
                    children: [
                      for (var i = 0; i < order.requirements.length; i++) ...[
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.sageTint,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: AppColors.sage,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                order.requirements[i],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        if (i != order.requirements.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CreatorSectionHeader(
                  title: '创作工作台',
                  subtitle: '接单后进入工作台完成作品并提交审核',
                ),
                const SizedBox(height: 10),
                GlassPanel(
                  child: Row(
                    children: [
                      CreationModeIcon(mode: order.mode, size: 49),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.mode.label,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '本次生成预计消耗 ${order.creditCost} 算力',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      CreatorTag(label: '工作台已就绪', color: AppColors.sage),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CreatorBottomAction(
            label: title,
            icon: isCurrent
                ? Icons.dashboard_customize_rounded
                : Icons.shopping_bag_outlined,
            caption: canAccept ? '接单后可随时回到工作台继续创作' : '该订单当前不可接取',
            onPressed: canAccept
                ? () {
                    if (!isCurrent) flow.acceptOrder(order.id);
                    context.go('/workbench');
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
