import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/skill_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/skill_provider.dart';
import '../../providers/work_provider.dart';
import '../../widgets/creation/skill_selector.dart';
import '../creator_flow_provider.dart';
import '../models/creator_models.dart';
import '../models/creator_order.dart';
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
  String _audioVoice = '温柔女声';
  int? _imageSkillId;
  int? _videoSkillId;
  String _ratio = '1:1';
  int _count = 4;
  bool _videoHasRef = false;
  bool _worksRequested = false;
  bool _skillsRequested = false;

  static const _audioVoices = ['温柔女声', '磁性男声', '活力主播', '多语言女声'];
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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_worksRequested) {
      _worksRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<WorkProvider>().loadIfNeeded();
      });
    }
    if (!_skillsRequested) {
      _skillsRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<SkillProvider>().loadIfNeeded();
      });
    }
  }

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

  List<SkillModel> _skillsForMode(SkillProvider provider) {
    return switch (_mode) {
      CreationMode.image => provider.textToImageSkills,
      CreationMode.video => provider.imageToVideoSkills,
      CreationMode.audio => const [],
    };
  }

  SkillModel? _selectedSkill(SkillProvider provider) {
    final skills = _skillsForMode(provider);
    if (skills.isEmpty) return null;
    final selectedId = _mode == CreationMode.image
        ? _imageSkillId
        : _videoSkillId;
    for (final skill in skills) {
      if (skill.id == selectedId) return skill;
    }
    return skills.first;
  }

  void _selectSkill(int id) {
    setState(() {
      if (_mode == CreationMode.image) {
        _imageSkillId = id;
      } else {
        _videoSkillId = id;
      }
    });
  }

  Future<void> _pickModel(SkillProvider skillProvider) async {
    if (_mode == CreationMode.audio) {
      final selected = await showPremiumSelectSheet<String>(
        context: context,
        title: '选择音色',
        options: [
          for (final voice in _audioVoices)
            PremiumSelectOption(
              value: voice,
              title: voice,
              icon: Icons.record_voice_over_outlined,
              highlighted: voice == _audioVoice,
            ),
        ],
        selected: _audioVoice,
      );
      if (selected != null && mounted) {
        setState(() => _audioVoice = selected);
      }
      return;
    }

    final skills = _skillsForMode(skillProvider);
    if (skillProvider.isLoading && skills.isEmpty) {
      _showMessage('创作线路正在加载，请稍后再试');
      return;
    }
    if (skills.isEmpty) {
      _showMessage('暂无可用创作线路，请刷新后重试');
      return;
    }
    final selected = await showPremiumSelectSheet<SkillModel>(
      context: context,
      title: '选择创作线路',
      subtitle: '来自后台 Skill 配置',
      options: [
        for (final skill in skills)
          PremiumSelectOption(
            value: skill,
            title: skill.name,
            description: [
              if (skill.scene?.isNotEmpty == true) skill.scene!,
              if (skill.modelName?.isNotEmpty == true) skill.modelName!,
            ].join(' · '),
            icon: Icons.route_rounded,
            highlighted: skill.id == _selectedSkill(skillProvider)?.id,
          ),
      ],
      selected: _selectedSkill(skillProvider),
    );
    if (selected != null && mounted) _selectSkill(selected.id);
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

  void _generate(SkillProvider skillProvider) {
    HapticFeedback.selectionClick();
    final skill = _mode == CreationMode.audio
        ? null
        : _selectedSkill(skillProvider);
    if (_mode != CreationMode.audio && skill == null) {
      _showMessage('暂无可用创作线路，请刷新后重试');
      return;
    }
    final currentOrderId = context.read<CreatorFlowProvider>().currentOrder?.id;
    final orderId = currentOrderId?.startsWith('api-') == true
        ? int.tryParse(currentOrderId!.substring(4))
        : null;
    context.push(
      _route,
      extra: CreatorCreationArgs(
        prompt: _prompt.text.trim(),
        orderId: orderId,
        skillId: skill?.id,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final flow = context.watch<CreatorFlowProvider>();
    final skillProvider = context.watch<SkillProvider>();
    final worksProvider = context.watch<WorkProvider>();
    final recentWorks = worksProvider.recentWorks.take(4).toList();
    final order = flow.currentOrder;
    final work = flow.workContext;
    final selectedSkill = _selectedSkill(skillProvider);
    final primaryValue = _mode == CreationMode.audio
        ? _audioVoice
        : selectedSkill?.name ??
              (skillProvider.isLoading ? '加载线路中…' : '暂无可选线路');

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
                _CourseBanner(onTap: () => context.go('/course')),
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
                    onTap: () => work?.action == CreatorWorkAction.viewReview
                        ? context.go('/submissions')
                        : context.go('/workbench'),
                  ),
                ],
                const SizedBox(height: 16),
                _CreationHero(
                  mode: _mode,
                  model: primaryValue,
                  ratio: _ratio,
                  count: _count,
                  promptController: _prompt,
                  placeholder: _placeholder,
                  videoHasRef: _videoHasRef,
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  onModelTap: () => _pickModel(skillProvider),
                  onRatioTap: _pickRatio,
                  onCountTap: _pickCount,
                  onToggleRef: () =>
                      setState(() => _videoHasRef = !_videoHasRef),
                  onGenerate: () => _generate(skillProvider),
                  buttonText: _buttonText,
                  cost: _cost,
                  generateEnabled:
                      _mode == CreationMode.audio || selectedSkill != null,
                ),
                if (_mode != CreationMode.audio) ...[
                  const SizedBox(height: 16),
                  _SkillRoutePanel(
                    provider: skillProvider,
                    skills: _skillsForMode(skillProvider),
                    selectedId: selectedSkill?.id,
                    onSelected: _selectSkill,
                  ),
                ],
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
                if (worksProvider.isLoading && recentWorks.isEmpty)
                  const GlassPanel(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (worksProvider.error != null && recentWorks.isEmpty)
                  EmptyPanel(
                    icon: Icons.cloud_off_outlined,
                    title: '最近作品加载失败',
                    subtitle: worksProvider.error!,
                    actionLabel: '重新加载',
                    onAction: worksProvider.refresh,
                  )
                else if (recentWorks.isEmpty)
                  const EmptyPanel(
                    icon: Icons.image_outlined,
                    title: '还没有作品',
                    subtitle: '完成一次生成后，最近作品会出现在这里。',
                  )
                else
                  PrototypeWorksGrid(
                    items: recentWorks,
                    onTap: (_) => context.push('/works'),
                  ),
              ],
            ),
          ),
          _CreateHomeDock(
            order: order,
            action: work?.action,
            reason: work?.reason,
            onOpenMarket: () => context.go('/market'),
            onContinueOrder: () => context.go('/workbench'),
            onViewReview: () => context.go('/submissions'),
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

class _SkillRoutePanel extends StatelessWidget {
  const _SkillRoutePanel({
    required this.provider,
    required this.skills,
    required this.selectedId,
    required this.onSelected,
  });

  final SkillProvider provider;
  final List<SkillModel> skills;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '创作线路',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '由后台 Skill 配置提供',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '刷新创作线路',
                onPressed: provider.isLoading
                    ? null
                    : () => provider.load(force: true),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (provider.isLoading && skills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.error != null && skills.isEmpty)
            Column(
              children: [
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.statusFailed),
                ),
                TextButton(
                  onPressed: () => provider.load(force: true),
                  child: const Text('重新加载线路'),
                ),
              ],
            )
          else if (skills.isEmpty)
            Text(
              '当前媒体类型暂无启用线路，请到后台检查 Skill 配置。',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            SkillSelector(
              skills: skills,
              selectedId: selectedId,
              allowAuto: false,
              title: '选择风格',
              subtitle: '点击切换',
              onChanged: (id) {
                if (id != null) onSelected(id);
              },
            ),
            if (provider.error != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.error!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.statusFailed),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CreateHomeDock extends StatelessWidget {
  const _CreateHomeDock({
    required this.order,
    required this.action,
    required this.reason,
    required this.onOpenMarket,
    required this.onContinueOrder,
    required this.onViewReview,
  });

  final MarketOrder? order;
  final CreatorWorkAction? action;
  final String? reason;
  final VoidCallback onOpenMarket;
  final VoidCallback onContinueOrder;
  final VoidCallback onViewReview;

  @override
  Widget build(BuildContext context) {
    final active = order;
    final theme = Theme.of(context);
    final waitingReview = action == CreatorWorkAction.viewReview;
    final unavailable = reason != null && !waitingReview;
    final label = active == null
        ? '还没有接单'
        : waitingReview
        ? '作品审核中'
        : unavailable
        ? '当前订单暂不可继续'
        : '当前订单';
    final subtitle = active == null
        ? '可以直接创作，也可以先接需求'
        : waitingReview
        ? '${active.title} · 不再占用新接单资格'
        : unavailable
        ? reason!
        : active.title;
    final buttonText = active == null
        ? '去接单'
        : waitingReview
        ? '查看审核'
        : unavailable
        ? '查看记录'
        : '继续';
    final onPressed = active == null
        ? onOpenMarket
        : waitingReview || unavailable
        ? onViewReview
        : onContinueOrder;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color:
                    (active == null || waitingReview
                            ? AppColors.gold
                            : AppColors.sage)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                active == null
                    ? Icons.storefront_outlined
                    : waitingReview
                    ? Icons.fact_check_outlined
                    : Icons.timer_outlined,
                color: active == null || waitingReview
                    ? AppColors.gold
                    : AppColors.sage,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 36,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                  backgroundColor: active == null || waitingReview
                      ? AppColors.gold
                      : AppColors.sage,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
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
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 电商创作训练营', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('培训 · 实操 · 考核，解锁专业订单', style: theme.textTheme.bodySmall),
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
            child: _QuickEntry(icon: item.$1, label: item.$2, onTap: item.$3),
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
    required this.generateEnabled,
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
  final bool generateEnabled;

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
                label: mode == CreationMode.audio ? '音色' : '线路',
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
              onPressed: generateEnabled ? onGenerate : null,
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
