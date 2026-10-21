import 'package:flutter/material.dart';

/// 品牌配色：Light Premium · 暖白 + 鼠尾草绿 + 香槟金。
///
/// 这套颜色来自老师给的移动端原型：
/// - 暖白/奶油底，避免纯白刺眼；
/// - 鼠尾草绿做主色，香槟金做强调色；
/// - 灰褐做次级文字，柔炭黑做正文；
/// - 毛玻璃卡片 + 大圆角 + 柔和阴影。
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // 原型设计令牌
  // ---------------------------------------------------------------------------

  static const Color warmBackground = Color(0xFFF7F7F5);
  static const Color peach = Color(0xFFFBE8DC);
  static const Color cream = Color(0xFFF5EDDE);

  static const Color sage = Color(0xFF7C9A7E);
  static const Color sageSoft = Color(0xFFA8BFA9);
  static const Color sageTint = Color(0x1A7C9A7E); // 10% 鼠尾草绿

  static const Color gold = Color(0xFFC9A96E);
  static const Color goldSoft = Color(0xFFE4D0A8);

  static const Color taupe = Color(0xFF8B8178);
  static const Color charcoal = Color(0xFF1C1C1E);
  static const Color textBody = Color(0xFF3C3C40);
  static const Color textMuted = Color(0xFF8B8178);
  static const Color divider = Color(0x0F000000); // 6% 黑

  static const Color glass = Color(0xB3FFFFFF); // 70% 白
  static const Color glassStrong = Color(0xD9FFFFFF); // 85% 白

  // ---------------------------------------------------------------------------
  // 保持原有名字，避免改动所有页面
  // ---------------------------------------------------------------------------

  static const Color primary = sage;
  static const Color primaryDark = Color(0xFF5F7D61);
  static const Color secondary = gold;
  static const Color accent = gold;

  static const Color lightBackground = warmBackground;
  static const Color lightSurface = Color(0xFFFFFDF9);
  static const Color lightBorder = Color(0xFFE9E2D8);
  static const Color lightTextPrimary = charcoal;
  static const Color lightTextSecondary = textMuted;

  static const Color darkBackground = Color(0xFF141311);
  static const Color darkSurface = Color(0xFF1F1D1A);
  static const Color darkBorder = Color(0xFF35312C);
  static const Color darkTextPrimary = Color(0xFFF5F0E8);
  static const Color darkTextSecondary = Color(0xFFB8AEA2);

  // ---------------------------------------------------------------------------
  // 渐变
  // ---------------------------------------------------------------------------

  /// 主行动渐变：鼠尾草绿 → 香槟金。
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sage, gold],
  );

  static const LinearGradient sageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sageSoft, sage],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldSoft, gold],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [peach, cream],
  );

  /// 占位/骨架的柔和流光。
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33F5EDDE), Color(0x337C9A7E)],
  );

  // ---------------------------------------------------------------------------
  // 阴影
  // ---------------------------------------------------------------------------

  static const List<BoxShadow> shadowSoft = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowLift = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 32, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> shadowButton = [
    BoxShadow(color: Color(0x477C9A7E), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // ---------------------------------------------------------------------------
  // 语义色：Harness 任务状态
  // ---------------------------------------------------------------------------

  static const Color statusQueued = Color(0xFFA79E92);
  static const Color statusRunning = gold;
  static const Color statusSuccess = sage;
  static const Color statusFailed = Color(0xFFD9705F);
  static const Color statusCanceled = Color(0xFFB8AEA2);
}
