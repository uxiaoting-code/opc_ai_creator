import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// 底部导航外壳。
///
/// 对应 5 个 Tab：首页 / 任务 / 画廊 / 素材 / 我的。
/// 视觉上改成原型里的“毛玻璃悬浮底栏”：半透明白、细描边、柔和阴影，
/// 选中项用鼠尾草绿的胶囊底。
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_NavItem> _items = [
    _NavItem(
      label: '首页',
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
    ),
    _NavItem(
      label: '任务',
      icon: CupertinoIcons.square_list,
      activeIcon: CupertinoIcons.square_list_fill,
    ),
    _NavItem(
      label: '画廊',
      icon: CupertinoIcons.square_grid_2x2,
      activeIcon: CupertinoIcons.square_grid_2x2_fill,
    ),
    _NavItem(
      label: '素材',
      icon: CupertinoIcons.photo,
      activeIcon: CupertinoIcons.photo_fill,
    ),
    _NavItem(
      label: '我的',
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.92)
                  : AppColors.glassStrong,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              boxShadow: AppColors.shadowSoft,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      _NavButton(
                        item: _items[i],
                        active: navigationShell.currentIndex == i,
                        onTap: () => _onTap(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactive = theme.brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.taupe;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.sageTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  size: 22,
                  color: active ? AppColors.sage : inactive,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? AppColors.sage : inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
