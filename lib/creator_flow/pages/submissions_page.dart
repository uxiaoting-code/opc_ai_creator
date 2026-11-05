import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../data/creator_submission_repository.dart';
import '../models/creator_order.dart';
import '../models/creator_submission.dart';
import '../widgets/creator_widgets.dart';

class SubmissionsPage extends StatefulWidget {
  const SubmissionsPage({super.key});

  @override
  State<SubmissionsPage> createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  late final CreatorSubmissionRepository _repository;
  List<CreatorSubmission> _items = const [];
  int _filter = 0;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = CreatorSubmissionRepository(context.read<ApiClient>());
    if (_items.isEmpty && !_loading) {
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
      final page = await _repository.fetchMy();
      if (!mounted) return;
      setState(() => _items = page.list);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CreatorSubmission> get _visible {
    return switch (_filter) {
      1 => _items
          .where((item) => item.status == SubmissionReviewStatus.pending)
          .toList(),
      2 => _items
          .where((item) => item.status == SubmissionReviewStatus.approved)
          .toList(),
      3 => _items
          .where((item) => item.status == SubmissionReviewStatus.rejected)
          .toList(),
      _ => _items,
    };
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final pending = _items
        .where((item) => item.status == SubmissionReviewStatus.pending)
        .length;
    final approved = _items
        .where((item) => item.status == SubmissionReviewStatus.approved)
        .length;

    return CreatorScreen(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  label: '$pending 个待审核',
                  color: pending > 0 ? AppColors.gold : AppColors.sage,
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
                    value: '${_items.length}',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CreatorMetric(
                    label: '审核通过',
                    value: '$approved',
                    icon: Icons.verified_outlined,
                    accent: AppColors.sage,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CreatorMetric(
                    label: '待审核',
                    value: '$pending',
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
            if (_loading && visible.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && visible.isEmpty)
              EmptyPanel(
                icon: Icons.error_outline_rounded,
                title: '审核记录加载失败',
                subtitle: _error!,
                actionLabel: '重新加载',
                onAction: _load,
              )
            else if (visible.isEmpty)
              const EmptyPanel(
                icon: Icons.fact_check_outlined,
                title: '暂无审核记录',
                subtitle: '完成一次创作并提交后，审核记录会显示在这里。',
              )
            else
              for (final item in visible) ...[
                _SubmissionCard(
                  item: item,
                  onTap: () => context.push('/submissions/${item.id}'),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.item, required this.onTap});

  final CreatorSubmission item;
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
              child: _SubmissionThumb(item: item),
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
                    _StatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.mediaType.label} · ${item.orderTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '¥${item.rewardYuan.toStringAsFixed(2)}',
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

class _SubmissionThumb extends StatelessWidget {
  const _SubmissionThumb({required this.item});

  final CreatorSubmission item;

  @override
  Widget build(BuildContext context) {
    if (item.mediaType == OrderMediaType.audio) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: AppColors.sageTint),
        child: Icon(Icons.graphic_eq_rounded, color: AppColors.sage, size: 34),
      );
    }
    final url = AppConfig.resolveAssetUrl(item.displayImageUrl);
    if (url.isEmpty) {
      return const ColoredBox(color: AppColors.sageTint);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.sageTint),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SubmissionReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SubmissionReviewStatus.pending => AppColors.gold,
      SubmissionReviewStatus.approved => AppColors.sage,
      SubmissionReviewStatus.rejected => AppColors.statusFailed,
    };
    return CreatorTag(label: status.label, color: color);
  }
}
