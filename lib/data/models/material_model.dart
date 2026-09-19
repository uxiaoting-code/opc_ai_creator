import 'package:flutter/foundation.dart';

/// 素材模型，对应后端 `t_material` 表 / `MaterialResponse`。
///
/// 字段名与后端 `MaterialResponse` 严格对齐。
@immutable
class MaterialModel {
  const MaterialModel({
    required this.id,
    required this.name,
    required this.url,
    this.thumbUrl,
    this.fileSize,
    this.mimeType,
    this.width,
    this.height,
    this.createdAt,
  });

  final int id;

  /// 素材名（一般是上传时的原始文件名）
  final String name;

  /// 访问地址。**后端返回的是 `/upload/xxx.png` 这种相对路径**，
  /// 要拿去显示必须先过一遍 `AppConfig.resolveAssetUrl`；
  /// 但要回传给后端当 `refImageUrl` 时必须用原始相对路径，别拼。
  final String url;

  final String? thumbUrl;
  final int? fileSize;
  final String? mimeType;
  final int? width;
  final int? height;
  final DateTime? createdAt;

  /// 展示用名称，为空时兜底。
  String get displayName => name.isEmpty ? '未命名素材' : name;

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      thumbUrl: json['thumbUrl'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'thumbUrl': thumbUrl,
        'fileSize': fileSize,
        'mimeType': mimeType,
        'width': width,
        'height': height,
        'createdAt': createdAt?.toIso8601String(),
      };

  /// 宽容解析时间：后端返回 ISO8601 字符串，也兼容时间戳。
  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MaterialModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
