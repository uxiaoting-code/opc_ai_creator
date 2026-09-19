import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 底部导航外壳。
///
/// 对应需求里的 5 个 Tab 页：首页 / 任务 / 画廊 / 素材库 / 我的。
/// 使用 [StatefulNavigationShell]，每个 Tab 拥有独立的导航栈：
/// 在「任务」Tab 里点进任务详情后切到「画廊」，再切回来仍停留在详情页，
/// 这是手机 App 的标准交互，也是用 StatefulShellRoute 而不是普通 TabBar 的原因。
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  /// go_router 注入的 shell 状态，负责实际的 Tab 切换。
  final StatefulNavigationShell navigationShell;

  /// 5 个 Tab 的图标与文案。顺序必须与 AppRouter 里 branches 的顺序一致。
  static const List<_NavItem> _items = [
    _NavItem(label: '首页', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
    _NavItem(
      label: '任务',
      icon: Icons.playlist_play_outlined,
      activeIcon: Icons.playlist_play_rounded,
    ),
    _NavItem(
      label: '画廊',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
    ),
    _NavItem(
      label: '素材',
      icon: Icons.photo_library_outlined,
      activeIcon: Icons.photo_library_rounded,
    ),
    _NavItem(label: '我的', icon: Icons.person_outline, activeIcon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack 由 go_router 维护，这里不传 bottomNavigationBar 以外的装饰
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          for (final item in _items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    // initialLocation: true 表示点击「当前已选中的 Tab」时，
    // 把该分支的导航栈弹回根页面（跟微信/淘宝的行为一致）。
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
