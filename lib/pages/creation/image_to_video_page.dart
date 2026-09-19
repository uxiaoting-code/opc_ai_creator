import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/media_utils.dart';
import '../../data/models/skill_model.dart';
import '../../data/repositories/material_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/skill_provider.dart';
import '../../widgets/media/media_viewers.dart';
import '../../widgets/scaffold_page.dart';

/// 页面 4：图生视频创作页
///
/// 入口：首页「图生视频」入口 / 首页 Skill 卡片 / Skill 市场。
/// 从卡片进来时路由会带 `?skillId=xxx`，进页面直接预选好那条线路。
///
/// 和文生图页的**唯一结构差异**：这里必须提前拿到一个 `refImageUrl`，
/// 所以提交是两步 —— 先把首帧图传到 `/api/materials/upload` 换回一个 URL，
/// 再拿这个 URL 去 `POST /api/creation/image-to-video`。
///
/// 拆两步而不是一个 multipart 接口，是为了让失败可以分开处理：
/// 图传上去了但任务没建成（算力点不足之类），用户改完提示词重提时
/// 不用重新选图 —— 上传结果缓存在 [_refImageUrl] 里。
///
/// 生成依然是异步的，所以这里不显示结果：提交成功立刻带 taskId 跳任务详情页，
/// 由详情页轮询「排队 → 生成中 → 成功」，成功后用视频播放器展示。
class ImageToVideoPage extends StatefulWidget {
  const ImageToVideoPage({super.key, this.skillId});

  /// 从路由 query 参数带进来的 Skill 线路 ID，为空表示用户还没选线路。
  final String? skillId;

  @override
  State<ImageToVideoPage> createState() => _ImageToVideoPageState();
}

class _ImageToVideoPageState extends State<ImageToVideoPage> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativeController = TextEditingController();

  /// 当前选中的线路 ID。null 表示「自动选择」（后端用默认参数）。
  int? _selectedSkillId;

  /// 提交中：禁用按钮并显示 loading，防止连点创建出多个任务。
  bool _submitting = false;

  /// 提交到哪一步了，用于按钮上的文案（上传图 / 建任务 两段）。
  String _submitStage = '';

  /// 用户选中的首帧图。null 表示还没选。
  XFile? _refImage;

  /// 首帧图的字节流。预览与上传共用，避免重复 readAsBytes。
  Uint8List? _refImageBytes;

  /// 上传成功后拿到的地址。**换图时必须清空**，否则会拿旧图去建新任务。
  String? _refImageUrl;

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
  // 选图
  // ===========================================================================

  Future<void> _pickImage(ImageSource source) async {
    final file = source == ImageSource.camera
        ? await MediaUtils.pickImageFromCamera()
        : await MediaUtils.pickImageFromGallery();

    if (file == null) {
      // null 有两种可能：用户主动取消（不算错误，不该弹提示），
      // 或权限被拒 / 体积超限（MediaUtils 会把原因写进 lastErrorMessage）。
      final reason = MediaUtils.lastErrorMessage;
      if (reason != null) _showMessage(reason);
      return;
    }

    final bytes = await MediaUtils.readBytes(file);
    if (!mounted) return;

    if (bytes == null) {
      _showMessage(MediaUtils.lastErrorMessage ?? '读取图片失败，请重新选择');
      return;
    }

    setState(() {
      _refImage = file;
      _refImageBytes = bytes;
      // 换了图，之前上传拿到的地址就作废了
      _refImageUrl = null;
    });
  }

  void _clearImage() {
    setState(() {
      _refImage = null;
      _refImageBytes = null;
      _refImageUrl = null;
    });
  }

    // 从素材库选择首帧图
    Future<void> _openSelectMaterial() async {
      if (_submitting) return;
      final selectedUrl = await context.push('/select-material');
      if(selectedUrl != null && selectedUrl is String) {
        // 拿到素材返回的图片url，更新到首帧
        setState(() {
          _refImageUrl = selectedUrl;
          // 因为是后端已经存在的素材，不需要本地文件，本地预览需要单独处理
          _refImage = null;
          _refImageBytes = null;
        });
      }
    }


  void _previewImage() {
    final bytes = _refImageBytes;
    if (bytes == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImagePreviewPage(imageBytes: bytes, title: '首帧参考图'),
      ),
    );
  }

  // ===========================================================================
  // 提交
  // ===========================================================================

  Future<void> _submit() async {
    final bytes = _refImageBytes;

    // 首帧图有两种来源，都算「已选」：
    //   1. 本地刚选的图 —— 有字节流，提交前要先上传换 URL；
    //   2. 从素材库选来的 —— 后端已经有这条素材，url 直接可用，不用再传一次。
    //
    // 只判断 bytes 的写法会把第 2 种挡在这里，提示「请先上传首帧参考图」，
    // 而用户明明已经选好了图 —— 这正是素材库那条路走不通的原因。
    final cachedUrl = _refImageUrl;
    if (bytes == null && (cachedUrl == null || cachedUrl.isEmpty)) {
      _showMessage('请先选择首帧参考图');
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showMessage('请先输入运动描述');
      return;
    }

    // 收起键盘，让用户立刻看到 loading
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _submitStage = _refImageUrl == null ? '正在上传参考图…' : '正在提交任务…';
    });

    try {
      // ---- 第一步：上传首帧图，换回一个后端可访问的 URL ----
      final refUrl = await _ensureRefImageUploaded(bytes);
      if (!mounted) return;

      // ---- 第二步：创建任务 ----
      final task = await context.read<TaskRepository>().createImageToVideo(
            skillId: _selectedSkillId,
            prompt: prompt,
            negativePrompt: _negativeController.text.trim(),
            refImageUrl: refUrl,
          );

      if (!mounted) return;

      // 后端在「创建任务」时就扣了算力点（图生视频扣 15 点），
      // 所以这一刻就把全局用户信息刷一遍，首页右上角积分会自动跟着变。
      // 故意不 await：这是顺带更新，不能拖慢跳转到任务详情页。
      unawaited(context.read<AuthProvider>().loadProfile());

      // 与文生图页一致：任务详情是「任务」Tab 分支下的子路由，
      // 跨分支跳转必须用 go，否则底部导航高亮会和内容对不上。
      _showMessage('任务已提交，正在排队');
      context.go(RouteNames.taskDetailOf(task.id));
    } on ApiException catch (e) {
      // 图片格式不支持、体积超限、算力点不足、线路下线……
      // 后端和网络层的错误都已被归一成 ApiException，直接展示中文提示
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('提交失败：$e');
    } finally {
      // 跳转成功时页面已被替换，setState 会报「组件已卸载」
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitStage = '';
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 确保首帧图已经上传，返回可填进 `refImageUrl` 的地址。
  ///
  /// 已经传过就直接复用缓存 —— 这对「图传上去了但建任务失败」的场景很重要：
  /// 用户改完提示词重提时不必重新上传一遍，那一步本来就已经成功了。
  ///
  /// 返回值非空：上传失败会抛 [ApiException]，由调用方的 catch 统一处理。
  ///
  /// [bytes] 可以为 null —— 从素材库选来的首帧图后端已经有地址了，
  /// 不需要上传，直接走上面的缓存分支返回。
  Future<String> _ensureRefImageUploaded(Uint8List? bytes) async {
    final cached = _refImageUrl;
    if (cached != null && cached.isNotEmpty) return cached;

    final source = bytes;
    if (source == null) {
      // 既没有本地字节、也没有已上传地址。正常流程进不来，
      // 走到这里说明状态被清掉了，给一句能看懂的提示而不是空指针。
      throw const ApiException(message: '没有可用的首帧图，请重新选择');
    }

    // context.read 必须在 await 之前调用
    final repository = context.read<MaterialRepository>();
    final url = await repository.uploadImage(
      bytes: source,
      // Web 上 XFile.name 才可靠（path 是 blob URL），取不到再退回一个默认名
      filename: MediaUtils.fileNameOf(_refImage!, fallback: 'ref.jpg'),
    );

    if (mounted) {
      setState(() {
        _refImageUrl = url;
        // 图传完了，按钮文案切到第二段，用户能感知到「还在跑，不是卡住了」
        _submitStage = '正在提交任务…';
      });
    }
    return url;
  }

  // ===========================================================================
  // 构建
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final skillProvider = context.watch<SkillProvider>();
    // 只用图生视频线路 —— 文生图线路出现在这里会让用户选错
    final skills = skillProvider.imageToVideoSkills;
    final selectedSkill = _resolveSelected(skills);

    return Scaffold(
      appBar: AppBar(title: const Text('图生视频创作')),
      body: SafeArea(
        child: MobileScaffoldBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(),
              const SizedBox(height: AppSpacing.xl),
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
  // 1. 首帧参考图（本页与文生图页最大的差异：这一项是必填的）
  // ---------------------------------------------------------------------------

  Widget _buildImageSection() {
    final theme = Theme.of(context);
    final bytes = _refImageBytes;
    final remoteUrl = _refImageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(
          icon: Icons.image_outlined,
          text: '首帧参考图',
          hint: '必填，视频会以这张图为起点运动',
        ),
        const SizedBox(height: AppSpacing.sm),

        // 三种状态，按「本地字节 > 远端地址 > 还没选」的优先级判断。
        //
        // 正常情况下两种来源是互斥的（选本地图会清空 url，选素材会清空 bytes），
        // 但改成字节优先是对的：手上真有字节流时，它一定是最准确的那张图。
        if (bytes != null)
          _buildImagePreview(theme, bytes)
        else if (remoteUrl != null && remoteUrl.isNotEmpty)
          _buildRemoteImagePreview(theme, remoteUrl)
        else
          _buildEmptyPicker(theme),
      ],
    );
  }

  /// 网络素材图片预览（从素材库选来的图）。
  ///
  /// ⚠️ **显示必须拼绝对地址**：后端返回的是 `/upload/xxx.png` 这种相对路径，
  /// 直接交给 `Image.network` 会按**当前页面域名**去解析 —— Web 上就是
  /// Flutter 的调试端口，结果 404 破图（Android 上更是直接失败）。
  ///
  /// 但 [_refImageUrl] 本身仍然保存那个相对路径：提交时要原样传给后端，
  /// 不能把拼好的绝对地址存进去，否则数据库里会写进
  /// `http://localhost:8080/...` 这种本机地址，换台机器就失效。
  Widget _buildRemoteImagePreview(ThemeData theme, String url) {
    final displayUrl = AppConfig.resolveAssetUrl(url);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          // 点图放大看细节，确认选对了再提交
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ImagePreviewPage(
                imageUrl: displayUrl,
                title: '首帧参考图',
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              // AppNetworkImage 内部就是 Image.network，
              // 另外补了加载中占位与加载失败兜底，避免破图
              child: AppNetworkImage(url: displayUrl, fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '已选素材图片（来自素材库）',
          style: theme.textTheme.bodySmall,
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton.icon(
              onPressed: _submitting ? null : _openSelectMaterial,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('重新选择'),
            ),
            TextButton.icon(
              onPressed: _submitting ? null : _clearImage,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('移除'),
            ),
          ],
        ),
      ],
    );
  }


  /// 还没选图：给相册 / 拍照两个入口。
  Widget _buildEmptyPicker(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 34,
            color: AppColors.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('上传一张图片作为首帧', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '支持 jpg / png / webp，10MB 以内',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          // 用 Wrap 而不是 Row：
          // Row 在主轴方向会给子组件**无限宽**的约束，而 OutlinedButton.icon
          // 内部的尺寸计算（ConstrainedBox + Flexible 标签）拿到无限宽约束时
          // 会直接抛 "BoxConstraints forces an infinite width"。
          // Wrap 只给子组件松约束，永远不会强制无限宽；顺带还有个好处 ——
          // 窄屏上两个按钮会自动折到第二行，不会横向溢出。
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _submitting
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('从相册选择'),
              ),
              OutlinedButton.icon(
                onPressed:
                    _submitting ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('拍照'),
              ),
              // ==========在这里插入新按钮==========
                             OutlinedButton.icon(
                               onPressed: _submitting ? null : _openSelectMaterial,
                               icon: const Icon(Icons.collections_outlined, size: 18),
                               label: const Text('从素材库选择'),
                             ),
            ],
          ),
        ],
      ),
    );
  }

  /// 已选图：预览 + 重选 / 移除，并标出上传状态。
  Widget _buildImagePreview(ThemeData theme, Uint8List bytes) {
    final uploaded = _refImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          // 点图放大看细节，确认选对了再提交
          onTap: _previewImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Stack(
              children: [
                // 用 BoxFit.contain + 固定高度：不裁掉画面任何部分，
                // 用户看到的就是将要送去生成的那张图的完整内容
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
                // 上传完成的角标：让用户明确知道「这张图后端已经收到了」
                if (uploaded)
                  Positioned(
                    left: AppSpacing.sm,
                    top: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccess.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_done_rounded,
                              size: 13, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            '已上传',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '已选图片 · ${MediaUtils.formatFileSize(bytes.length)}',
          style: theme.textTheme.bodySmall,
        ),
        // 与上方选图入口同理：按钮不能直接放进 Row（会拿到无限宽约束而报错），
        // 统一改用 Wrap，窄屏时自动折行。
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton.icon(
              onPressed: _submitting
                  ? null
                  : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('重新选择'),
            ),
            TextButton.icon(
              onPressed: _submitting ? null : _clearImage,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('移除'),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. 线路下拉选择
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
          text: '运镜线路',
          hint: '线路决定镜头运动方式与推理参数',
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
            Text('正在加载运镜线路…'),
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

  /// 线路下拉框。与文生图页同一套写法（裸 DropdownButton，不用 FormField）。
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
  // 3. 运动描述（正向提示词）
  // ---------------------------------------------------------------------------

  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(
          icon: Icons.auto_awesome,
          text: '运动描述',
          hint: '描述镜头怎么动、画面里发生什么',
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _promptController,
          enabled: !_submitting,
          maxLines: 5,
          minLines: 3,
          // 与后端 CreationRequest 的 @Size(max = 2000) 对齐，
          // 前端先拦一道，用户体验好过提交后收 400
          maxLength: 2000,
          textInputAction: TextInputAction.newline,
          decoration: _inputDecoration(
            hintText: '例如：镜头缓慢推进，人物头发随风飘动，背景霓虹灯闪烁',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. 反向提示词
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
            hintText: '例如：画面抖动、人物变形、闪烁、低分辨率',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. 生成按钮
  // ---------------------------------------------------------------------------

  Widget _buildSubmitButton() {
    final theme = Theme.of(context);

    // 提交中整体压暗：按钮本体是透明的（为了透出渐变），
    // FilledButton 的 disabled 配色管不到这层渐变，所以用 Opacity 统一处理。
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
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: _submitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // 两段式提交，文案要跟着走，否则用户会以为卡住了
                      Text(_submitStage.isEmpty ? '正在提交…' : _submitStage),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.movie_creation_outlined, size: 20),
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
            '提交后任务进入排队，页面会自动跳到任务详情页。'
            '视频生成比图片慢，完成后可直接在详情页播放。',
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
// 内部小组件（与文生图页保持同一套视觉语言）
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

/// 选中线路的参数预览。让「多线路」这件事在界面上可见。
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
