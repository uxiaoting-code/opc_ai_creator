import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_utils.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/notification_provider.dart';

/// 首页「消息入口」点开后的消息弹层。
///
/// 做成底部弹层而不是独立页面，是因为 13 个业务页面里没有「消息中心」，
/// 而消息入口又必须能点开看 —— 弹层既能承载内容，也不占用页面名额。
/// 后续如果要做完整的消息中心，再单独加一个页面路由即可。
class NotificationSheet extends StatelessWidget {
  const NotificationSheet({super.key});

  /// 统一入口：`NotificationSheet.show(context)`
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotificationProvider>();

    return ConstrainedBox(
      // 最多占屏幕 65%，避免长列表把整个屏幕盖满
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---------- 标题栏 ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text('消息', style: theme.textTheme.titleMedium),
                if (provider.hasUnread) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusFailed.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      '${provider.unreadCount} 条未读',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.statusFailed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (provider.hasUnread)
                  TextButton(
                    onPressed: provider.markAllRead,
                    child: const Text('全部已读'),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ---------- 列表 ----------
          Flexible(child: _buildList(context, provider)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('暂无消息', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: provider.notifications.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 60),
      itemBuilder: (context, index) =>
          _NotificationTile(notification: provider.notifications[index]),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _iconAndColor(notification.type);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      TimeUtils.relative(notification.createdAt),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notification.content,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // 未读小圆点
          if (!notification.isRead) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                color: AppColors.statusFailed,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 消息类型 → (图标, 主题色)
  (IconData, Color) _iconAndColor(String type) {
    switch (type) {
      case 'TASK':
        return (Icons.auto_awesome_rounded, AppColors.primary);
      case 'ACTIVITY':
        return (Icons.card_giftcard_rounded, AppColors.accent);
      case 'SYSTEM':
      default:
        return (Icons.campaign_outlined, AppColors.secondary);
    }
  }
}
