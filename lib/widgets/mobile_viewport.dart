import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// 手机竖屏视口约束。
///
/// 需求：UI 只按手机竖屏设计，不做电脑宽屏布局。
/// 但 Web 调试时浏览器窗口很宽，如果不处理，页面会被拉成横跨整个屏幕的
/// 宽屏布局，和最终 APK 里的效果完全不一样。
///
/// 解决方式：挂到 `MaterialApp.builder` 上，
/// 宽度超过 [AppSpacing.mobileMaxWidth] 时把整棵页面树居中收窄成手机比例，
/// 两侧留深色背景。Android 上宽度本来就小于阈值，这个方法直接返回 child，
/// **零额外开销，也不影响真机表现**。
class MobileViewport extends StatelessWidget {
  const MobileViewport({super.key, required this.child});

  final Widget child;

  /// Web 宽屏时两侧的留白色，用深色以突出中间的「手机屏」。
  static const Color _frameBackground = Color(0xFF0B0D12);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxWidth = AppSpacing.mobileMaxWidth;

        // 手机 / 窄窗口：不做任何处理
        if (constraints.maxWidth <= maxWidth) return child;

        // 宽屏：居中 + 固定宽高（给死约束，避免 Navigator 拿到松约束后布局异常）
        return ColoredBox(
          color: _frameBackground,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: maxWidth,
                height: constraints.maxHeight,
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }
}
