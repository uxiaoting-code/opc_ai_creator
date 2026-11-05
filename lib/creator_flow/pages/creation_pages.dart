import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/media_utils.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../widgets/premium/premium_select_sheet.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';

class CreateImagePage extends StatelessWidget {
  const CreateImagePage({super.key, this.initialPrompt, this.orderId});

  final String? initialPrompt;
  final int? orderId;

  @override
  Widget build(BuildContext context) {
    return _CreationFormPage(
      mode: CreationMode.image,
      title: '文生图',
      defaultModel: 'GPT-4o Image',
      promptHint: '例如：春季香水瓶，奶油色背景，柔和自然光，高级电商广告质感',
      initialPrompt: initialPrompt ?? '',
      orderId: orderId,
      models: ['GPT-4o Image', 'DALL·E 3', '通义万相'],
      choices: [
        _ChoiceGroup('画面风格', ['高级留白', '自然光', '场景化', '极简']),
        _ChoiceGroup('画面比例', ['1:1', '3:4', '4:3', '9:16']),
        _ChoiceGroup('清晰度', ['标准', '高清', '超清']),
      ],
      allowOptionalReference: true,
    );
  }
}

class CreateVideoPage extends StatelessWidget {
  const CreateVideoPage({super.key, this.initialPrompt, this.orderId});

  final String? initialPrompt;
  final int? orderId;

  @override
  Widget build(BuildContext context) {
    return _CreationFormPage(
      mode: CreationMode.video,
      title: '图生视频',
      defaultModel: '可灵 Kling',
      promptHint: '例如：咖啡机缓慢旋转，蒸汽升起，镜头平稳推进，暖色生活场景',
      initialPrompt: initialPrompt ?? '',
      orderId: orderId,
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
  const CreateAudioPage({super.key, this.initialPrompt, this.orderId});

  final String? initialPrompt;
  final int? orderId;

  @override
  Widget build(BuildContext context) {
    return _CreationFormPage(
      mode: CreationMode.audio,
      title: '生成音频',
      defaultModel: '温柔女声',
      promptHint: '输入需要配音的商品文案，例如：欢迎来到花漾美妆直播间……',
      initialPrompt: initialPrompt ?? '',
      orderId: orderId,
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
    this.initialPrompt = '',
    this.orderId,
    required this.models,
    required this.choices,
    this.showReference = false,
    this.allowOptionalReference = false,
    this.audioMode = false,
  });

  final CreationMode mode;
  final String title;
  final String defaultModel;
  final String promptHint;
  final String initialPrompt;
  final int? orderId;
  final List<String> models;
  final List<_ChoiceGroup> choices;
  final bool showReference;
  final bool allowOptionalReference;
  final bool audioMode;

  @override
  State<_CreationFormPage> createState() => _CreationFormPageState();
}

class _CreationFormPageState extends State<_CreationFormPage> {
  late final TextEditingController _prompt;
  late String _model;
  late final List<String> _selected;
  bool _busy = false;
  bool _pickingReference = false;
  String? _refImageUrl;

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController(text: widget.initialPrompt);
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

  Future<void> _pickModel() async {
    final selected = await showPremiumSelectSheet<String>(
      context: context,
      title: '选择生成模型',
      options: [
        for (final model in widget.models)
          PremiumSelectOption(
            value: model,
            title: model,
            description: model == widget.defaultModel
                ? '推荐 · 由后台模型配置提供'
                : 'AI 创作模型',
            icon: Icons.auto_awesome_rounded,
            highlighted: model == widget.defaultModel,
          ),
      ],
      selected: _model,
    );
    if (selected != null && mounted) setState(() => _model = selected);
  }

  Future<void> _pickChoice(int index) async {
    final group = widget.choices[index];
    final selected = await showPremiumSelectSheet<String>(
      context: context,
      title: group.label,
      options: [
        for (final value in group.values)
          PremiumSelectOption(
            value: value,
            title: value,
            icon: switch (group.label) {
              '画面风格' => Icons.palette_outlined,
              '画面比例' => Icons.aspect_ratio_rounded,
              '镜头运动' => Icons.movie_filter_outlined,
              '视频比例' => Icons.aspect_ratio_rounded,
              '语言' => Icons.language_rounded,
              '语速' => Icons.speed_rounded,
              _ => Icons.tune_rounded,
            },
          ),
      ],
      selected: _selected[index],
    );
    if (selected != null && mounted) {
      setState(() => _selected[index] = selected);
    }
  }

  Future<void> _pickReference() async {
    final materialRepository = context.read<MaterialRepository>();
    final file = await MediaUtils.pickImageFromGallery();
    if (file == null) {
      if (MediaUtils.lastErrorMessage != null) {
        _showError(MediaUtils.lastErrorMessage!);
      }
      return;
    }

    final bytes = await MediaUtils.readBytes(file);
    if (bytes == null) {
      _showError(MediaUtils.lastErrorMessage ?? '读取图片失败');
      return;
    }

    setState(() => _pickingReference = true);
    try {
      final url = await materialRepository.uploadImage(
        bytes: bytes,
        filename: MediaUtils.fileNameOf(file),
      );
      if (!mounted) return;
      setState(() => _refImageUrl = url);
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _pickingReference = false);
    }
  }

  Future<void> _generate() async {
    final prompt = _composedPrompt();
    if (prompt.isEmpty) {
      _showError('请先输入创作描述');
      return;
    }
    if (widget.showReference && _refImageUrl == null) {
      _showError('视频生成需要先上传一张参考图');
      return;
    }

    setState(() => _busy = true);
    try {
      final repository = context.read<TaskRepository>();
      final TaskModel task;
      switch (widget.mode) {
        case CreationMode.image:
          task = await repository.createTextToImage(
            prompt: prompt,
            refImageUrl: _refImageUrl,
            orderId: widget.orderId,
          );
        case CreationMode.video:
          task = await repository.createImageToVideo(
            prompt: prompt,
            refImageUrl: _refImageUrl!,
            orderId: widget.orderId,
          );
        case CreationMode.audio:
          task = await repository.createTextToAudio(
            prompt: prompt,
            voiceCode: _voiceCode,
            language: _languageCode,
            speed: _audioSpeed,
            format: _audioFormat,
            orderId: widget.orderId,
          );
      }
      if (!mounted) return;
      context.push('/result', extra: task);
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _voiceCode => switch (_model) {
    '温柔女声' => 'warm_female',
    '磁性男声' => 'deep_male',
    '活力主播' => 'lively_host',
    '多语言女声' => 'multilingual_female',
    _ => 'warm_female',
  };

  String get _languageCode {
    if (widget.choices.isEmpty) return 'zh-CN';
    return switch (_selected[0]) {
      'English' => 'en-US',
      '日本語' => 'ja-JP',
      _ => 'zh-CN',
    };
  }

  double get _audioSpeed {
    if (widget.choices.length < 2) return 1.0;
    return switch (_selected[1]) {
      '慢速' => 0.75,
      '快速' => 1.25,
      _ => 1.0,
    };
  }

  String get _audioFormat {
    if (widget.choices.length < 3) return 'MP3';
    return _selected[2] == 'WAV' ? 'WAV' : 'MP3';
  }

  /// 把用户选的风格、比例等选项拼进提示词。
  ///
  /// 当前后端 M4 还没有 `options` 字段，所以前端先把选项合并为提示词，
  /// 保证这些选择至少会真实影响生成结果，而不是只停留在界面上。
  String _composedPrompt() {
    final base = _prompt.text.trim();
    if (widget.mode == CreationMode.audio) return base;

    final parts = <String>[base];
    for (var i = 0; i < widget.choices.length; i++) {
      parts.add('${widget.choices[i].label}：${_selected[i]}');
    }
    if (widget.showReference && _refImageUrl != null) {
      parts.add('使用已上传的参考图');
    }
    return parts.join('，');
  }

  void _openMode(CreationMode mode) {
    final path = switch (mode) {
      CreationMode.image => '/create/image',
      CreationMode.video => '/create/video',
      CreationMode.audio => '/create/audio',
    };
    context.go(path, extra: _prompt.text.trim());
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                    if (widget.showReference || widget.allowOptionalReference) ...[
                      const SizedBox(height: 18),
                      FormFieldLabel(
                        widget.showReference ? '参考图' : '参考图（可选）',
                        required: widget.showReference,
                      ),
                      _ReferenceImageCard(
                        active: _refImageUrl != null,
                        busy: _pickingReference,
                        onTap: _pickReference,
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
                    if (widget.audioMode) ...[
                      const SizedBox(height: 18),
                      const FormFieldLabel('选择音色'),
                      _VoiceChips(
                        voices: widget.models,
                        selected: _model,
                        onSelect: (voice) => setState(() => _model = voice),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      const FormFieldLabel('生成模型'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ChoicePill(
                            label: _model,
                            onTap: _pickModel,
                          ),
                        ],
                      ),
                      if (widget.choices.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        FormFieldLabel(widget.choices.first.label),
                        _ChoiceChips(
                          values: widget.choices.first.values,
                          selected: _selected.first,
                          onSelect: (value) =>
                              setState(() => _selected.first = value),
                        ),
                      ],
                      for (
                        var i = 1;
                        i < widget.choices.length;
                        i++
                      ) ...[
                        const SizedBox(height: 18),
                        FormFieldLabel(widget.choices[i].label),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChoicePill(
                              label: _selected[i],
                              onTap: () => _pickChoice(i),
                            ),
                          ],
                        ),
                      ],
                    ],
                    if (widget.audioMode)
                      for (var i = 0; i < widget.choices.length; i++) ...[
                        const SizedBox(height: 18),
                        FormFieldLabel(widget.choices[i].label),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChoicePill(
                              label: _selected[i],
                              onTap: () => _pickChoice(i),
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
              _ModeMiniBar(
                mode: widget.mode,
                onSelect: _openMode,
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

class _ModeMiniBar extends StatelessWidget {
  const _ModeMiniBar({required this.mode, required this.onSelect});

  final CreationMode mode;
  final ValueChanged<CreationMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: [
          for (final item in CreationMode.values)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (item != mode) onSelect(item);
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: item == mode
                        ? AppColors.sageTint
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    item.shortLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: item == mode ? AppColors.sage : AppColors.taupe,
                      fontSize: 12,
                      fontWeight:
                          item == mode ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.sage.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: AppColors.sage.withValues(alpha: 0.34),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.sage,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: AppColors.sage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(value),
            selected: selected == value,
            onSelected: (_) => onSelect(value),
          ),
      ],
    );
  }
}

class _VoiceChips extends StatelessWidget {
  const _VoiceChips({
    required this.voices,
    required this.selected,
    required this.onSelect,
  });

  final List<String> voices;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final voice in voices) ...[
            _VoiceCard(
              voice: voice,
              selected: selected == voice,
              onTap: () => onSelect(voice),
            ),
            if (voice != voices.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({
    required this.voice,
    required this.selected,
    required this.onTap,
  });

  final String voice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageTint : AppColors.glass,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: selected
                ? AppColors.sage.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: selected
                  ? AppColors.sage
                  : AppColors.sage.withValues(alpha: 0.14),
              child: Text(
                voice.characters.first,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.sage,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              voice,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? AppColors.sage : AppColors.taupe,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceImageCard extends StatelessWidget {
  const _ReferenceImageCard({
    required this.active,
    required this.busy,
    required this.onTap,
  });

  final bool active;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
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
        child: busy
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Row(
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
                        active ? '参考图已上传' : '点击上传参考图',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        active ? '可重新上传替换' : '支持 JPG / PNG，最大 10MB',
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
