import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../data/creator_order_repository.dart';
import '../models/creator_order.dart';
import '../widgets/creator_widgets.dart';

class OrderMarketPage extends StatefulWidget {
  const OrderMarketPage({super.key});

  @override
  State<OrderMarketPage> createState() => _OrderMarketPageState();
}

class _OrderMarketPageState extends State<OrderMarketPage> {
  late final CreatorOrderRepository _repository;
  final List<CreatorOrder> _orders = [];
  int _filter = 0;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = CreatorOrderRepository(context.read<ApiClient>());
    if (_orders.isEmpty && !_loading) {
      _load();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository.fetchAvailable(pageSize: 50);
      if (!mounted) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(page.list);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CreatorOrder> get _visible {
    return switch (_filter) {
      1 => _orders.where((o) => o.mediaType == OrderMediaType.image).toList(),
      2 => _orders.where((o) => o.mediaType == OrderMediaType.video).toList(),
      3 => _orders.where((o) => o.mediaType == OrderMediaType.audio).toList(),
      _ => _orders,
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final visible = _visible;

    return CreatorScreen(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: RefreshIndicator(
        onRefresh: _load,
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
              ],
            ),
            const SizedBox(height: 20),
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
            if (_loading && visible.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && visible.isEmpty)
              EmptyPanel(
                icon: Icons.error_outline_rounded,
                title: '订单加载失败',
                subtitle: _error!,
                actionLabel: '重新加载',
                onAction: _load,
              )
            else if (visible.isEmpty)
              const EmptyPanel(
                icon: Icons.inbox_outlined,
                title: '暂无符合条件的订单',
                subtitle: '切换分类看看其他创作需求。',
              )
            else
              for (final order in visible) ...[
                _ApiOrderCard(
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

class _ApiOrderCard extends StatelessWidget {
  const _ApiOrderCard({required this.order, required this.onTap});

  final CreatorOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quota = order.tasksTotal == 0
        ? 0.0
        : (order.tasksTaken / order.tasksTotal).clamp(0.0, 1.0);
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MediaIcon(type: order.mediaType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 5),
                    Text(
                      '${order.brandName} · ${order.mediaType.label} · ${_deadlineLabel(order.deadlineAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '¥${order.rewardYuan.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.sage,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('已接 ${order.tasksTaken}/${order.tasksTotal}', style: theme.textTheme.bodySmall),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  child: LinearProgressIndicator(
                    value: quota,
                    minHeight: 6,
                    backgroundColor: AppColors.sageTint,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('剩 ${order.tasksLeft}', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CreatorTag(
                label: '${order.creditCost} 算力',
                color: AppColors.gold,
                icon: Icons.bolt_rounded,
              ),
              const SizedBox(width: 8),
              CreatorTag(label: order.status.label, color: AppColors.sage),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.taupe,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _deadlineLabel(DateTime? time) {
    if (time == null) return '长期';
    final diff = time.difference(DateTime.now());
    if (diff.isNegative) return '已截止';
    if (diff.inHours < 24) return '${diff.inHours + 1} 小时后截止';
    return '${diff.inDays + 1} 天后截止';
  }
}

class _MediaIcon extends StatelessWidget {
  const _MediaIcon({required this.type});

  final OrderMediaType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      OrderMediaType.image => (Icons.image_outlined, AppColors.sage),
      OrderMediaType.video => (Icons.movie_filter_outlined, AppColors.gold),
      OrderMediaType.audio => (
        Icons.graphic_eq_rounded,
        AppColors.primaryDark,
      ),
    };
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
