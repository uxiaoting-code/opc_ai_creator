import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../data/creator_submission_repository.dart';
import '../models/creator_order.dart';
import '../models/creator_submission.dart';
import '../widgets/creator_widgets.dart';

class WorkDetailPage extends StatefulWidget {
  const WorkDetailPage({super.key, required this.submissionId});

  final String submissionId;

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  late final CreatorSubmissionRepository _repository;
  CreatorSubmission? _item;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = CreatorSubmissionRepository(context.read<ApiClient>());
    if (_item == null && !_loading) _load();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = int.tryParse(widget.submissionId);
    if (id == null) {
      setState(() {
        _error = '提交记录 ID 不合法';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await _repository.fetchDetail(id);
      if (!mounted) return;
      setState(() => _item = item);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/submissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return CreatorScreen(
      title: '作品详情',
      onBack: _goBack,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: _loading && item == null
          ? const Center(child: CircularProgressIndicator())
          : item == null
          ? EmptyPanel(
              icon: Icons.search_off_rounded,
              title: '作品加载失败',
              subtitle: _error ?? '该作品可能已被移除。',
              actionLabel: '重新加载',
              onAction: _load,
            )
          : ListView(
              children: [
                _WorkMedia(item: item),
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
                    CreatorTag(
                      label: item.displayStatus,
                      color: switch (item.status) {
                        SubmissionReviewStatus.pending => AppColors.gold,
                        SubmissionReviewStatus.approved => AppColors.sage,
                        SubmissionReviewStatus.rejected =>
                          AppColors.statusFailed,
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassPanel(
                  child: Column(
                    children: [
                      _DetailRow(
                        label: '作品类型',
                        value: item.mediaType.label,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: '订单报酬',
                        value: '¥${item.rewardYuan.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(label: '提交版本', value: 'V${item.versionNo}'),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: '提交时间',
                        value: _formatDate(item.submittedAt),
                      ),
                    ],
                  ),
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const CreatorSectionHeader(title: '交付说明'),
                  const SizedBox(height: 10),
                  GlassPanel(
                    child: Text(
                      item.note,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                if (item.reviewNote?.isNotEmpty == true) ...[
                  const SizedBox(height: 18),
                  const CreatorSectionHeader(title: '审核意见'),
                  const SizedBox(height: 10),
                  GlassPanel(
                    child: Text(
                      item.reviewNote!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: item.status == SubmissionReviewStatus.rejected
                            ? AppColors.statusFailed
                            : AppColors.sage,
                      ),
                    ),
                  ),
                ],
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

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day $hour:$minute';
  }
}

class _WorkMedia extends StatelessWidget {
  const _WorkMedia({required this.item});

  final CreatorSubmission item;

  @override
  Widget build(BuildContext context) {
    if (item.mediaType == OrderMediaType.audio) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        ),
        child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 54),
      );
    }
    final url = AppConfig.resolveAssetUrl(item.displayImageUrl);
    if (url.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
      child: Image.network(
        url,
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: 220,
          color: AppColors.sageTint,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, size: 42),
        ),
      ),
    );
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
