import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class CreateImagePage extends StatelessWidget {
  const CreateImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CreationFormPage(
      mode: CreationMode.image,
      title: '文生图',
      defaultModel: 'GPT-4o Image',
      promptHint: '例如：春季香水瓶，奶油色背景，柔和自然光，高级电商广告质感',
      models: ['GPT-4o Image', 'DALL·E 3', '通义万相'],
      choices: [
        _ChoiceGroup('画面风格', ['高级留白', '自然光', '场景化', '极简']),
        _ChoiceGroup('画面比例', ['1:1', '3:4', '4:3', '9:16']),
        _ChoiceGroup('清晰度', ['标准', '高清', '超清']),
      ],
    );
  }
}

class CreateVideoPage extends StatelessWidget {
  const CreateVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CreationFormPage(
      mode: CreationMode.video,
      title: '图生视频',
      defaultModel: '可灵 Kling',
      promptHint: '例如：咖啡机缓慢旋转，蒸汽升起，镜头平稳推进，暖色生活场景',
      models: ['可灵 Kling', 'Runway Gen-3', '即梦 Jimeng'],
      choices: [
        _ChoiceGroup('镜头运动', ['平稳推进', '环绕展示', '拉近特写', '固定镜头']),
        _ChoiceGroup('视频比例', ['9:16', '16:9', '1:1']),
        _ChoiceGroup('视频时长', ['5 秒', '10 秒', '15 秒']),
      ],
      showReference: true,
    );
  }
}

class CreateAudioPage extends StatelessWidget {
  const CreateAudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CreationFormPage(
      mode: CreationMode.audio,
      title: '生成音频',
      defaultModel: '温柔女声',
      promptHint: '输入需要配音的商品文案，例如：欢迎来到花漾美妆直播间……',
      models: ['温柔女声', '磁性男声', '活力主播', '多语言女声'],
      choices: [
        _ChoiceGroup('语言', ['中文', 'English', '日本語']),
        _ChoiceGroup('语速', ['慢速', '适中', '快速']),
        _ChoiceGroup('输出格式', ['MP3', 'WAV']),
      ],
      audioMode: true,
    );
  }
}

class _ChoiceGroup {
  const _ChoiceGroup(this.label, this.values);

  final String label;
  final List<String> values;
}

class _CreationFormPage extends StatefulWidget {
  const _CreationFormPage({
    required this.mode,
    required this.title,
    required this.defaultModel,
    required this.promptHint,
    required this.models,
    required this.choices,
    this.showReference = false,
    this.audioMode = false,
  });

  final CreationMode mode;
  final String title;
  final String defaultModel;
  final String promptHint;
  final List<String> models;
  final List<_ChoiceGroup> choices;
  final bool showReference;
  final bool audioMode;

  @override
  State<_CreationFormPage> createState() => _CreationFormPageState();
}

class _CreationFormPageState extends State<_CreationFormPage> {
  late final TextEditingController _prompt;
  late String _model;
  late final List<String> _selected;
  bool _busy = false;
  bool _hasReference = true;

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController();
    _model = widget.defaultModel;
    _selected = [for (final group in widget.choices) group.values.first];
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  int get _cost => switch (widget.mode) {
    CreationMode.image => 12,
    CreationMode.video => 48,
    CreationMode.audio => 8,
  };

  Future<void> _generate() async {
    final flow = context.read<CreatorFlowProvider>();
    if (flow.currentOrder == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('尚未接单'),
          content: const Text('请先从接单大厅选择任务，再进入工作台创作。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/market');
              },
              child: const Text('去接单'),
            ),
          ],
        ),
      );
      return;
    }
    if (_prompt.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先输入创作描述')));
      return;
    }
    if (widget.showReference && !_hasReference) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('视频生成需要先添加一张参考图')));
      return;
    }

    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final options = <String, String>{
      for (var i = 0; i < widget.choices.length; i++)
        widget.choices[i].label: _selected[i],
      if (widget.showReference) '参考图': _hasReference ? '商品示例图' : '未添加',
    };
    final ok = flow.createDraft(
      mode: widget.mode,
      prompt: _prompt.text.trim(),
      model: _model,
      options: options,
    );
    setState(() => _busy = false);
    if (!mounted) return;
    if (ok) {
      context.push('/submission');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('算力不足，请先充值')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    return Stack(
      children: [
        CreatorScreen(
          title: widget.title,
          onBack: () => context.pop(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (flow.currentOrder != null)
                      GlassPanel(
                        backgroundColor: AppColors.sage.withValues(alpha: 0.07),
                        borderColor: AppColors.sage.withValues(alpha: 0.18),
                        child: Row(
                          children: [
                            CreationModeIcon(mode: widget.mode, size: 42),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '当前订单',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    flow.currentOrder!.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.showReference) ...[
                      const SizedBox(height: 18),
                      const FormFieldLabel('参考图', required: true),
                      _ReferenceImageCard(
                        active: _hasReference,
                        onTap: () =>
                            setState(() => _hasReference = !_hasReference),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FormFieldLabel(
                      widget.audioMode ? '配音文案' : '创作描述',
                      required: true,
                    ),
                    TextField(
                      controller: _prompt,
                      minLines: widget.audioMode ? 5 : 4,
                      maxLines: 8,
                      maxLength: widget.audioMode ? 500 : 1200,
                      decoration: InputDecoration(
                        hintText: widget.promptHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const FormFieldLabel('生成模型'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final model in widget.models)
                          ChoiceChip(
                            label: Text(model),
                            selected: _model == model,
                            onSelected: (_) => setState(() => _model = model),
                          ),
                      ],
                    ),
                    for (var i = 0; i < widget.choices.length; i++) ...[
                      const SizedBox(height: 18),
                      FormFieldLabel(widget.choices[i].label),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final value in widget.choices[i].values)
                            ChoiceChip(
                              label: Text(value),
                              selected: _selected[i] == value,
                              onSelected: (_) =>
                                  setState(() => _selected[i] = value),
                            ),
                        ],
                      ),
                    ],
                    if (widget.audioMode) ...[
                      const SizedBox(height: 18),
                      const CreatorSectionHeader(
                        title: '试听与生成',
                        subtitle: '生成后可在提交页试听音频波形',
                      ),
                      const SizedBox(height: 10),
                      ArtworkPreview(
                        mode: CreationMode.audio,
                        seed: 48,
                        height: 160,
                        showLabel: false,
                      ),
                    ],
                  ],
                ),
              ),
              CreatorBottomAction(
                label: _busy
                    ? '生成中…'
                    : '生成${widget.mode == CreationMode.audio ? '音频' : '作品'}',
                icon: Icons.auto_awesome_rounded,
                caption:
                    '预计消耗 $_cost 算力 · 当前余额 ${flow.credits.toStringAsFixed(0)}',
                onPressed: _busy ? null : _generate,
              ),
            ],
          ),
        ),
        if (_busy)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.18),
              child: Center(
                child: GlassPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 14),
                      Text(
                        '正在生成${widget.mode.label}…',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '请稍候，马上进入作品提交',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReferenceImageCard extends StatelessWidget {
  const _ReferenceImageCard({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: active
              ? AppColors.sage.withValues(alpha: 0.08)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: active
                ? AppColors.sage.withValues(alpha: 0.5)
                : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active
                  ? Icons.check_circle_rounded
                  : Icons.add_photo_alternate_outlined,
              color: active ? AppColors.sage : AppColors.taupe,
              size: 32,
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? '商品示例图已添加' : '点击添加参考图',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  active ? '再次点击可移除' : '支持 JPG / PNG',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
