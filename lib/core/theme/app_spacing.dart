/// 间距 / 圆角 / 尺寸 设计令牌。
///
/// 约束：手机竖屏优先，所有可点击元素的高度不小于 [touchTargetMin]，
/// 保证手指点得中（Material 无障碍规范要求 48dp）。
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// 页面统一的水平内边距。
  static const double pagePadding = 16;

  // --- 圆角 ---
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  // --- 组件尺寸 ---
  /// 主按钮最小高度：手指友好。
  static const double buttonHeight = 52;

  /// 可点击区域最小边长。
  static const double touchTargetMin = 48;

  /// 底部导航栏高度。
  static const double bottomNavHeight = 64;

  /// 页面最大内容宽度：Web 宽屏时居中收窄成手机比例。
  static const double mobileMaxWidth = 480;
}
