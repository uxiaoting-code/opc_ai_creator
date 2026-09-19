import 'package:flutter/foundation.dart';

/// 平台判断工具。
///
/// 全项目统一从这里判断平台，**禁止直接 import 'dart:io'**——
/// `dart:io` 在 Web 上不存在，一旦引入 `flutter build web` 直接编译失败。
/// [kIsWeb] 与 [defaultTargetPlatform] 都来自 `flutter/foundation`，双端安全。
class PlatformUtils {
  const PlatformUtils._();

  /// 是否运行在浏览器（Chrome 调试 / Web 发布）。
  static bool get isWeb => kIsWeb;

  /// 是否 Android。
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// 是否 iOS。
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// 是否桌面端。桌面端不参与手机竖屏布局，需要居中收窄显示。
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// 是否为移动端（Android / iOS 原生）。
  static bool get isMobile => isAndroid || isIOS;

  /// 是否窄屏（手机竖屏布局判定）。
  ///
  /// Web 调试时浏览器窗口可能很宽，此时业务代码仍按手机布局走，
  /// 由 [MobileViewport] 负责在宽屏下居中收窄。
  static bool isNarrowScreen(double width) => width < 600;

  /// 当前平台名，用于日志和「设置页」展示。
  static String get platformName {
    if (kIsWeb) return 'Web';
    return defaultTargetPlatform.name;
  }
}
