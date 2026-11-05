import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../data/creator_order_repository.dart';
import '../models/creator_order.dart';
import '../widgets/creator_widgets.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final CreatorOrderRepository _repository;
  CreatorOrderDetail? _detail;
  bool _loading = true;
  bool _accepting = false;
  String? _error;

  int? get _id => int.tryParse(widget.orderId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = CreatorOrderRepository(context.read<ApiClient>());
    if (_detail == null && _error == null && !_loading) {
      _load();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null) {
      setState(() {
        _error = '订单 ID 不合法';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repository.fetchDetail(id);
      if (!mounted) return;
      setState(() => _detail = detail);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptAndCreate(CreatorOrder order) async {
    setState(() => _accepting = true);
    try {
      await _repository.accept(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('接单成功，进入创作')));
      _openCreation(order);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  void _openCreation(CreatorOrder order) {
    final path = switch (order.mediaType) {
      OrderMediaType.image => '/create/image',
      OrderMediaType.video => '/create/video',
      OrderMediaType.audio => '/create/audio',
    };
    context.go(path, extra: CreatorCreationArgs(orderId: order.id));
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return CreatorScreen(
      title: '订单详情',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: _buildBody(detail),
    );
  }

  Widget _buildBody(CreatorOrderDetail? detail) {
    if (_loading && detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (detail == null || _error != null) {
      return EmptyPanel(
        icon: Icons.search_off_rounded,
        title: '订单加载失败',
        subtitle: _error ?? '该订单可能已经下架。',
        actionLabel: '重新加载',
        onAction: _load,
      );
    }

    final order = detail.order;
    final accepted = detail.myAcceptance != null;
    final canAccept = detail.canAccept;
    final buttonLabel = accepted
        ? '继续创作'
        : (canAccept ? '立即接单' : '当前不可接单');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              CreatorHeroCard(
                eyebrow: '${order.brandName} · ${order.mediaType.label}',
                title: order.title,
                subtitle: order.description,
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${order.rewardYuan.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
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
                      value: _deadlineLabel(order.deadlineAt),
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
              const CreatorSectionHeader(title: '订单要求'),
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
            ],
          ),
        ),
        CreatorBottomAction(
          label: _accepting ? '接单中…' : buttonLabel,
          icon: accepted
              ? Icons.auto_awesome_rounded
              : Icons.shopping_bag_outlined,
          caption: accepted
              ? '已接单，可进入创作并提交作品'
              : (canAccept ? '接单后直接进入对应创作页' : detail.unavailableReason),
          onPressed: _accepting || !canAccept && !accepted
              ? null
              : () {
                  if (accepted) {
                    _openCreation(order);
                  } else {
                    _acceptAndCreate(order);
                  }
                },
        ),
      ],
    );
  }

  String _deadlineLabel(DateTime? time) {
    if (time == null) return '—';
    final now = DateTime.now();
    final diff = time.difference(now);
    if (diff.isNegative) return '已截止';
    final hours = diff.inHours;
    if (hours < 24) return '${diff.inHours + 1} 小时内';
    return '${diff.inDays + 1} 天';
  }
}
