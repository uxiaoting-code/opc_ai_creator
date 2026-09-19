import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// 首页顶部栏。
///
/// 三段式结构（对应需求 1）：
/// - 第一行：头像 + 问候语 + 算力点数 + 消息入口
/// - 第二行：搜索框
///
/// 顶部栏固定不参与滚动，搜索框始终可见 —— 这是内容型首页的常见做法。
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.nickname,
    required this.credits,
    required this.unreadCount,
    required this.unreadLabel,
    required this.onCreditsTap,
    required this.onMessagesTap,
    required this.onSearchTap,
  });

  final String nickname;

  /// 剩余算力点数。null 表示还没从后端取到，显示占位符 `—`。
  final int? credits;

  /// 未读消息数，0 时不显示红点
  final int unreadCount;

  /// 红点文案（超过 99 已是 `99+`）
  final String unreadLabel;

  final VoidCallback onCreditsTap;
  final VoidCallback onMessagesTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          // ---------- 第一行：问候 + 算力 + 消息 ----------
          Row(
            children: [
              // 头像（点进个人中心）
              GestureDetector(
                onTap: onCreditsTap,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    nickname.isEmpty ? '?' : nickname.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '你好，$nickname',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '今天想创作点什么？',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // 算力点数：点进个人中心看明细
              _PillButton(
                onTap: onCreditsTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 3),
                    Text(
                      // 还没拉到真实值时不显示 0 —— 那会让用户以为算力点没了
                      credits?.toString() ?? '—',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // 消息入口：带未读红点
              _PillButton(
                onTap: onMessagesTap,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadLabel),
                  backgroundColor: AppColors.statusFailed,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 22,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ---------- 第二行：搜索框 ----------
          //
          // 做成「长得像输入框的按钮」而不是真正的 TextField：
          // 移动端首页搜索是导航入口，点击后进真正的搜索页，
          // 这样不用在首页重复实现一套搜索逻辑。
          // 这里跳到 Prompt 知识库（第 8 个页面），它本身带检索与分类筛选。
          InkWell(
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: Container(
              height: AppSpacing.touchTargetMin,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(
                  color: theme.dividerTheme.color ?? Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '搜索提示词、创作线路',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部栏用的小圆角按钮容器。
///
/// 统一保证高度 ≥ 40，宽度自适应，避免手指点不中。
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        height: 40,
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: theme.dividerTheme.color ?? Colors.transparent,
          ),
        ),
        child: child,
      ),
    );
  }
}
