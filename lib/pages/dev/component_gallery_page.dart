import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/skill_model.dart';
import '../../data/models/task_model.dart';
import '../../widgets/creation/credit_chip.dart';
import '../../widgets/creation/generate_bar.dart';
import '../../widgets/creation/param_slider_row.dart';
import '../../widgets/creation/prompt_input_card.dart';
import '../../widgets/creation/result_preview_card.dart';
import '../../widgets/creation/size_picker.dart';
import '../../widgets/creation/skill_selector.dart';
import '../../widgets/creation/task_status_card.dart';

/// 开发用组件预览页。
///
/// 这里不放业务逻辑，只把 8 个可复用组件摆出来看样式和状态。
/// 路由是 /dev/components，不算在 13 个业务页面里。
class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  final TextEditingController _promptController = TextEditingController(
    text: '雨夜霓虹街道，湿润路面倒影，电影感光效',
  );
  final TextEditingController _negativeController = TextEditingController();

  int? _selectedSkillId = 1;
  String _selectedRatio = '1:1';
  double _steps = 28;

  static const List<SkillModel> _demoSkills = [
    SkillModel(
      id: 1,
      code: 'anime_v1',
      name: '二次元插画',
      type: SkillType.textToImage,
      scene: '头像 / 立绘',
      modelName: 'sd-xl-anime',
      promptPrefix: 'masterpiece, best quality, anime style',
    ),
    SkillModel(
      id: 2,
      code: 'realistic_v1',
      name: '写实摄影',
      type: SkillType.textToImage,
      scene: '人像 / 风景',
      modelName: 'sd-xl-real',
    ),
    SkillModel(
      id: 3,
      code: 'ecommerce_v1',
      name: '电商海报',
      type: SkillType.textToImage,
      scene: '商品主图',
      modelName: 'sd-xl-product',
    ),
  ];

  static final TaskModel _demoTask = TaskModel(
    id: 1001,
    taskNo: 'TASK-DEMO-1001',
    type: TaskType.textToImage,
    status: TaskStatus.running,
    skillName: '二次元插画',
    progress: 42,
    canCancel: true,
    queueAt: DateTime.now().subtract(const Duration(seconds: 12)),
  );

  @override
  void dispose() {
    _promptController.dispose();
    _negativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('组件预览')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            '这页只做组件展示，不连接后端。组件通过参数接收数据，'
            '不 import api_client / repository / provider。',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),

          _GallerySection(
            name: 'PromptInputCard',
            description: '提示词输入卡，玻璃底 + 无边框输入。',
            child: PromptInputCard(
              controller: _promptController,
              trailing: TextButton(
                onPressed: () => _promptController.clear(),
                child: const Text('清空'),
              ),
            ),
          ),
          _GallerySection(
            name: 'SkillSelector',
            description: '创作线路横向胶囊，包含“自动线路”。',
            child: SkillSelector(
              skills: _demoSkills,
              selectedId: _selectedSkillId,
              onChanged: (value) => setState(() => _selectedSkillId = value),
            ),
          ),
          _GallerySection(
            name: 'SizePicker',
            description: '比例 / 尺寸选择。',
            child: SizePicker(
              sizes: const ['1:1', '3:4', '4:3', '9:16', '16:9'],
              selected: _selectedRatio,
              onChanged: (value) => setState(() => _selectedRatio = value),
            ),
          ),
          _GallerySection(
            name: 'ParamSliderRow',
            description: '标题 + 滑杆 + 数值的一行参数。',
            child: ParamSliderRow(
              label: '采样步数',
              value: _steps,
              min: 10,
              max: 50,
              divisions: 40,
              valueLabel: _steps.toStringAsFixed(0),
              onChanged: (value) => setState(() => _steps = value),
            ),
          ),
          _GallerySection(
            name: 'GenerateBar',
            description: '底部生成栏：算力消耗 + 渐变按钮。',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: GenerateBar(
                creditCost: 10,
                credits: 10000,
                onGenerate: () => _show('组件回调：开始生成'),
                hint: '预览页不会真的创建任务',
              ),
            ),
          ),
          _GallerySection(
            name: 'ResultPreviewCard',
            description: '结果预览：图片 / 视频 / 渐变占位。',
            child: ResultPreviewCard(
              title: '示例作品',
              subtitle: '图片占位状态',
              onTap: () => _show('组件回调：打开作品'),
            ),
          ),
          _GallerySection(
            name: 'TaskStatusCard',
            description: '任务状态、进度、重试 / 取消。',
            child: TaskStatusCard(
              task: _demoTask,
              onTap: () => _show('组件回调：打开任务'),
              onCancel: () => _show('组件回调：取消任务'),
              onRetry: () => _show('组件回调：重试任务'),
            ),
          ),
          _GallerySection(
            name: 'CreditChip',
            description: '算力余额胶囊，自动显示万 / 亿。',
            child: Align(
              alignment: Alignment.centerLeft,
              child: CreditChip(
                credits: 12860000,
                onTap: () => _show('组件回调：查看算力'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              '组件预览页 · /dev/components',
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.name,
    required this.description,
    required this.child,
  });

  final String name;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(name, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 2),
          Text(description, style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
