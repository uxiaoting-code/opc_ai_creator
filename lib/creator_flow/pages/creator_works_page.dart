import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/work_model.dart';
import '../../providers/work_provider.dart';
import '../../widgets/premium/premium_choice_chip.dart';
import '../../widgets/premium/premium_top_bar.dart';
import '../../widgets/state_views.dart';

/// 用户端「我的作品」页。
///
/// 首页的「最近作品」和「全部」都进入这里，不再跳到个人中心。
class CreatorWorksPage extends StatefulWidget {
  const CreatorWorksPage({super.key});

  @override
  State<CreatorWorksPage> createState() => _CreatorWorksPageState();
}

class _CreatorWorksPageState extends State<CreatorWorksPage> {
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkProvider>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkProvider>();
    final works = switch (_filter) {
      1 => provider.works.where((work) => !work.isVideo).toList(),
      2 => provider.works.where((work) => work.isVideo).toList(),
      _ => provider.works,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: premiumTopBar(
        title: '我的作品',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/create');
          }
        },
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: provider.isLoading ? null : provider.refresh,
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      PremiumChoiceChip(
                        label: const ['全部', '图片', '视频'][i],
                        selected: _filter == i,
                        onTap: () => setState(() => _filter = i),
                        compact: true,
                      ),
                      if (i < 2) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(child: _buildBody(provider, works)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(WorkProvider provider, List<WorkModel> works) {
    if (provider.isLoading && works.isEmpty) {
      return const LoadingView(message: '正在加载作品…');
    }
    if (provider.error != null && works.isEmpty) {
      return ErrorView(message: provider.error!, onRetry: provider.refresh);
    }
    if (works.isEmpty) {
      return const EmptyView(
        icon: Icons.image_outlined,
        title: '还没有作品',
        description: '生成成功后的图片和视频会显示在这里',
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: AppColors.sage,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: works.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final work = works[index];
          return _WorkCard(
            work: work,
            onTap: () => _openWork(work),
          );
        },
      ),
    );
  }

  void _openWork(WorkModel work) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkDetailSheet(work: work),
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.work, required this.onTap});

  final WorkModel work;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rawUrl = work.coverUrl?.isNotEmpty == true
        ? work.coverUrl!
        : work.resourceUrl;
    final url = AppConfig.resolveAssetUrl(rawUrl);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isEmpty)
              const ColoredBox(color: AppColors.sageTint)
            else
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.sageTint),
              ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  work.type.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (work.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                  ),
                ),
                child: Text(
                  work.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkDetailSheet extends StatelessWidget {
  const _WorkDetailSheet({required this.work});

  final WorkModel work;

  @override
  Widget build(BuildContext context) {
    final rawUrl = work.coverUrl?.isNotEmpty == true
        ? work.coverUrl!
        : work.resourceUrl;
    final url = AppConfig.resolveAssetUrl(rawUrl);
    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.warmBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.taupe.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          work.displayTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (url.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
                      child: Image.network(
                        url,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 220,
                          color: AppColors.sageTint,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    work.prompt ?? '暂无创作描述',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
