import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/media_utils.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../creator_flow_provider.dart';
import '../widgets/creator_widgets.dart';

/// 原型中的「生成结果」页。
///
/// 进入页面时带一个刚创建的 [TaskModel]，随后每 3 秒轮询一次任务状态，
/// 直到后端标记 `finished`，成功后展示真实 `resultUrl`。
class ResultPage extends StatefulWidget {
  const ResultPage({super.key, this.initialTask});

  final TaskModel? initialTask;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  TaskModel? _task;
  Timer? _timer;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _task = widget.initialTask;
    _loading = _task == null;
    if (_task != null) {
      _schedulePoll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedulePoll() {
    _timer?.cancel();
    _timer = Timer(AppConfig.taskPollInterval, _poll);
  }

  Future<void> _poll() async {
    final task = _task;
    if (task == null || !mounted) return;
    try {
      final fresh = await context.read<TaskRepository>().fetchDetail(task.id);
      if (!mounted) return;
      setState(() {
        _task = fresh;
        _loading = false;
        _error = null;
      });
      if (!fresh.finished) {
        _schedulePoll();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
      _schedulePoll();
    }
  }

  Future<void> _retry() async {
    final task = _task;
    if (task == null || !task.canRetry) return;
    setState(() => _loading = true);
    try {
      final fresh = await context.read<TaskRepository>().retryTask(task.id);
      if (!mounted) return;
      setState(() {
        _task = fresh;
        _loading = false;
        _error = null;
      });
      _schedulePoll();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _copyResultUrl() async {
    final task = _task;
    if (task?.resultUrl == null) return;
    await Clipboard.setData(ClipboardData(text: task!.resultUrl!));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('结果链接已复制')));
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<CreatorFlowProvider>();
    final order = flow.currentOrder;
    final task = _task;

    return CreatorScreen(
      title: '生成结果',
      onBack: () => context.pop(),
      padding: EdgeInsets.zero,
      child: _buildBody(context, task, order),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TaskModel? task,
    dynamic order,
  ) {
    if (_loading && task == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (task == null) {
      return EmptyPanel(
        icon: Icons.image_not_supported_outlined,
        title: '还没有生成结果',
        subtitle: '请先选择一个创作模式并完成一次生成。',
        actionLabel: '返回创作首页',
        onAction: () => context.go('/create'),
      );
    }

    final succeeded = task.status == TaskStatus.success && task.hasResult;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _TaskStatusBanner(task: task),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 12),
              _PromptSummary(prompt: task.prompt),
              const SizedBox(height: 12),
              _ResultMeta(task: task),
              const SizedBox(height: 14),
              _ResultViewer(task: task),
              if (succeeded) ...[
                const SizedBox(height: 14),
                _ResultActions(
                  task: task,
                  onRetry: task.canRetry ? _retry : null,
                  onCopy: _copyResultUrl,
                ),
              ],
              if (succeeded) ...[
                const SizedBox(height: 18),
                const CreatorSectionHeader(title: '试试这些微调'),
                const SizedBox(height: 10),
                _RefineRow(task: task),
              ],
            ],
          ),
        ),
        CreatorBottomAction(
          label: task.finished
              ? (order != null ? '提交到订单' : '完成')
              : '生成中…',
          icon: task.finished
              ? Icons.task_alt_rounded
              : Icons.hourglass_top_rounded,
          caption: task.displayStatusLabel,
          onPressed: task.finished
              ? () {
                  if (order != null) {
                    context.push('/submission');
                  } else {
                    context.go('/create');
                  }
                }
              : null,
        ),
      ],
    );
  }
}

class _TaskStatusBanner extends StatelessWidget {
  const _TaskStatusBanner({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = task.status.isActive;
    final color = switch (task.status) {
      TaskStatus.success => AppColors.sage,
      TaskStatus.failed => AppColors.statusFailed,
      TaskStatus.canceled => AppColors.taupe,
      _ => AppColors.gold,
    };
    return GlassPanel(
      backgroundColor: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.22),
      child: Row(
        children: [
          Icon(
            switch (task.status) {
              TaskStatus.success => Icons.check_circle_rounded,
              TaskStatus.failed => Icons.cancel_rounded,
              TaskStatus.canceled => Icons.remove_circle_outline_rounded,
              _ => Icons.schedule_rounded,
            },
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.displayStatusLabel, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  isRunning ? '任务正在后台生成，页面会自动刷新' : '任务已完成',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isRunning)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      backgroundColor: AppColors.statusFailed.withValues(alpha: 0.07),
      borderColor: AppColors.statusFailed.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.statusFailed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _PromptSummary extends StatelessWidget {
  const _PromptSummary({required this.prompt});

  final String? prompt;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.sage),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              prompt?.isNotEmpty == true ? prompt! : '（未填写创作描述）',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMeta extends StatelessWidget {
  const _ResultMeta({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CreatorMetric(
            label: '模型',
            value: task.skillName ?? task.provider ?? task.typeLabel ?? '—',
            icon: Icons.auto_awesome_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CreatorMetric(
            label: '任务号',
            value: task.taskNo,
            icon: Icons.tag_rounded,
            accent: AppColors.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CreatorMetric(
            label: '耗时',
            value: task.durationLabel ?? '生成中',
            icon: Icons.timer_outlined,
          ),
        ),
      ],
    );
  }
}

class _ResultViewer extends StatelessWidget {
  const _ResultViewer({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final url = task.displayImageUrl;
    if (task.status == TaskStatus.success && url != null) {
      if (task.type == TaskType.textToAudio) {
        return _AudioResult(url: url);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
        child: Image.network(
          AppConfig.resolveAssetUrl(url),
          height: 340,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 340,
              alignment: Alignment.center,
              color: AppColors.sageTint,
              child: const CircularProgressIndicator(),
            );
          },
          errorBuilder: (context, error, stack) => Container(
            height: 340,
            alignment: Alignment.center,
            color: AppColors.sageTint,
            child: const Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: AppColors.taupe,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 320,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.sageTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.status.isActive)
            const CircularProgressIndicator()
          else
            Icon(
              task.status == TaskStatus.failed
                  ? Icons.error_outline_rounded
                  : Icons.hourglass_empty_rounded,
              size: 48,
              color: AppColors.taupe,
            ),
          const SizedBox(height: 14),
          Text(
            task.errorMsg ?? '结果生成后会显示在这里',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({
    required this.task,
    required this.onRetry,
    required this.onCopy,
  });

  final TaskModel task;
  final VoidCallback? onRetry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ResultAction(
          icon: Icons.download_rounded,
          label: '下载',
          onTap: () async {
            final url = task.resultUrl;
            if (url == null) return;
            final ok = await MediaUtils.saveToLocal(
              url: AppConfig.resolveAssetUrl(url),
              filename: 'task_${task.id}',
              isVideo: task.type == TaskType.imageToVideo,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(ok ? '已保存' : '下载功能暂未完成')),
              );
          },
        ),
        _ResultAction(
          icon: Icons.refresh_rounded,
          label: '重生',
          onTap: onRetry,
        ),
        _ResultAction(
          icon: Icons.hd_rounded,
          label: '高清',
          onTap: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('高清放大暂未接入')));
          },
        ),
        _ResultAction(
          icon: Icons.photo_filter_rounded,
          label: '参考',
          onTap: onCopy,
        ),
        _ResultAction(
          icon: Icons.share_rounded,
          label: '分享',
          onTap: onCopy,
        ),
      ],
    );
  }
}

class _ResultAction extends StatelessWidget {
  const _ResultAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: AppColors.sage, size: 20),
              const SizedBox(height: 5),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioResult extends StatelessWidget {
  const _AudioResult({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 52),
          const SizedBox(height: 12),
          Text(
            '音频已生成',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            url,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefineRow extends StatelessWidget {
  const _RefineRow({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final chips = task.type == TaskType.textToImage
        ? ['换成暖光', '加模特', '换背景色', '生成视频']
        : ['更慢一点', '换背景', '加字幕', '重新生成'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in chips)
          ActionChip(
            label: Text(chip),
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('已应用：$chip')));
            },
          ),
      ],
    );
  }
}
