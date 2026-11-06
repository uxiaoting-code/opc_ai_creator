import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../creator_flow_provider.dart';
import '../data/creator_order_repository.dart';

class CreatorMainShell extends StatefulWidget {
  const CreatorMainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<CreatorMainShell> createState() => _CreatorMainShellState();
}

class _CreatorMainShellState extends State<CreatorMainShell>
    with WidgetsBindingObserver {
  static const _items = [
    _NavItem('课程', Icons.school_outlined, Icons.school_rounded),
    _NavItem(
      '创作',
      Icons.auto_awesome_outlined,
      Icons.auto_awesome_rounded,
    ),
    _NavItem('接单', Icons.storefront_outlined, Icons.storefront_rounded),
    _NavItem('我的', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshContext());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshContext();
  }

  Future<void> _refreshContext() async {
    if (!mounted) return;
    try {
      final context = await CreatorOrderRepository(
        this.context.read<ApiClient>(),
      ).fetchCurrentWork();
      if (!mounted) return;
      this.context.read<CreatorFlowProvider>().applyWorkContext(context);
    } catch (_) {
      // 网络失败时保留现有状态；页面仍会各自展示错误提示。
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: _NavButton(
                          item: _items[i],
                          active: navigationShell.currentIndex == i,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            navigationShell.goBranch(
                              i,
                              initialLocation:
                                  i == navigationShell.currentIndex,
                            );
                          },
                        ),
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
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 220),
              scale: active ? 1.08 : 1,
              child: Icon(
                active ? item.activeIcon : item.icon,
                size: 22,
                color: active ? AppColors.sage : AppColors.taupe,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.sage : AppColors.taupe,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
