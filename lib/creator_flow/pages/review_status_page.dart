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

class ReviewStatusPage extends StatefulWidget {
  const ReviewStatusPage({super.key, required this.submissionId});

  final String submissionId;

  @override
  State<ReviewStatusPage> createState() => _ReviewStatusPageState();
}

class _ReviewStatusPageState extends State<ReviewStatusPage> {
  late final CreatorSubmissionRepository _repository;
  CreatorSubmission? _item;
  bool _loading = true;
  String? _error;

  int? get _id => int.tryParse(widget.submissionId);

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
    final id = _id;
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

  @override
  Widget build(BuildContext context) {
    final item = _item;
    if (_loading && item == null) {
      return CreatorScreen(
        title: '审核状态',
        onBack: () => context.pop(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (item == null) {
      return CreatorScreen(
        title: '审核状态',
        onBack: () => context.pop(),
        child: EmptyPanel(
          icon: Icons.search_off_rounded,
          title: '找不到提交记录',
          subtitle: _error ?? '这条审核记录可能已经失效。',
          actionLabel: '重新加载',
          onAction: _load,
        ),
      );
    }

    return CreatorScreen(
      title: '审核状态',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _StatusHero(item: item),
            const SizedBox(height: 18),
            _SubmissionMedia(item: item),
            const SizedBox(height: 18),
            const CreatorSectionHeader(title: '审核进度'),
            const SizedBox(height: 10),
            GlassPanel(
              child: Column(
                children: [
                  _TimelineStep(
                    title: '作品已提交',
                    subtitle: _formatTime(item.submittedAt),
                    done: true,
                    active: false,
                  ),
                  _TimelineStep(
                    title: '订单方审核',
                    subtitle: item.status == SubmissionReviewStatus.pending
                        ? '正在进行中'
                        : '审核已完成',
                    done: item.status != SubmissionReviewStatus.pending,
                    active: item.status == SubmissionReviewStatus.pending,
                  ),
                  _TimelineStep(
                    title: item.status == SubmissionReviewStatus.rejected
                        ? '等待修改后重新提交'
                        : '审核结果',
                    subtitle: item.status == SubmissionReviewStatus.pending
                        ? '审核通过后自动入账'
                        : item.status == SubmissionReviewStatus.approved
                        ? '报酬 ¥${item.rewardYuan.toStringAsFixed(2)} 已进入可提现余额'
                        : item.reviewNote ?? '可返回工作台重新生成',
                    done: item.status != SubmissionReviewStatus.pending,
                    active: false,
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const CreatorSectionHeader(title: '作品信息'),
            const SizedBox(height: 10),
            GlassPanel(
              child: Column(
                children: [
                  _KeyValue(label: '作品标题', value: item.title),
                  const SizedBox(height: 12),
                  _KeyValue(label: '关联订单', value: item.orderTitle),
                  const SizedBox(height: 12),
                  _KeyValue(label: '提交版本', value: 'V${item.versionNo}'),
                  const SizedBox(height: 12),
                  _KeyValue(label: '审核状态', value: item.displayStatus),
                  if (item.note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _KeyValue(label: '交付说明', value: item.note),
                  ],
                  if (item.reviewNote?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _KeyValue(label: '审核意见', value: item.reviewNote!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/submissions'),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('查看全部审核记录'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '—';
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.item});

  final CreatorSubmission item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      SubmissionReviewStatus.pending => AppColors.gold,
      SubmissionReviewStatus.approved => AppColors.sage,
      SubmissionReviewStatus.rejected => AppColors.statusFailed,
    };
    final title = switch (item.status) {
      SubmissionReviewStatus.pending => '作品已提交，等待订单方审核',
      SubmissionReviewStatus.approved => '审核通过，报酬已入账',
      SubmissionReviewStatus.rejected => '审核未通过，请根据意见调整',
    };
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              switch (item.status) {
                SubmissionReviewStatus.pending => Icons.hourglass_top_rounded,
                SubmissionReviewStatus.approved => Icons.verified_rounded,
                SubmissionReviewStatus.rejected => Icons.close_rounded,
              },
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            item.status == SubmissionReviewStatus.pending
                ? '审核结果以订单方为准，可下拉刷新'
                : item.reviewNote ?? '状态已更新',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SubmissionMedia extends StatelessWidget {
  const _SubmissionMedia({required this.item});

  final CreatorSubmission item;

  @override
  Widget build(BuildContext context) {
    if (item.mediaType == OrderMediaType.audio) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 46),
            SizedBox(height: 8),
            Text('音频作品', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }
    final url = AppConfig.resolveAssetUrl(item.displayImageUrl);
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
      child: Image.network(
        url,
        height: 240,
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

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.active,
    this.last = false,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.sage
        : active
        ? AppColors.gold
        : AppColors.taupe;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: done || active ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
              if (!last)
                Container(
                  width: 1.5,
                  height: 38,
                  color: color.withValues(alpha: 0.28),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
