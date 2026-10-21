import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/skill_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/skill_provider.dart';

/// 页面 3：文生图创作页
///
/// 按原型重排的“创作台”：
/// - 顶部图片 / 视频模式切换
/// - 玻璃提示词卡 + 灵感示例
/// - 风格芯片（会真正拼进提示词）
/// - 比例 / 清晰度参数弹层
/// - 线路选择 + 当前线路参数预览
/// - 底部固定生成栏
class TextToImagePage extends StatefulWidget {
  const TextToImagePage({super.key, this.skillId, this.prompt});

  final String? skillId;
  final String? prompt;

  @override
  State<TextToImagePage> createState() => _TextToImagePageState();
}

class _TextToImagePageState extends State<TextToImagePage> {
  static const int _cost = 10;
  static const List<String> _styles = [
    '纯白背景',
    '场景图',
    '模特上身',
    '3D质感',
    '国潮',
    '极简',
  ];
  static const List<String> _ratios = ['1:1', '3:4', '4:3', '9:16', '16:9'];
  static const List<String> _qualities = ['标清', '高清', '超清', '4K'];
  static const List<String> _ideas = [
    '雨夜霓虹街道，湿润路面倒影，电影感光效',
    '白色背景商品主图，柔和棚拍光，高级质感',
    '国风水墨山水，留白构图，淡雅配色',
    '未来感金属质感产品，深色背景，轮廓光',
  ];

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativeController = TextEditingController();

  int? _selectedSkillId;
  bool _submitting = false;
  bool _showAdvanced = false;

  String _selectedStyle = _styles.first;
  String _selectedRatio = '1:1';
  String _selectedQuality = '高清';
  int _ideaIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedSkillId = int.tryParse(widget.skillId ?? '');
    _promptController.text = widget.prompt ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SkillProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativeController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 提交
  // ===========================================================================

  Future<void> _submit() async {
    final rawPrompt = _promptController.text.trim();
    if (rawPrompt.isEmpty) {
      _showMessage('先描述一下你想生成什么');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final task = await context.read<TaskRepository>().createTextToImage(
        skillId: _selectedSkillId,
        prompt: _composePrompt(rawPrompt),
        negativePrompt: _negativeController.text.trim().isEmpty
            ? null
            : _negativeController.text.trim(),
      );

      if (!mounted) return;
      unawaited(context.read<AuthProvider>().loadProfile());
      _showMessage('任务已提交，正在排队');
      context.go(RouteNames.taskDetailOf(task.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('提交失败：$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _composePrompt(String base) {
    final parts = <String>[base];
    final style = _styleModifier;
    if (style.isNotEmpty) parts.add(style);
    parts.add('aspect ratio $_selectedRatio');
    parts.add(_qualityModifier);
    final text = parts.join(', ');
    // 后端 prompt 上限 2000，风格/比例是追加项，别把总长度顶爆。
    return text.length <= 2000 ? text : text.substring(0, 2000);
  }

  String get _styleModifier {
    return switch (_selectedStyle) {
      '纯白背景' => 'pure white background, clean studio lighting',
      '场景图' => 'lifestyle scene background, natural lighting',
      '模特上身' => 'worn by a model, fashion photography',
      '3D质感' => '3D render, glossy material, soft shadows',
      '国潮' => 'Chinese guochao style, modern oriental aesthetic',
      '极简' => 'minimalist composition, lots of negative space',
      _ => '',
    };
  }

  String get _qualityModifier {
    return switch (_selectedQuality) {
      '标清' => 'standard quality',
      '高清' => 'high quality, detailed',
      '超清' => 'ultra detailed, sharp focus',
      '4K' => '4K resolution, highly detailed',
      _ => 'high quality, detailed',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ===========================================================================
  // 构建
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final skillProvider = context.watch<SkillProvider>();
    final auth = context.watch<AuthProvider>();
    final skills = skillProvider.textToImageSkills;
    final selected = _resolveSelected(skills);
    final credits = auth.user?.credits;
    final enough = credits == null || credits >= _cost;

    return Scaffold(
      appBar: AppBar(title: const Text('文生图创作')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildModeSwitch(),
                    const SizedBox(height: AppSpacing.md),
                    _buildPromptCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStyleSection(),
                    const SizedBox(height: AppSpacing.md),
                    _buildParamRow(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSkillPreview(skills, selected),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAdvancedSection(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(skills, selected, credits, enough),
          ],
        ),
      ),
    );
  }

  SkillModel? _resolveSelected(List<SkillModel> skills) {
    if (_selectedSkillId == null) return null;
    for (final skill in skills) {
      if (skill.id == _selectedSkillId) return skill;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 模式切换：图片 / 视频
  // ---------------------------------------------------------------------------

  Widget _buildModeSwitch() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.6)
            : AppColors.sageTint.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        children: [
          _modePill(
            theme,
            isDark,
            active: true,
            icon: CupertinoIcons.photo,
            label: '图片',
          ),
          _modePill(
            theme,
            isDark,
            active: false,
            icon: CupertinoIcons.videocam,
            label: '视频',
            onTap: _switchToVideo,
          ),
        ],
      ),
    );
  }

  Widget _modePill(
    ThemeData theme,
    bool isDark, {
    required bool active,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? (isDark ? AppColors.darkSurface : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        boxShadow: active ? AppColors.shadowSoft : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: active ? AppColors.sage : AppColors.taupe,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: active ? AppColors.charcoal : AppColors.taupe,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return Expanded(
      child: onTap == null
          ? child
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: child,
            ),
    );
  }

  void _switchToVideo() {
    final query = <String, String>{};
    final prompt = _promptController.text.trim();
    if (prompt.isNotEmpty) query['prompt'] = prompt;
    if (_selectedSkillId != null) {
      query['skillId'] = '$_selectedSkillId';
    }
    HapticFeedback.selectionClick();
    context.pushReplacement(
      Uri(
        path: RouteNames.imageToVideoPath,
        queryParameters: query.isEmpty ? null : query,
      ).toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // 提示词卡
  // ---------------------------------------------------------------------------

  Widget _buildPromptCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.darkBorder
        : Colors.white.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.82)
            : AppColors.glass,
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        border: Border.all(color: borderColor),
        boxShadow: AppColors.shadowLift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                size: 18,
                color: AppColors.sage,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('描述画面', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _promptController,
              enabled: !_submitting,
              minLines: 4,
              maxLines: 6,
              maxLength: 2000,
              textInputAction: TextInputAction.newline,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '描述商品画面，如：白色背景，柔光，高级质感…',
                hintStyle: theme.textTheme.bodySmall,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _quickAction(
                icon: CupertinoIcons.lightbulb,
                label: '灵感示例',
                onTap: _fillIdea,
              ),
              const SizedBox(width: AppSpacing.md),
              _quickAction(
                icon: CupertinoIcons.arrow_counterclockwise,
                label: '清空',
                onTap: _clearPrompt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.sage),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.sage,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fillIdea() {
    HapticFeedback.selectionClick();
    final idea = _ideas[_ideaIndex % _ideas.length];
    _ideaIndex++;
    _promptController.text = idea;
    _promptController.selection = TextSelection.collapsed(offset: idea.length);
    setState(() {});
  }

  void _clearPrompt() {
    HapticFeedback.selectionClick();
    _promptController.clear();
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // 风格芯片
  // ---------------------------------------------------------------------------

  Widget _buildStyleSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('风格', style: theme.textTheme.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('会追加到提示词里', style: theme.textTheme.labelSmall),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _styles.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final style = _styles[index];
              return _styleChip(style, style == _selectedStyle);
            },
          ),
        ),
      ],
    );
  }

  Widget _styleChip(String style, bool selected) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedStyle = style);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sageTint
              : (isDark ? AppColors.darkSurface : AppColors.glass),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected
                ? AppColors.sage.withValues(alpha: 0.45)
                : (isDark
                      ? AppColors.darkBorder
                      : Colors.white.withValues(alpha: 0.75)),
          ),
        ),
        child: Text(
          style,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 12.5,
            color: selected ? AppColors.sage : AppColors.taupe,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 参数胶囊
  // ---------------------------------------------------------------------------

  Widget _buildParamRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _paramPill(
                icon: Icons.aspect_ratio_rounded,
                label: '比例',
                value: _selectedRatio,
                onTap: () => _pickOption(
                  title: '选择比例',
                  options: _ratios,
                  current: _selectedRatio,
                  onSelected: (value) => _selectedRatio = value,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _paramPill(
                icon: Icons.crop_original_rounded,
                label: '数量',
                value: '1 张',
              ),
              const SizedBox(width: AppSpacing.sm),
              _paramPill(
                icon: Icons.hd_rounded,
                label: '清晰度',
                value: _selectedQuality,
                onTap: () => _pickOption(
                  title: '选择清晰度',
                  options: _qualities,
                  current: _selectedQuality,
                  onSelected: (value) => _selectedQuality = value,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '当前接口每次生成 1 张；比例/清晰度会写进提示词。',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _paramPill({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final child = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.white.withValues(alpha: 0.9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.sage),
          const SizedBox(width: 5),
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: AppColors.taupe,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: child,
    );
  }

  Future<void> _pickOption({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _OptionSheet(title: title, options: options, current: current),
    );
    if (result == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() => onSelected(result));
  }

  // ---------------------------------------------------------------------------
  // 线路预览
  // ---------------------------------------------------------------------------

  Widget _buildSkillPreview(List<SkillModel> skills, SkillModel? selected) {
    if (selected != null) return _SkillPreview(skill: selected);

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.slider_horizontal_3,
            size: 18,
            color: AppColors.sage,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              skills.isEmpty ? '线路加载中…' : '未选择线路，将使用默认参数',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 高级设置
  // ---------------------------------------------------------------------------

  Widget _buildAdvancedSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.82)
            : AppColors.glass,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.white.withValues(alpha: 0.72),
        ),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showAdvanced = !_showAdvanced);
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.slider_horizontal_3,
                    size: 18,
                    color: AppColors.sage,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('高级设置', style: theme.textTheme.titleSmall),
                  ),
                  Text('反向提示词', style: theme.textTheme.labelSmall),
                  const SizedBox(width: 4),
                  Icon(
                    _showAdvanced
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 14,
                    color: AppColors.taupe,
                  ),
                ],
              ),
            ),
          ),
          if (_showAdvanced)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _negativeController,
                enabled: !_submitting,
                minLines: 2,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: '不想出现的内容，例如：低分辨率、水印、多余手指',
                  hintStyle: theme.textTheme.bodySmall,
                  counterText: '',
                  fillColor: isDark
                      ? AppColors.darkBackground.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 底部固定生成栏
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(
    List<SkillModel> skills,
    SkillModel? selected,
    int? credits,
    bool enough,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final skillName = selected?.name ?? '自动线路';

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.94)
            : AppColors.glassStrong,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        boxShadow: AppColors.shadowSoft,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            10,
            AppSpacing.pagePadding,
            12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  PopupMenuButton<int>(
                    onSelected: (value) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedSkillId = value < 0 ? null : value;
                      });
                    },
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem<int>(value: -1, child: Text('自动线路')),
                      for (final skill in skills)
                        PopupMenuItem<int>(
                          value: skill.id,
                          child: Text(
                            skill.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.slider_horizontal_3,
                            size: 14,
                            color: AppColors.sage,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              skillName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.chevron_down,
                            size: 12,
                            color: AppColors.taupe,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text('预计消耗 $_cost 算力', style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: enough
                        ? AppColors.primaryGradient
                        : const LinearGradient(
                            colors: [Color(0xFFBDB5AA), Color(0xFFA79E92)],
                          ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    boxShadow: enough ? AppColors.shadowButton : null,
                  ),
                  child: FilledButton(
                    onPressed: _submitting || !enough ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                    child: _submitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Text('正在提交任务…'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.sparkles, size: 18),
                              SizedBox(width: AppSpacing.sm),
                              Text('开始生成'),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                enough
                    ? '提交后自动跳到任务详情，排队进度实时刷新'
                    : '算力不足（当前 ${credits ?? '—'}），先去个人中心看看',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: enough ? AppColors.taupe : AppColors.statusFailed,
                  fontWeight: enough ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 内部组件
// =============================================================================

class _SkillPreview extends StatelessWidget {
  const _SkillPreview({required this.skill});

  final SkillModel skill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final params = <String>[
      if (skill.modelName != null) skill.modelName!,
      if (skill.width != null && skill.height != null)
        '${skill.width}×${skill.height}',
      if (skill.steps != null) '${skill.steps} 步',
      if (skill.cfgScale != null) 'CFG ${skill.cfgScale}',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.slider_horizontal_3,
                size: 16,
                color: AppColors.sage,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '当前线路 · ${skill.name}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          if (skill.description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(skill.description!, style: theme.textTheme.bodySmall),
          ],
          if (params.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final param in params)
                  Text(
                    param,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.sage,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
          if (skill.promptPrefix != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '自动前缀：${skill.promptPrefix}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionSheet extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.current,
  });

  final String title;
  final List<String> options;
  final String current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero),
        ),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.white.withValues(alpha: 0.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.taupe.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final option in options)
              InkWell(
                onTap: () => Navigator.of(context).pop(option),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(option, style: theme.textTheme.bodyMedium),
                      ),
                      if (option == current)
                        const Icon(
                          CupertinoIcons.checkmark,
                          size: 18,
                          color: AppColors.sage,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
