import 'package:flutter/foundation.dart';

/// 用户端可选择的真实模型通道。
///
/// 这里只包含展示和选择需要的公开字段；Base URL、API Key 和请求模板
/// 永远只留在服务端。
@immutable
class CreatorModel {
  const CreatorModel({
    required this.id,
    required this.name,
    required this.type,
    this.vendor,
    this.typeLabel,
    this.modelName,
  });

  final int id;
  final String name;
  final String? vendor;
  final String type;
  final String? typeLabel;
  final String? modelName;

  factory CreatorModel.fromJson(Map<String, dynamic> json) {
    return CreatorModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '未命名模型',
      vendor: json['vendor'] as String?,
      type: json['type'] as String? ?? '',
      typeLabel: json['typeLabel'] as String?,
      modelName: json['modelName'] as String?,
    );
  }
}
