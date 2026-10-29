import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../creator_flow_provider.dart';
import '../widgets/creator_widgets.dart';

class SubmissionPage extends StatefulWidget {
  const SubmissionPage({super.key});

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
    final flow = context.read<CreatorFlowProvider>();
    final order = flow.currentOrder;
    _title.text = order == null ? '' : '${order.title} · 最终稿';
    _initialized = true;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final item = context.read<CreatorFlowProvider>().submitDraft(
      title: _title.text,
      note: _note.text,
    );
    setState(() => _submitting = false);
    if (!mounted) return;
    if (item == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('作品草稿已失效，请重新生成')));
      return;
    }
    context.go('/review/${item.id}');
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    final draft = flow.draft;
    if (draft == null) {
      return CreatorScreen(
        title: '提交作品',
        onBack: () => context.pop(),
        child: Column(
          children: [
            const Spacer(),
            EmptyPanel(
              icon: Icons.drafts_outlined,
              title: '没有待提交的作品',
              subtitle: '请先在工作台生成一份作品。',
              actionLabel: '返回工作台',
              onAction: () => context.go('/workbench'),
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
                ArtworkPreview(
                  mode: draft.mode,
                  seed: draft.artworkSeed,
                  height: 250,
                ),
                const SizedBox(height: 18),
                GlassPanel(
                  backgroundColor: AppColors.sage.withValues(alpha: 0.07),
                  borderColor: AppColors.sage.withValues(alpha: 0.18),
                  child: Row(
                    children: [
                      CreatorTag(
                        label: draft.mode.shortLabel,
                        color: AppColors.sage,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          flow.currentOrder?.title ?? '创作订单',
                          style: Theme.of(context).textTheme.titleSmall,
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
                const CreatorSectionHeader(title: '生成参数'),
                const SizedBox(height: 10),
                GlassPanel(
                  child: Column(
                    children: [
                      _InfoRow(label: '生成模型', value: draft.model),
                      const SizedBox(height: 12),
                      _InfoRow(label: '创作描述', value: draft.prompt, maxLines: 3),
                      for (final entry in draft.options.entries) ...[
                        const SizedBox(height: 12),
                        _InfoRow(label: entry.key, value: entry.value),
                      ],
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
            caption: '提交后可在「审核」中查看进度',
            onPressed: _submitting ? null : _submit,
          ),
        ],
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
