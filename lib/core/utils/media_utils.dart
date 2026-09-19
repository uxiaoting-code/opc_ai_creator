import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'permission_utils.dart';
import 'platform_utils.dart';

/// 图片 / 视频选择工具，Web 与 Android 行为统一。
///
/// ## 为什么必须用字节流而不是文件路径
///
/// `XFile.path` 在 Web 上是一个 `blob:` 开头的临时 URL，后端根本拿不到；
/// 只有在 Android 上才是真实的文件系统路径。
/// 所以上传时**一律 `await xfile.readAsBytes()` 拿字节流**，
/// 交给 `ApiClient.uploadBytes` 走 multipart，两端才能共用同一套代码。
class MediaUtils {
  const MediaUtils._();

  static final ImagePicker _picker = ImagePicker();

  /// 单张图片最大体积（10MB），超出直接拦下来，避免上传到一半失败。
  static const int maxImageBytes = 10 * 1024 * 1024;

  /// 单段视频最大体积（100MB）。
  static const int maxVideoBytes = 100 * 1024 * 1024;

  // ===========================================================================
  // 选择图片
  // ===========================================================================

  /// 从相册选一张图。
  ///
  /// 返回 null 表示用户取消了，或权限被拒绝（后者会把提示写进
  /// [lastErrorMessage]）。
  static Future<XFile?> pickImageFromGallery() =>
      _pickImage(ImageSource.gallery);

  /// 拍照。
  static Future<XFile?> pickImageFromCamera() =>
      _pickImage(ImageSource.camera);

  static Future<XFile?> _pickImage(ImageSource source) async {
    // Web 端不需要权限，直接选文件；移动端先申请
    if (PlatformUtils.isMobile) {
      final permission = source == ImageSource.camera
          ? await PermissionUtils.requestCamera()
          : await PermissionUtils.requestGallery();
      if (!permission.isGranted) {
        lastErrorMessage = permission.message;
        return null;
      }
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        // 上传前先压一下，手机原图动辄 5-8MB，压到 1600px 足够做垫图
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (file == null) return null;

      final size = await file.length();
      if (size > maxImageBytes) {
        lastErrorMessage = '图片体积过大（${formatFileSize(size)}），请选择 10MB 以内的图片';
        return null;
      }

      lastErrorMessage = null;
      return file;
    } catch (e) {
      debugPrint('选择图片失败: $e');
      lastErrorMessage = '选择图片失败：$e';
      return null;
    }
  }

  /// 一次选多张（素材库批量上传用）。
  static Future<List<XFile>> pickMultipleImages({int limit = 9}) async {
    if (PlatformUtils.isMobile) {
      final permission = await PermissionUtils.requestGallery();
      if (!permission.isGranted) {
        lastErrorMessage = permission.message;
        return const [];
      }
    }

    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
        limit: limit,
      );
      lastErrorMessage = null;
      return files.take(limit).toList();
    } catch (e) {
      debugPrint('批量选择图片失败: $e');
      lastErrorMessage = '批量选择失败：$e';
      return const [];
    }
  }

  // ===========================================================================
  // 选择视频（图生视频的参考素材）
  // ===========================================================================

  static Future<XFile?> pickVideo() async {
    if (PlatformUtils.isMobile) {
      final permission = await PermissionUtils.requestGallery();
      if (!permission.isGranted) {
        lastErrorMessage = permission.message;
        return null;
      }
    }

    try {
      final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (file == null) return null;

      final size = await file.length();
      if (size > maxVideoBytes) {
        lastErrorMessage = '视频体积过大（${formatFileSize(size)}），请选择 100MB 以内的视频';
        return null;
      }

      lastErrorMessage = null;
      return file;
    } catch (e) {
      debugPrint('选择视频失败: $e');
      lastErrorMessage = '选择视频失败：$e';
      return null;
    }
  }

  // ===========================================================================
  // 读取字节流（上传前必经步骤）
  // ===========================================================================

  /// 读取为字节流。返回 null 表示读取失败。
  ///
  /// 这是 Web 与 Android 唯一可靠的共同表示，上传一定要走这里。
  static Future<Uint8List?> readBytes(XFile file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('读取文件字节失败: $e');
      lastErrorMessage = '读取文件失败：$e';
      return null;
    }
  }

  /// 取文件名，Web 上 [XFile.name] 是可靠的（path 不是）。
  static String fileNameOf(XFile file, {String fallback = 'upload.jpg'}) {
    final name = file.name;
    return name.isEmpty ? fallback : name;
  }

  // ===========================================================================
  // 下载 / 保存（待实现）
  // ===========================================================================

  /// 把生成的图片或视频保存到本地。
  ///
  /// **当前为占位实现，尚未接通。** 两端差异较大，单独排一个迭代：
  ///
  /// - **Web**：用 `package:web` + `dart:js_interop` 创建一个带 `download`
  ///   属性的 `<a>` 标签并触发 click。注意跨域资源要先 fetch 成 Blob，
  ///   否则 download 属性对跨域 URL 不生效。
  ///
  /// - **Android**：`dio.download` 存到临时目录，再用
  ///   `MediaStore`（Android 10+）或 `gal` 之类的插件写入相册；
  ///   注意 `path_provider` **不支持 Web**，必须用条件导入
  ///   （`if (dart.library.io)` / `if (dart.library.js_interop)`）拆成
  ///   两个文件，否则 `flutter build web` 会直接编译失败。
  ///
  /// 返回值：true 表示保存成功。
  static Future<bool> saveToLocal({
    required String url,
    required String filename,
    bool isVideo = false,
  }) async {
    debugPrint('saveToLocal 尚未实现: $url');
    lastErrorMessage = '保存到本地功能将在后续迭代实现';
    return false;
  }

  // ===========================================================================
  // 辅助方法
  // ===========================================================================

  /// 最近一次失败原因，供页面弹出 SnackBar。
  static String? lastErrorMessage;

  /// 把字节数格式化成易读的字符串。
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// 根据文件名判断是不是图片。
  static bool isImageFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  /// 根据文件名判断是不是视频。
  static bool isVideoFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }
}
