import 'package:flutter/foundation.dart';

/// Harness 任务状态，与后端 `TaskStatus` 枚举取值一一对应。
///
/// **字符串值不能改**：后端 `t_ai_task.status` 存的就是这些枚举名
/// (`TaskStatus.name()`)，改了前端会一个状态都认不出来。
enum TaskStatus {
  queued('QUEUED', '排队中'),
  running('RUNNING', '生成中'),
  success('SUCCESS', '成功'),
  failed('FAILED', '失败'),
  canceled('CANCELED', '已取消');

  const TaskStatus(this.value, this.label);

  /// 后端存储值
  final String value;

  /// 中文名。页面优先用后端返回的 `statusLabel`，
  /// 这里的 label 只是前端兜底（接口漏字段时不至于显示空白）。
  final String label;

  /// 从后端值解析。未知值兜底成「排队中」，
  /// 这样即使后端将来加了新状态，页面也只是停在这一态而不是崩溃。
  static TaskStatus fromValue(String? value) {
    return TaskStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => TaskStatus.queued,
    );
  }

  /// 是否终态 —— **决定前端要不要停止轮询**。
  ///
  /// 与后端 `TaskStatus.isTerminal()` 严格对齐，注意两点：
  /// - `FAILED` 也是终态：失败的任务不会自己变好，必须用户手动点「重试」才回到 QUEUED；
  /// - 判定规则只有后端一份，前端不要自己另写一套，否则两端迟早不一致。
  bool get isTerminal => this == success || this == canceled || this == failed;

  /// 是否仍在进行中，决定要不要继续转圈 / 显示进度条。
  bool get isActive => !isTerminal;
}

/// 任务类型，对应后端 `t_ai_task.type`。
enum TaskType {
  textToImage('TEXT_TO_IMAGE', '文生图'),
  imageToVideo('IMAGE_TO_VIDEO', '图生视频');

  const TaskType(this.value, this.label);

  final String value;
  final String label;

  static TaskType fromValue(String? value) {
    return TaskType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TaskType.textToImage,
    );
  }

  /// 任务产出的是视频还是图片，决定详情页用图片预览还是播放器。
  bool get isVideo => this == TaskType.imageToVideo;
}

/// AI 生成任务模型，对应后端 `t_ai_task` 表 / `TaskResponse`。
///
/// 与 [WorkModel]（作品）的区别：
/// 任务记录的是**执行过程**（排队 / 生成中 / 失败重试 / 耗时），
/// 作品记录的是**用户可见的成果**。任务可以失败、可以重试、可以取消，
/// 作品只在任务成功时产生一条，并且要长期留在画廊里。
///
/// 字段与后端 `TaskResponse` 一一对应 —— 后端顺手多给了
/// `statusLabel` / `canRetry` / `canCancel` / `finished` 这几个派生字段，
/// 就是为了让前端不用把状态机规则再实现一遍。
@immutable
class TaskModel {
  const TaskModel({
    required this.id,
    required this.taskNo,
    required this.type,
    required this.status,
    this.typeLabel,
    this.skillId,
    this.skillName,
    this.skillCode,
    this.prompt,
    this.negativePrompt,
    this.refImageUrl,
    this.statusLabel,
    this.progress = 0,
    this.resultUrl,
    this.resultThumb,
    this.errorMsg,
    this.provider,
    this.retryCount = 0,
    this.maxRetry = 3,
    this.canRetry = false,
    this.canCancel = false,
    this.finished = false,
    this.queueAt,
    this.startAt,
    this.finishAt,
    this.durationMs,
    this.createdAt,
  });

  final int id;

  /// 任务编号（UUID），对外展示用，避免暴露自增 ID
  final String taskNo;

  final TaskType type;

  /// 类型中文名（后端给）
  final String? typeLabel;

  /// 使用的 Skill 线路
  final int? skillId;

  /// 线路名称，后端联表带出，前端不用再查一次
  final String? skillName;

  final String? skillCode;

  /// 最终提示词（后端已拼上线路的风格前缀 / 后缀）
  final String? prompt;

  final String? negativePrompt;

  /// 参考图 / 首帧图（图生视频用）
  final String? refImageUrl;

  final TaskStatus status;

  /// 状态中文名（后端给）
  final String? statusLabel;

  /// 进度 0~100
  final int progress;

  /// 生成结果地址（图片或视频）
  final String? resultUrl;

  /// 结果缩略图。Mock 不生成缩略图，此时等于 resultUrl
  final String? resultThumb;

  /// 失败原因，直接展示给用户
  final String? errorMsg;

  /// 实际执行的服务商标识
  final String? provider;

  final int retryCount;
  final int maxRetry;

  /// 后端判定的是否可重试 / 可取消，前端直接用，不要自己算
  final bool canRetry;
  final bool canCancel;

  /// 是否已结束（等于 status 是否终态）
  final bool finished;

  final DateTime? queueAt;
  final DateTime? startAt;
  final DateTime? finishAt;

  /// 总耗时（毫秒），任务结束后由后端算好
  final int? durationMs;

  final DateTime? createdAt;

  /// 状态展示文案：优先用后端给的，缺失时回退到本地枚举。
  String get displayStatusLabel => statusLabel ?? status.label;

  /// 进度条用的 0~1 比值（夹紧，防止后端偶发返回越界值把进度条画崩）。
  double get progressRatio => (progress.clamp(0, 100)) / 100;

  /// 是否已有可展示的结果图。
  bool get hasResult => resultUrl != null && resultUrl!.isNotEmpty;

  /// 详情页优先展示的大图地址（缩略图缺失时回退到原图）。
  String? get displayImageUrl {
    if (hasResult) return resultUrl;
    return (resultThumb != null && resultThumb!.isNotEmpty) ? resultThumb : null;
  }

  /// 耗时文案，如 `3.2s` / `1m24s`。
  String? get durationLabel {
    final ms = durationMs;
    if (ms == null || ms <= 0) return null;
    if (ms < 1000) return '${ms}ms';
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final minutes = ms ~/ 60000;
    final rest = (ms % 60000) ~/ 1000;
    return '${minutes}m${rest}s';
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      taskNo: json['taskNo'] as String? ?? '',
      type: TaskType.fromValue(json['type'] as String?),
      typeLabel: json['typeLabel'] as String?,
      skillId: (json['skillId'] as num?)?.toInt(),
      skillName: json['skillName'] as String?,
      skillCode: json['skillCode'] as String?,
      prompt: json['prompt'] as String?,
      negativePrompt: json['negativePrompt'] as String?,
      refImageUrl: json['refImageUrl'] as String?,
      status: TaskStatus.fromValue(json['status'] as String?),
      statusLabel: json['statusLabel'] as String?,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      resultUrl: json['resultUrl'] as String?,
      resultThumb: json['resultThumb'] as String?,
      errorMsg: json['errorMsg'] as String?,
      provider: json['provider'] as String?,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      maxRetry: (json['maxRetry'] as num?)?.toInt() ?? 3,
      canRetry: json['canRetry'] as bool? ?? false,
      canCancel: json['canCancel'] as bool? ?? false,
      finished: json['finished'] as bool? ?? false,
      queueAt: _parseDate(json['queueAt']),
      startAt: _parseDate(json['startAt']),
      finishAt: _parseDate(json['finishAt']),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskNo': taskNo,
        'type': type.value,
        'typeLabel': typeLabel,
        'skillId': skillId,
        'skillName': skillName,
        'skillCode': skillCode,
        'prompt': prompt,
        'negativePrompt': negativePrompt,
        'refImageUrl': refImageUrl,
        'status': status.value,
        'statusLabel': statusLabel,
        'progress': progress,
        'resultUrl': resultUrl,
        'resultThumb': resultThumb,
        'errorMsg': errorMsg,
        'provider': provider,
        'retryCount': retryCount,
        'maxRetry': maxRetry,
        'canRetry': canRetry,
        'canCancel': canCancel,
        'finished': finished,
        'queueAt': queueAt?.toIso8601String(),
        'startAt': startAt?.toIso8601String(),
        'finishAt': finishAt?.toIso8601String(),
        'durationMs': durationMs,
        'createdAt': createdAt?.toIso8601String(),
      };

  /// 宽容解析时间：后端返回 ISO8601 字符串（application.yml 里关掉了时间戳数组），
  /// 但也兼容时间戳，避免配置被改回去后整页崩掉。
  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TaskModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
