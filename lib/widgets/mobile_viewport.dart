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

  /// Web 宽屏时两侧的留白色：用原型的暖灰米色，突出中间的「手机屏」。
  static const Color _frameBackground = Color(0xFFEDE9E1);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxWidth = AppSpacing.mobileMaxWidth;
        final page = Stack(
          fit: StackFit.expand,
          children: [const _PremiumBackdrop(), child],
        );

        // 手机 / 窄窗口：不做任何处理
        if (constraints.maxWidth <= maxWidth) return page;

        // 宽屏：模板外层是暖灰画布，中间保留一块完整的 App 视口。
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.72, -0.82),
              radius: 1.25,
              colors: [Color(0xFFF3E9DC), _frameBackground],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: maxWidth,
                height: constraints.maxHeight,
                child: ClipRect(child: page),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 模板页面背景：暖白底 + 左上蜜桃光 + 右上奶油光 + 左下鼠尾草光。
class _PremiumBackdrop extends StatelessWidget {
  const _PremiumBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const ColoredBox(color: Color(0xFF141311));
    }

    return const Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Color(0xFFF7F7F5)),
        _Glow(
          alignment: Alignment(-0.86, -0.92),
          size: 560,
          color: Color(0xD9FBE8DC),
        ),
        _Glow(
          alignment: Alignment(1.08, -0.2),
          size: 480,
          color: Color(0xCFF5EDDE),
        ),
        _Glow(
          alignment: Alignment(-0.5, 1.12),
          size: 580,
          color: Color(0x99E0E8DC),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
