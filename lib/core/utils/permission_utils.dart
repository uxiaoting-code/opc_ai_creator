import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'platform_utils.dart';

/// 权限申请结果。
///
/// 不直接把 `permission_handler` 的 [PermissionStatus] 暴露给业务层，
/// 是为了让 UI 只关心「能不能用」和「要不要引导去设置页」两件事。
enum AppPermissionStatus {
  /// 已授权
  granted,

  /// 被拒绝，但还能再次弹窗申请
  denied,

  /// 被永久拒绝，只能引导用户去系统设置里手动开
  permanentlyDenied,

  /// 当前平台不需要这个权限（例如 Web）
  notRequired,
}

extension AppPermissionStatusX on AppPermissionStatus {
  bool get isGranted =>
      this == AppPermissionStatus.granted ||
      this == AppPermissionStatus.notRequired;

  /// 给用户看的提示文案。
  String get message {
    switch (this) {
      case AppPermissionStatus.granted:
        return '已授权';
      case AppPermissionStatus.denied:
        return '需要授权后才能使用该功能';
      case AppPermissionStatus.permanentlyDenied:
        return '权限已被永久拒绝，请到「系统设置 → 应用 → OPC AI 创作平台 → 权限」中手动开启';
      case AppPermissionStatus.notRequired:
        return '当前平台无需授权';
    }
  }
}

/// Android / iOS 相册与存储权限统一入口。
///
/// **Web 端全部直接返回 [AppPermissionStatus.notRequired]**：
/// 浏览器选文件走的是 `<input type="file">`，不存在权限申请这回事，
/// 所以这里必须先判平台，否则在 Chrome 上会直接抛异常。
///
/// Android 侧还需要在 `android/app/src/main/AndroidManifest.xml` 里补声明
/// （见文件末尾注释，第 5 步打包前一并加上）。
class PermissionUtils {
  const PermissionUtils._();

  // ===========================================================================
  // 相册（读取图片 / 视频）
  // ===========================================================================

  /// 申请相册读取权限。
  ///
  /// Android 13+ 用 `READ_MEDIA_IMAGES`，旧版本回退到 `READ_EXTERNAL_STORAGE`，
  /// `permission_handler` 的 [Permission.photos] 已经帮我们做了版本适配。
  static Future<AppPermissionStatus> requestGallery() async {
    if (!PlatformUtils.isMobile) return AppPermissionStatus.notRequired;

    try {
      // Android 13 以下 photos 会直接返回 denied，此时回退到 storage
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) {
        return AppPermissionStatus.granted;
      }
      if (photos.isPermanentlyDenied) {
        return AppPermissionStatus.permanentlyDenied;
      }

      final storage = await Permission.storage.request();
      if (storage.isGranted) return AppPermissionStatus.granted;
      if (storage.isPermanentlyDenied) {
        return AppPermissionStatus.permanentlyDenied;

      }
      return AppPermissionStatus.denied;
    } catch (e) {
      debugPrint('申请相册权限异常: $e');
      return AppPermissionStatus.denied;
    }
  }

  // ===========================================================================
  // 相机（拍照上传素材 / 现拍现传）
  // ===========================================================================

  /// 申请相机权限。
  static Future<AppPermissionStatus> requestCamera() async {
    if (!PlatformUtils.isMobile) return AppPermissionStatus.notRequired;

    try {
      final status = await Permission.camera.request();
      if (status.isGranted) return AppPermissionStatus.granted;
      if (status.isPermanentlyDenied) {
        return AppPermissionStatus.permanentlyDenied;
      }
      return AppPermissionStatus.denied;
    } catch (e) {
      debugPrint('申请相机权限异常: $e');
      return AppPermissionStatus.denied;
    }
  }

  // ===========================================================================
  // 保存文件到本地相册（作品下载）
  // ===========================================================================

  /// 申请「写入相册」权限，保存生成的图片/视频时用。
  ///
  /// Android 10+ 使用分区存储，往相册写通常不需要额外权限；
  /// 这里保留申请逻辑是为了兼容 Android 9 及以下。
  static Future<AppPermissionStatus> requestSaveToGallery() async {
    if (!PlatformUtils.isMobile) return AppPermissionStatus.notRequired;

    try {
      // Android 13+ 写自己的媒体文件无需授权，直接放行
      final status = await Permission.storage.request();
      if (status.isGranted || status.isLimited) {
        return AppPermissionStatus.granted;
      }
      // 被拒绝也不算致命：Android 10+ 依然能通过 MediaStore 写入
      return AppPermissionStatus.denied;
    } catch (e) {
      debugPrint('申请存储权限异常: $e');
      return AppPermissionStatus.denied;
    }
  }

  // ===========================================================================
  // 批量申请（进素材库页时一次性申请到位）
  // ===========================================================================

  /// 一次性申请素材库需要的全部权限，返回是否全部通过。
  static Future<AppPermissionStatus> requestMaterialLibraryPermissions() async {
    if (!PlatformUtils.isMobile) return AppPermissionStatus.notRequired;

    try {
      final results = await [
        Permission.photos,
        Permission.storage,
        Permission.camera,
      ].request();

      final allGranted = results.values.every(
        (s) => s.isGranted || s.isLimited || s.isDenied,
      );
      final anyPermanentlyDenied =
          results.values.any((s) => s.isPermanentlyDenied);

      if (anyPermanentlyDenied) {
        // 相机被永久拒绝不影响选相册，素材库主流程仍可用
        return AppPermissionStatus.permanentlyDenied;
      }
      return allGranted
          ? AppPermissionStatus.granted
          : AppPermissionStatus.denied;
    } catch (e) {
      debugPrint('批量申请权限异常: $e');
      return AppPermissionStatus.denied;
    }
  }

  /// 跳转到系统设置页，让用户手动开权限。
  static Future<void> openSystemSettings() async {
    if (!PlatformUtils.isMobile) return;
    await openAppSettings();
  }

  /// 当前相册权限是否已授予（不弹窗，只查询）。
  static Future<bool> hasGalleryAccess() async {
    if (!PlatformUtils.isMobile) return true;
    try {
      final photos = await Permission.photos.status;
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await Permission.storage.status;
      return storage.isGranted;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // AndroidManifest 待补充的权限声明（第 5 步打包前加，现在先记在这里）
  // ===========================================================================
  //
  // 路径：android/app/src/main/AndroidManifest.xml，放在 <manifest> 直接子级：
  //
  // <!-- 网络：所有接口调用 -->
  // <uses-permission android:name="android.permission.INTERNET"/>
  // <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
  //
  // <!-- Android 13+ 读取相册图片 / 视频 -->
  // <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
  // <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
  //
  // <!-- Android 12 及以下读取外部存储 -->
  // <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
  //     android:maxSdkVersion="32"/>
  // <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
  //     android:maxSdkVersion="28"/>
  //
  // <!-- 拍照上传素材 -->
  // <uses-permission android:name="android.permission.CAMERA"/>
  // <uses-feature android:name="android.hardware.camera" android:required="false"/>
  //
  // <!-- Android 11+ 若需查询相册类应用（image_picker 在部分机型上需要） -->
  // <queries>
  //   <intent>
  //     <action android:name="android.media.action.IMAGE_CAPTURE"/>
  //   </intent>
  // </queries>
  //
  // 另外：明文 HTTP 访问局域网后端需要
  // android:usesCleartextTraffic="true"（加在 <application> 标签上），
  // 否则 Android 9+ 会直接拦截 http://192.168.x.x 的请求。
}
