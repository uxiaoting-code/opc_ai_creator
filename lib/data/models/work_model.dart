import 'package:flutter/foundation.dart';

/// 作品类型，对应后端 `t_work.type`。
enum WorkType {
  image('IMAGE', '图片'),
  video('VIDEO', '视频');

  const WorkType(this.value, this.label);

  final String value;
  final String label;

  static WorkType fromValue(String? value) {
    return WorkType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => WorkType.image,
    );
  }
}

/// 作品模型，对应后端 `t_work` 表。
///
/// 与 AI 任务（`t_ai_task`）的区别：
/// 任务记录的是**执行过程**（排队/生成中/失败重试），作品记录的是**用户可见的成果**。
/// 任务可以删除或过期清理，作品要长期保留在画廊里。
@immutable
class WorkModel {
  const WorkModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.resourceUrl,
    this.taskId,
    this.title,
    this.coverUrl,
    this.prompt,
    this.negativePrompt,
    this.skillId,
    this.skillName,
    this.width,
    this.height,
    this.duration,
    this.isPublic = false,
    this.likeCount = 0,
    this.viewCount = 0,
    this.createdAt,
  });

  final int id;

  /// 作者 ID
  final int userId;

  /// 来源任务 ID
  final int? taskId;

  /// 作品标题
  final String? title;

  /// 作品类型：图片 / 视频
  final WorkType type;

  /// 封面图（视频取首帧）。为空时前端渲染渐变色占位
  final String? coverUrl;

  /// 作品资源地址（图片 URL 或视频 URL）
  final String resourceUrl;

  /// 生成用的提示词，作品详情页回显
  final String? prompt;
  final String? negativePrompt;

  /// 使用的 Skill 线路
  final int? skillId;

  /// 线路名称，列表展示用（后端联表带出，避免前端再查一次）
  final String? skillName;

  final int? width;
  final int? height;

  /// 视频时长（秒）
  final int? duration;

  /// 是否发布到公开画廊
  final bool isPublic;

  final int likeCount;
  final int viewCount;

  /// 创建时间
  final DateTime? createdAt;

  /// 列表展示用标题，缺省时回退到提示词首段。
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (prompt != null && prompt!.isNotEmpty) {
      return prompt!.length > 20 ? '${prompt!.substring(0, 20)}…' : prompt!;
    }
    return '未命名作品';
  }

  /// 是否视频作品（决定要不要叠播放角标）。
  bool get isVideo => type == WorkType.video;

  /// 视频时长文案，如 `00:12`。
  String? get durationLabel {
    if (duration == null) return null;
    final minutes = (duration! ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  factory WorkModel.fromJson(Map<String, dynamic> json) {
    return WorkModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      taskId: (json['taskId'] as num?)?.toInt(),
      title: json['title'] as String?,
      type: WorkType.fromValue(json['type'] as String?),
      coverUrl: json['coverUrl'] as String?,
      resourceUrl: json['resourceUrl'] as String? ?? '',
      prompt: json['prompt'] as String?,
      negativePrompt: json['negativePrompt'] as String?,
      skillId: (json['skillId'] as num?)?.toInt(),
      skillName: json['skillName'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      isPublic: json['isPublic'] as bool? ?? false,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'taskId': taskId,
        'title': title,
        'type': type.value,
        'coverUrl': coverUrl,
        'resourceUrl': resourceUrl,
        'prompt': prompt,
        'negativePrompt': negativePrompt,
        'skillId': skillId,
        'skillName': skillName,
        'width': width,
        'height': height,
        'duration': duration,
        'isPublic': isPublic,
        'likeCount': likeCount,
        'viewCount': viewCount,
        'createdAt': createdAt?.toIso8601String(),
      };

  /// 宽容解析时间：后端可能返回 ISO8601，也可能返回时间戳（毫秒）。
  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is WorkModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
