import 'package:flutter/foundation.dart';

import 'creator_order.dart';

/// 作品审核状态，对应后端 `ReviewStatus`。
enum SubmissionReviewStatus {
  pending('PENDING', '审核中'),
  approved('APPROVED', '已通过'),
  rejected('REJECTED', '未通过');

  const SubmissionReviewStatus(this.value, this.label);

  final String value;
  final String label;

  static SubmissionReviewStatus fromValue(String? value) {
    return SubmissionReviewStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubmissionReviewStatus.pending,
    );
  }
}

/// 作品提交与审核状态，对应后端 `SubmissionResponse`。
@immutable
class CreatorSubmission {
  const CreatorSubmission({
    required this.id,
    required this.submissionNo,
    required this.orderId,
    required this.orderTitle,
    required this.acceptanceId,
    required this.taskId,
    required this.mediaType,
    required this.title,
    required this.status,
    required this.resultUrl,
    this.note = '',
    this.thumbnailUrl,
    this.durationMs,
    this.versionNo = 1,
    this.statusLabel,
    this.reviewNote,
    this.submittedAt,
    this.reviewedAt,
    this.rewardFen = 0,
  });

  final int id;
  final String submissionNo;
  final int orderId;
  final String orderTitle;
  final int acceptanceId;
  final int taskId;
  final OrderMediaType mediaType;
  final String title;
  final String note;
  final String resultUrl;
  final String? thumbnailUrl;
  final int? durationMs;
  final int versionNo;
  final SubmissionReviewStatus status;
  final String? statusLabel;
  final String? reviewNote;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int rewardFen;

  String get displayStatus => statusLabel ?? status.label;
  double get rewardYuan => rewardFen / 100;
  String get displayImageUrl =>
      (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
          ? thumbnailUrl!
          : resultUrl;

  factory CreatorSubmission.fromJson(Map<String, dynamic> json) {
    return CreatorSubmission(
      id: (json['id'] as num?)?.toInt() ?? 0,
      submissionNo: json['submissionNo'] as String? ?? '',
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderTitle: json['orderTitle'] as String? ?? '订单作品',
      acceptanceId: (json['acceptanceId'] as num?)?.toInt() ?? 0,
      taskId: (json['taskId'] as num?)?.toInt() ?? 0,
      mediaType: OrderMediaType.fromValue(json['mediaType'] as String?),
      title: json['title'] as String? ?? '未命名作品',
      note: json['note'] as String? ?? '',
      resultUrl: json['resultUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      versionNo: (json['versionNo'] as num?)?.toInt() ?? 1,
      status: SubmissionReviewStatus.fromValue(json['status'] as String?),
      statusLabel: json['statusLabel'] as String?,
      reviewNote: json['reviewNote'] as String?,
      submittedAt: _parseDate(json['submittedAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
      rewardFen: (json['rewardFen'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return null;
  }
}
