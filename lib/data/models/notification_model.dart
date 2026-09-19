import 'package:flutter/foundation.dart';

/// 系统通知 / 消息模型。
///
/// 首页顶部「消息入口」的红点与列表用。
/// 后端接入后对应一张 `t_notification` 表（本轮暂未建表，先由 Repository 返回）。
@immutable
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  final int id;
  final String title;
  final String content;

  /// 消息类型：TASK（任务状态变更）/ SYSTEM（系统公告）/ ACTIVITY（活动）
  final String type;

  final DateTime createdAt;
  final bool isRead;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'SYSTEM',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
