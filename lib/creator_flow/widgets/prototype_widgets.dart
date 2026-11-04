import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/creator_models.dart';
import 'creator_widgets.dart';

/// 原型风格参数胶囊：点击后由页面打开底部选择弹层。
class PrototypeParamPill extends StatelessWidget {
  const PrototypeParamPill({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 5),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: AppColors.taupe,
            ),
          ],
        ),
      ),
    );
  }
}

/// 创作首页的场景快捷入口。
class PrototypeScene {
  const PrototypeScene({
    required this.icon,
    required this.label,
    required this.mode,
    this.prompt = '',
  });

  final IconData icon;
  final String label;
  final CreationMode mode;
  final String prompt;
}

class PrototypeSceneStrip extends StatelessWidget {
  const PrototypeSceneStrip({
    super.key,
    required this.scenes,
    required this.onTap,
  });

  final List<PrototypeScene> scenes;
  final ValueChanged<PrototypeScene> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: scenes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final scene = scenes[index];
          return InkWell(
            onTap: () => onTap(scene),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              width: 76,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                boxShadow: AppColors.shadowSoft,
              ),
              child: Column(
                children: [
                  Icon(scene.icon, color: AppColors.sage, size: 23),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      scene.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 首页「最近作品」两列网格。
class PrototypeWorkItem {
  const PrototypeWorkItem(this.mode, this.seed);

  final CreationMode mode;
  final int seed;
}

class PrototypeWorksGrid extends StatelessWidget {
  const PrototypeWorksGrid({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<PrototypeWorkItem> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: ArtworkPreview(
            mode: item.mode,
            seed: item.seed,
            height: 210,
            showLabel: true,
            onTap: onTap,
          ),
        );
      },
    );
  }
}

/// 首页进行中订单横幅。
class PrototypeOrderBanner extends StatelessWidget {
  const PrototypeOrderBanner({
    super.key,
    required this.order,
    required this.onTap,
  });

  final MarketOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      onTap: onTap,
      backgroundColor: AppColors.gold.withValues(alpha: 0.1),
      borderColor: AppColors.gold.withValues(alpha: 0.28),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: AppColors.gold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('进行中的订单', style: theme.textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(
                  order.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
          CreatorTag(label: '继续创作', color: AppColors.gold),
        ],
      ),
    );
  }
}
