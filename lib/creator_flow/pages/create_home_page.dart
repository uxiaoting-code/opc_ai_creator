import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../widgets/creator_widgets.dart';
import '../widgets/prototype_widgets.dart';
import '../../widgets/premium/premium_mode_switch.dart';
import '../../widgets/premium/premium_select_sheet.dart';

/// 原型中的「首页 · 创作」。
///
/// 这是用户端最核心的页面：三模式创作入口、进行中任务、创作工具和最近作品。
/// 生成动作会跳转到具体创作页，订单上下文由 Provider 维护。
class CreateHomePage extends StatefulWidget {
  const CreateHomePage({super.key});

  @override
  State<CreateHomePage> createState() => _CreateHomePageState();
}

class _CreateHomePageState extends State<CreateHomePage> {
  final _prompt = TextEditingController();
  CreationMode _mode = CreationMode.image;
  String _model = 'GPT-4o Image';
  String _ratio = '1:1';
  int _count = 4;
  bool _videoHasRef = false;

  static const _models = ['GPT-4o Image', 'DALL·E 3', '通义万相'];
  static const _ratios = ['1:1', '3:4', '4:3', '9:16', '16:9'];
  static const _counts = [1, 2, 4, 6, 9];
  static const _scenes = [
    PrototypeScene(
      icon: Icons.content_cut_rounded,
      label: 'AI 抠图',
      mode: CreationMode.image,
      prompt: '去掉背景，输出透明 PNG',
    ),
    PrototypeScene(
      icon: Icons.shopping_bag_outlined,
      label: '商品宣传图',
      mode: CreationMode.image,
      prompt: '高级商品宣传图，突出产品质感',
    ),
    PrototypeScene(
      icon: Icons.person_pin_circle_outlined,
      label: '数字人播报',
      mode: CreationMode.video,
      prompt: '自然口播，亲和风格',
    ),
    PrototypeScene(
      icon: Icons.image_search_rounded,
      label: '主图换背景',
      mode: CreationMode.image,
      prompt: '替换背景，保持商品主体真实',
    ),
    PrototypeScene(
      icon: Icons.description_outlined,
      label: '详情页长图',
      mode: CreationMode.image,
      prompt: '电商详情页长图，信息清晰',
    ),
    PrototypeScene(
      icon: Icons.record_voice_over_outlined,
      label: '音频配音',
      mode: CreationMode.audio,
      prompt: '商品口播配音，语气自然',
    ),
    PrototypeScene(
      icon: Icons.accessibility_new_rounded,
      label: '模特上身',
      mode: CreationMode.image,
      prompt: '虚拟模特上身展示，保持服装版型真实',
    ),
    PrototypeScene(
      icon: Icons.translate_rounded,
      label: '跨境翻译图',
      mode: CreationMode.image,
      prompt: '跨境电商主图本地化，翻译商品卖点',
    ),
  ];
  static const _workItems = [
    PrototypeWorkItem(CreationMode.image, 11),
    PrototypeWorkItem(CreationMode.video, 17),
    PrototypeWorkItem(CreationMode.image, 23),
    PrototypeWorkItem(CreationMode.image, 29),
  ];

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  int get _cost => switch (_mode) {
    CreationMode.image => _count * 2,
    CreationMode.video => 8,
    CreationMode.audio => 1,
  };

  String get _placeholder => switch (_mode) {
    CreationMode.image => '描述商品画面，如：白色背景，柔光，高级质感…',
    CreationMode.video => '描述视频内容与运镜，如：商品 360° 旋转展示…',
    CreationMode.audio => '输入要生成语音的文案，如：欢迎光临本店…',
  };

  String get _buttonText => switch (_mode) {
    CreationMode.image => '✦  开始生成',
    CreationMode.video => '✦  生成视频',
    CreationMode.audio => '✦  生成音频',
  };

  String get _route => switch (_mode) {
    CreationMode.image => '/create/image',
    CreationMode.video => '/create/video',
    CreationMode.audio => '/create/audio',
  };

  Future<void> _pickModel() async {
    final selected = await showPremiumSelectSheet<String>(
      context: context,
      title: '选择模型',
      subtitle: '由后端 Skill / 模型配置提供',
      options: [
        for (final model in _models)
          PremiumSelectOption(
            value: model,
            title: model,
            description: model == 'GPT-4o Image'
                ? '高画质 · 中文优化 · 推荐'
                : 'AI 创作模型',
            icon: Icons.auto_awesome_rounded,
            highlighted: model == 'GPT-4o Image',
            trailing: model == 'GPT-4o Image' ? '推荐' : null,
          ),
      ],
      selected: _model,
    );
    if (selected != null && mounted) setState(() => _model = selected);
  }

  Future<void> _pickRatio() async {
    final selected = await showPremiumSelectSheet<String>(
      context: context,
      title: '选择比例',
      options: [
        for (final ratio in _ratios)
          PremiumSelectOption(
            value: ratio,
            title: ratio,
            icon: Icons.aspect_ratio_rounded,
          ),
      ],
      selected: _ratio,
    );
    if (selected != null && mounted) setState(() => _ratio = selected);
  }

  Future<void> _pickCount() async {
    final selected = await showPremiumSelectSheet<int>(
      context: context,
      title: '选择数量',
      options: [
        for (final count in _counts)
          PremiumSelectOption(
            value: count,
            title: '$count 张',
            icon: Icons.photo_library_outlined,
          ),
      ],
      selected: _count,
    );
    if (selected != null && mounted) setState(() => _count = selected);
  }

  void _generate() {
    HapticFeedback.selectionClick();
    context.push(_route, extra: _prompt.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final flow = context.watch<CreatorFlowProvider>();
    final order = flow.currentOrder;

    return CreatorScreen(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _HomeHeader(auth: auth),
                const SizedBox(height: 16),
                _CourseBanner(
                  onTap: () => context.go('/course'),
                ),
                const SizedBox(height: 16),
                _QuickEntries(
                  onCourse: () => context.go('/course'),
                  onMarket: () => context.go('/market'),
                  onProfile: () => context.go('/profile'),
                  onWorks: () => context.push('/works'),
                ),
                if (order != null) ...[
                  const SizedBox(height: 16),
                  PrototypeOrderBanner(
                    order: order,
                    onTap: () => context.go('/workbench'),
                  ),
                ],
                const SizedBox(height: 16),
                _CreationHero(
                  mode: _mode,
                  model: _model,
                  ratio: _ratio,
                  count: _count,
                  promptController: _prompt,
                  placeholder: _placeholder,
                  videoHasRef: _videoHasRef,
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  onModelTap: _pickModel,
                  onRatioTap: _pickRatio,
                  onCountTap: _pickCount,
                  onToggleRef: () =>
                      setState(() => _videoHasRef = !_videoHasRef),
                  onGenerate: _generate,
                  buttonText: _buttonText,
                  cost: _cost,
                ),
                const SizedBox(height: 22),
                const CreatorSectionHeader(
                  title: '创作工具',
                  subtitle: '左右滑动查看更多电商场景',
                ),
                const SizedBox(height: 12),
                PrototypeSceneStrip(scenes: _scenes, onTap: _openScene),
                const SizedBox(height: 22),
                CreatorSectionHeader(
                  title: '最近作品',
                  action: TextButton(
                    onPressed: () => context.push('/works'),
                    child: const Text('全部 ›'),
                  ),
                ),
                const SizedBox(height: 12),
                PrototypeWorksGrid(
                  items: _workItems,
                  onTap: () => context.push('/works'),
                ),
              ],
            ),
          ),
          CreatorBottomAction(
            label: _buttonText,
            icon: Icons.auto_awesome_rounded,
            caption: '预计消耗 $_cost 算力 · 当前余额 ${flow.credits.toStringAsFixed(0)}',
            onPressed: flow.credits >= _cost ? _generate : null,
            secondaryLabel: '接一个订单，先按需求创作',
            onSecondary: () => context.go('/market'),
          ),
        ],
      ),
    );
  }

  void _openScene(PrototypeScene scene) {
    final path = switch (scene.mode) {
      CreationMode.image => '/create/image',
      CreationMode.video => '/create/video',
      CreationMode.audio => '/create/audio',
    };
    context.push(path, extra: scene.prompt);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nickname = auth.user?.nickname ?? auth.user?.username ?? '创作者';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('晚上好，来点灵感', style: theme.textTheme.bodySmall),
              const SizedBox(height: 3),
              Text('开始创作', style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
        CreatorTag(
          label: 'Lv.3',
          color: AppColors.sage,
          icon: Icons.workspace_premium_rounded,
        ),
        const SizedBox(width: 8),
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            nickname.isEmpty ? 'K' : nickname.characters.first,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CourseBanner extends StatelessWidget {
  const _CourseBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      onTap: onTap,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.sage.withValues(alpha: 0.1),
      borderColor: AppColors.sage.withValues(alpha: 0.2),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 92,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(AppSpacing.radiusCard),
              ),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 电商创作训练营', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '培训 · 实操 · 考核，解锁专业订单',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.taupe),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _QuickEntries extends StatelessWidget {
  const _QuickEntries({
    required this.onCourse,
    required this.onMarket,
    required this.onProfile,
    required this.onWorks,
  });

  final VoidCallback onCourse;
  final VoidCallback onMarket;
  final VoidCallback onProfile;
  final VoidCallback onWorks;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.school_outlined, '课程中心', onCourse),
      (Icons.storefront_outlined, '接单大厅', onMarket),
      (Icons.image_outlined, '我的作品', onWorks),
      (Icons.account_balance_wallet_outlined, '我的钱包', onProfile),
    ];
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: _QuickEntry(
              icon: item.$1,
              label: item.$2,
              onTap: item.$3,
            ),
          ),
      ],
    );
  }
}

class _QuickEntry extends StatelessWidget {
  const _QuickEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                boxShadow: AppColors.shadowSoft,
              ),
              child: Icon(icon, color: AppColors.sage, size: 22),
            ),
            const SizedBox(height: 7),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CreationHero extends StatelessWidget {
  const _CreationHero({
    required this.mode,
    required this.model,
    required this.ratio,
    required this.count,
    required this.promptController,
    required this.placeholder,
    required this.videoHasRef,
    required this.onModeChanged,
    required this.onModelTap,
    required this.onRatioTap,
    required this.onCountTap,
    required this.onToggleRef,
    required this.onGenerate,
    required this.buttonText,
    required this.cost,
  });

  final CreationMode mode;
  final String model;
  final String ratio;
  final int count;
  final TextEditingController promptController;
  final String placeholder;
  final bool videoHasRef;
  final ValueChanged<CreationMode> onModeChanged;
  final VoidCallback onModelTap;
  final VoidCallback onRatioTap;
  final VoidCallback onCountTap;
  final VoidCallback onToggleRef;
  final VoidCallback onGenerate;
  final String buttonText;
  final int cost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumModeSwitch<CreationMode>(
            options: const [
              PremiumModeOption(
                value: CreationMode.image,
                label: '图片',
                icon: Icons.image_outlined,
              ),
              PremiumModeOption(
                value: CreationMode.video,
                label: '视频',
                icon: Icons.movie_filter_outlined,
              ),
              PremiumModeOption(
                value: CreationMode.audio,
                label: '音频',
                icon: Icons.graphic_eq_rounded,
              ),
            ],
            value: mode,
            onChanged: onModeChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: promptController,
            minLines: mode == CreationMode.audio ? 3 : 2,
            maxLines: 5,
            maxLength: mode == CreationMode.audio ? 500 : 1200,
            decoration: InputDecoration(
              hintText: placeholder,
              counterText: '',
              alignLabelWithHint: true,
            ),
          ),
          if (mode == CreationMode.video) ...[
            const SizedBox(height: 10),
            _VideoRefSlot(hasRef: videoHasRef, onTap: onToggleRef),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PrototypeParamPill(
                label: '模型',
                value: model,
                onTap: onModelTap,
              ),
              if (mode == CreationMode.image) ...[
                PrototypeParamPill(
                  label: '比例',
                  value: ratio,
                  onTap: onRatioTap,
                ),
                PrototypeParamPill(
                  label: '数量',
                  value: '$count 张',
                  onTap: onCountTap,
                ),
              ],
              if (mode == CreationMode.video)
                PrototypeParamPill(
                  label: '时长',
                  value: '5s',
                  onTap: onModelTap,
                ),
              if (mode == CreationMode.audio)
                PrototypeParamPill(
                  label: '音色',
                  value: '温柔女声',
                  onTap: onModelTap,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(buttonText),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '预计消耗 $cost 算力 · $model',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _VideoRefSlot extends StatelessWidget {
  const _VideoRefSlot({required this.hasRef, required this.onTap});

  final bool hasRef;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasRef
              ? AppColors.sage.withValues(alpha: 0.08)
              : AppColors.glass,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: hasRef
                ? AppColors.sage.withValues(alpha: 0.4)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasRef
                  ? Icons.check_circle_rounded
                  : Icons.add_photo_alternate_outlined,
              color: hasRef ? AppColors.sage : AppColors.taupe,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasRef ? '首帧图已添加，点击可移除' : '添加首帧图（可选，用于图生视频）',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

