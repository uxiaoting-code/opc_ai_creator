import 'package:flutter/material.dart';

/// 品牌配色。
///
/// AI 创作类产品的视觉惯例：深色底 + 高饱和渐变强调色。
/// 这里以「电光紫 → 青蓝」为主渐变，用于主按钮、选中态、生成中动画。
class AppColors {
  const AppColors._();

  // --- 品牌主色 ---
  static const Color primary = Color(0xFF6C4DF6); // 电光紫
  static const Color primaryDark = Color(0xFF4A2FD1);
  static const Color secondary = Color(0xFF17C3E6); // 青蓝
  static const Color accent = Color(0xFFFF5A9E); // 品红点缀

  /// 主渐变：用于「开始生成」等主行动按钮。
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary],
  );

  /// 卡片上用于「生成中」的流光渐变。
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x226C4DF6), Color(0x2217C3E6)],
  );

  // --- 浅色主题 ---
  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6E8F0);
  static const Color lightTextPrimary = Color(0xFF1A1C25);
  static const Color lightTextSecondary = Color(0xFF6B7086);

  // --- 深色主题 ---
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF181B24);
  static const Color darkBorder = Color(0xFF2A2E3C);
  static const Color darkTextPrimary = Color(0xFFF2F3F7);
  static const Color darkTextSecondary = Color(0xFF9BA1B4);

  // --- 语义色：对应 Harness 任务状态 ---
  /// 排队中
  static const Color statusQueued = Color(0xFF8A8FA3);

  /// 生成中
  static const Color statusRunning = Color(0xFF2E90FA);

  /// 成功
  static const Color statusSuccess = Color(0xFF12B76A);

  /// 失败
  static const Color statusFailed = Color(0xFFF04438);

  /// 已取消
  static const Color statusCanceled = Color(0xFFB0B4C4);
}
