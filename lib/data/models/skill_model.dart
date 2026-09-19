import 'package:flutter/foundation.dart';

/// Skill 线路适用类型。
///
/// 与后端 `t_skill.type` 字段取值一一对应，**字符串值不能改**，
/// 否则和前端的线上数据对不上。
enum SkillType {
  /// 文生图线路
  textToImage('TEXT_TO_IMAGE', '文生图', '文'),

  /// 图生视频线路
  imageToVideo('IMAGE_TO_VIDEO', '图生视频', '视');

  const SkillType(this.value, this.label, this.badge);

  /// 后端存储值
  final String value;

  /// 中文名
  final String label;

  /// 卡片角标用的单字
  final String badge;

  /// 从后端值解析，未知值兜底为文生图，避免脏数据导致页面崩溃。
  static SkillType fromValue(String? value) {
    return SkillType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => SkillType.textToImage,
    );
  }

  /// 该类型对应的创作页路由，首页点 Skill 卡片时直接跳这里。
  String get creationRoute => switch (this) {
        SkillType.textToImage => '/create/text-to-image',
        SkillType.imageToVideo => '/create/image-to-video',
      };
}

/// Skill 创作线路模型，对应后端 `t_skill` 表。
///
/// 一条 Skill = 一整套生成参数模板（模型、采样器、步数、提示词前后缀…）。
/// 用户切换线路即切换风格，新增线路只需往数据库插一行，**不用改前端代码**。
@immutable
class SkillModel {
  const SkillModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.coverUrl,
    this.description,
    this.scene,
    this.provider,
    this.modelName,
    this.steps,
    this.cfgScale,
    this.width,
    this.height,
    this.promptPrefix,
    this.promptSuffix,
    this.negativePrompt,
    this.usageCount = 0,
    this.favoriteCount = 0,
    this.tags = const [],
    this.status = 1,
  });

  final int id;

  /// 线路编码，如 `anime_v1`，全局唯一
  final String code;

  /// 线路名称，如「二次元插画」
  final String name;

  final SkillType type;

  /// 封面示例图。为空时前端渲染渐变色占位（见 CoverImage）
  final String? coverUrl;

  final String? description;

  /// 适用场景，如「头像 / 立绘」
  final String? scene;

  /// AI 服务商标识，对应后端 AiProvider 路由 key
  final String? provider;

  /// 模型名，如 `sd-xl-anime`
  final String? modelName;

  /// 采样步数
  final int? steps;

  /// 提示词引导强度
  final double? cfgScale;

  final int? width;
  final int? height;

  /// 提示词前缀，拼接在用户输入之前，保证风格稳定
  final String? promptPrefix;
  final String? promptSuffix;

  /// 默认负面提示词
  final String? negativePrompt;

  /// 被使用次数，用于市场热度排序
  final int usageCount;

  /// 被收藏次数
  final int favoriteCount;

  /// 标签
  final List<String> tags;

  /// 1 启用 / 0 下线
  final int status;

  /// 热度文案，如「1.2k」。
  String get usageLabel {
    if (usageCount >= 10000) {
      return '${(usageCount / 10000).toStringAsFixed(1)}w';
    }
    if (usageCount >= 1000) {
      return '${(usageCount / 1000).toStringAsFixed(1)}k';
    }
    return '$usageCount';
  }

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '未命名线路',
      type: SkillType.fromValue(json['type'] as String?),
      coverUrl: json['coverUrl'] as String?,
      description: json['description'] as String?,
      scene: json['scene'] as String?,
      provider: json['provider'] as String?,
      modelName: json['modelName'] as String?,
      steps: (json['steps'] as num?)?.toInt(),
      cfgScale: (json['cfgScale'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      promptPrefix: json['promptPrefix'] as String?,
      promptSuffix: json['promptSuffix'] as String?,
      negativePrompt: json['negativePrompt'] as String?,
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
      status: (json['status'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'type': type.value,
        'coverUrl': coverUrl,
        'description': description,
        'scene': scene,
        'provider': provider,
        'modelName': modelName,
        'steps': steps,
        'cfgScale': cfgScale,
        'width': width,
        'height': height,
        'promptPrefix': promptPrefix,
        'promptSuffix': promptSuffix,
        'negativePrompt': negativePrompt,
        'usageCount': usageCount,
        'favoriteCount': favoriteCount,
        'tags': tags,
        'status': status,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SkillModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
