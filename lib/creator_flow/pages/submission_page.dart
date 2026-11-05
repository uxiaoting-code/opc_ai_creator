import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/task_model.dart';
import '../data/creator_submission_repository.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class SubmissionPage extends StatefulWidget {
  const SubmissionPage({super.key, this.initialTask});

  final TaskModel? initialTask;

  @override
  State<SubmissionPage> createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  bool _submitting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final task = widget.initialTask;
    if (task != null) {
      final prompt = (task.prompt ?? '').trim();
      _title.text = prompt.isEmpty
          ? '作品 ${task.taskNo}'
          : (prompt.length > 24 ? '${prompt.substring(0, 24)}…' : prompt);
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final task = widget.initialTask;
    if (task == null || task.orderId == null) return;
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写作品标题')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final submission = await CreatorSubmissionRepository(
        context.read<ApiClient>(),
      ).submit(
        orderId: task.orderId!,
        taskId: task.id,
        title: _title.text.trim(),
        note: _note.text.trim(),
      );
      if (!mounted) return;
      context.go('/review/${submission.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.initialTask;
    if (task == null || task.orderId == null || task.status != TaskStatus.success) {
      return CreatorScreen(
        title: '提交作品',
        onBack: () => context.pop(),
        child: Column(
          children: [
            const Spacer(),
            EmptyPanel(
              icon: Icons.drafts_outlined,
              title: '没有待提交的作品',
              subtitle: '请先生成一条成功且绑定订单的任务。',
              actionLabel: '返回创作',
              onAction: () => context.go('/create'),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return CreatorScreen(
      title: '提交作品',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _TaskResultPreview(task: task),
                const SizedBox(height: 18),
                GlassPanel(
                  backgroundColor: AppColors.sage.withValues(alpha: 0.07),
                  borderColor: AppColors.sage.withValues(alpha: 0.18),
                  child: Row(
                    children: [
                      CreatorTag(label: task.type.label, color: AppColors.sage),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '订单 #${task.orderId} · ${task.taskNo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const CreatorTag(label: '待提交', color: AppColors.gold),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const FormFieldLabel('作品标题', required: true),
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(hintText: '给作品起一个容易识别的标题'),
                ),
                const SizedBox(height: 18),
                const FormFieldLabel('交付说明'),
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '说明素材、尺寸、修改点或需要客户重点关注的内容',
                  ),
                ),
                const SizedBox(height: 18),
                const CreatorSectionHeader(title: '生成信息'),
                const SizedBox(height: 10),
                GlassPanel(
                  child: Column(
                    children: [
                      _InfoRow(label: '任务号', value: task.taskNo),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: '创作描述',
                        value: task.prompt ?? '—',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: '生成结果',
                        value: task.resultUrl ?? '—',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '提交后订单会进入审核状态，审核通过后订单报酬将进入可提现余额。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          CreatorBottomAction(
            label: _submitting ? '正在提交…' : '提交给订单方审核',
            icon: Icons.cloud_upload_outlined,
            caption: '提交后可在审核记录中查看进度',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _TaskResultPreview extends StatelessWidget {
  const _TaskResultPreview({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final raw = task.resultThumb ?? task.resultUrl;
    if (raw == null || raw.isEmpty || task.type == TaskType.textToAudio) {
      return ArtworkPreview(
        mode: switch (task.type) {
          TaskType.imageToVideo => CreationMode.video,
          TaskType.textToAudio => CreationMode.audio,
          TaskType.textToImage => CreationMode.image,
        },
        seed: task.id,
        height: 250,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
      child: Image.network(
        AppConfig.resolveAssetUrl(raw),
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ArtworkPreview(
          mode: task.type == TaskType.imageToVideo
              ? CreationMode.video
              : CreationMode.image,
          seed: task.id,
          height: 250,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.maxLines = 1});

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
