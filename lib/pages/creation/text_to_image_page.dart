import 'dart:async';

import 'package:flutter/material.dart';
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
import '../../widgets/scaffold_page.dart';

/// 页面 3：文生图创作页
///
/// 入口：首页「文生图」入口 / 首页 Skill 卡片 / Skill 市场。
/// 从卡片进来时路由会带 `?skillId=xxx`，进页面直接预选好那条线路。
///
/// 页面只做两件事：**选线路 + 写提示词**，然后把任务交给后端 Harness。
/// 生成是异步的，所以这里不显示结果 —— 提交成功立刻带着 taskId 跳任务详情页，
/// 由详情页轮询「排队 → 生成中 → 成功」的完整状态流转。
///
/// 线路列表复用 [SkillProvider]，不单独发请求：
/// 首页已经加载过一份，两个页面看到的是同一份缓存。
class TextToImagePage extends StatefulWidget {
  const TextToImagePage({super.key, this.skillId});

  /// 从路由 query 参数带进来的 Skill 线路 ID，为空表示用户还没选线路。
  final String? skillId;

  @override
  State<TextToImagePage> createState() => _TextToImagePageState();
}

class _TextToImagePageState extends State<TextToImagePage> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativeController = TextEditingController();

  /// 当前选中的线路 ID。null 表示「自动选择」（后端用默认参数）。
  int? _selectedSkillId;

  /// 提交中：禁用按钮并显示 loading，防止连点创建出多个任务。
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    // 路由参数是字符串，转不成数字就当没带（而不是崩掉）
    _selectedSkillId = int.tryParse(widget.skillId ?? '');

    // 放到首帧之后再触发加载：Provider 的 load() 内部会 notifyListeners()，
    // 在 initState 里同步触发会在 build 期间标记依赖组件为脏，直接报错。
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
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showMessage('请先输入提示词');
      return;
    }

    // 收起键盘，让用户立刻看到 loading
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final task = await context.read<TaskRepository>().createTextToImage(
            skillId: _selectedSkillId,
            prompt: prompt,
            negativePrompt: _negativeController.text.trim(),
          );

      if (!mounted) return;

      // 后端是在「创建任务」时就扣算力点的（HarnessService.createTask），
      // 所以提交成功的这一刻就把全局用户信息刷一遍：AuthProvider 是全局
      // ChangeNotifier，首页 watch 着它，右上角积分会自动跟着变，
      // 不需要手动刷新浏览器。
      // 故意不 await：这是顺带更新，不能拖慢跳转到任务详情页。
      unawaited(context.read<AuthProvider>().loadProfile());

      // 任务详情页是「任务」Tab 分支下的子路由，跨分支跳转必须用 go：
      // go 会把任务分支的页面栈设成 [任务列表, 任务详情]，
      // 用户从详情返回就落在任务列表，底部导航也跟着切到「任务」。
      // 用 push 会把详情压进首页分支的栈里，导致导航高亮与内容对不上。
      _showMessage('任务已提交，正在排队');
      context.go(RouteNames.taskDetailOf(task.id));
    } on ApiException catch (e) {
      // 网络不通、算力点不足、线路下线…… 后端和网络层的错误
      // 都已经被归一成 ApiException，这里直接展示中文提示即可
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('提交失败：$e');
    } finally {
      // 跳转成功时页面已经被替换，setState 会报"组件已卸载"
      if (mounted) setState(() => _submitting = false);
    }
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
    // 只用文生图线路 —— 图生视频线路出现在这里会让用户选错
    final skills = skillProvider.textToImageSkills;
    final selectedSkill = _resolveSelected(skills);

    return Scaffold(
      appBar: AppBar(title: const Text('文生图创作')),
      body: SafeArea(
        child: MobileScaffoldBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSkillSection(skillProvider, skills, selectedSkill),
              const SizedBox(height: AppSpacing.xl),
              _buildPromptSection(),
              const SizedBox(height: AppSpacing.xl),
              _buildNegativeSection(),
              const SizedBox(height: AppSpacing.xl),
              _buildSubmitButton(),
              const SizedBox(height: AppSpacing.md),
              _buildHint(),
            ],
          ),
        ),
      ),
    );
  }

  /// 取当前生效的线路。
  ///
  /// 必须校验「选中的 ID 真的在候选列表里」：
  /// 从路由带进来的 skillId 可能已被运营下线，或者用户手改了地址栏，
  /// 直接把它塞给 DropdownButton 会触发断言崩溃。
  SkillModel? _resolveSelected(List<SkillModel> skills) {
    if (_selectedSkillId == null) return null;
    for (final skill in skills) {
      if (skill.id == _selectedSkillId) return skill;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 1. 线路下拉选择
  // ---------------------------------------------------------------------------

  Widget _buildSkillSection(
    SkillProvider provider,
    List<SkillModel> skills,
    SkillModel? selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(
          icon: Icons.dashboard_customize_rounded,
          text: '模型线路',
          hint: '线路决定出图风格与推理参数',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (skills.isEmpty)
          _buildSkillPlaceholder(provider)
        else
          _buildDropdown(skills),
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.md),
          _SkillPreview(skill: selected),
        ],
      ],
    );
  }

  /// 线路还没加载出来（或加载失败）时的占位，避免下拉框空着让人以为坏了。
  Widget _buildSkillPlaceholder(SkillProvider provider) {
    final theme = Theme.of(context);
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Text('正在加载创作线路…'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.statusFailed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.statusFailed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: AppColors.statusFailed),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              provider.error ?? '暂无可用线路，请先在后台配置 Skill',
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () => provider.load(force: true),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 线路下拉框。
  ///
  /// 用 [DropdownButton] 而不是 DropdownButtonFormField：
  /// 后者的 `value` 参数在近几个 Flutter 版本里正在往 `initialValue` 迁移，
  /// 用裸的 DropdownButton 没有这个 API 变动风险，也更好控制样式。
  Widget _buildDropdown(List<SkillModel> skills) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerTheme.color ?? AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: _resolveSelected(skills)?.id,
          hint: Text('自动选择（使用默认参数）', style: theme.textTheme.bodyMedium),
          icon: const Icon(Icons.expand_more_rounded),
          // 单条高度要够手指点，否则手机上容易点错
          itemHeight: AppSpacing.touchTargetMin,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onChanged: _submitting
              ? null
              : (value) => setState(() => _selectedSkillId = value),
          items: [
            for (final skill in skills)
              DropdownMenuItem<int?>(
                value: skill.id,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        skill.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (skill.modelName != null)
                      Text(
                        skill.modelName!,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. 正向提示词
  // ---------------------------------------------------------------------------

  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(
          icon: Icons.auto_awesome,
          text: '提示词',
          hint: '描述你想要的画面，越具体越好',
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _promptController,
          enabled: !_submitting,
          maxLines: 6,
          minLines: 4,
          // 与后端 CreationRequest 的 @Size(max = 2000) 对齐，
          // 前端先拦一道，用户体验好过提交后收 400
          maxLength: 2000,
          textInputAction: TextInputAction.newline,
          decoration: _inputDecoration(
            hintText: '例如：雨夜霓虹街道，赛博朋克风格，湿滑路面倒影，电影感光效',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. 反向提示词
  // ---------------------------------------------------------------------------

  Widget _buildNegativeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(
          icon: Icons.block_outlined,
          text: '反向提示词',
          hint: '不想出现的内容，留空则用线路自带的',
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _negativeController,
          enabled: !_submitting,
          maxLines: 3,
          minLines: 2,
          // 与后端 @Size(max = 1000) 对齐
          maxLength: 1000,
          textInputAction: TextInputAction.newline,
          decoration: _inputDecoration(
            hintText: '例如：低分辨率、多余手指、水印、文字',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. 生成按钮
  // ---------------------------------------------------------------------------

  Widget _buildSubmitButton() {
    final theme = Theme.of(context);

    // 提交中整体压暗：按钮本体是透明的（为了透出渐变），
    // FilledButton 的 disabled 配色管不到这层渐变，所以用 Opacity 统一处理，
    // 否则 loading 时按钮看起来还是"可以点"的。
    return Opacity(
      opacity: _submitting ? 0.65 : 1,
      child: SizedBox(
        height: AppSpacing.buttonHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              // 让渐变透出来：按钮本体不填色
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '开始生成',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '提交后任务进入排队，页面会自动跳到任务详情页，实时显示生成进度。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hintText,
      hintStyle: theme.textTheme.bodySmall,
      filled: true,
      fillColor: theme.cardTheme.color,
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.all(AppSpacing.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: theme.dividerTheme.color ?? AppColors.lightBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: theme.dividerTheme.color ?? AppColors.lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }
}

// =============================================================================
// 内部小组件
// =============================================================================

/// 表单字段的标题行：图标 + 标题 + 一句说明。
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.icon,
    required this.text,
    required this.hint,
  });

  final IconData icon;
  final String text;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: theme.textTheme.titleSmall),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            hint,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 选中线路的参数预览。
///
/// 让「多线路」这件事在界面上可见：同一句提示词走不同线路，
/// 前缀、步数、尺寸都不一样，这里把差异摊开给用户看。
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
        // 用品牌色的淡化底而不是灰底，和整体视觉语言一致
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (skill.description != null)
            Text(skill.description!, style: theme.textTheme.bodySmall),
          if (params.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final param in params)
                  Text(
                    param,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
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
