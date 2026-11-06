import 'package:flutter/foundation.dart';

/// 订单媒体类型，对应后端 `MediaType` 枚举。
enum OrderMediaType {
  image('IMAGE', '图片'),
  video('VIDEO', '视频'),
  audio('AUDIO', '音频');

  const OrderMediaType(this.value, this.label);

  final String value;
  final String label;

  static OrderMediaType fromValue(String? value) {
    return OrderMediaType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => OrderMediaType.image,
    );
  }
}

/// 订单公共状态，对应后端 `MarketOrderStatus`。
enum OrderStatus {
  open('OPEN', '可接单'),
  closed('CLOSED', '已关闭'),
  completed('COMPLETED', '已结束');

  const OrderStatus(this.value, this.label);

  final String value;
  final String label;

  static OrderStatus fromValue(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.open,
    );
  }
}

/// 接单市场订单，对应后端 `MarketOrderResponse`。
@immutable
class CreatorOrder {
  const CreatorOrder({
    required this.id,
    required this.orderNo,
    required this.title,
    required this.brandName,
    required this.description,
    required this.mediaType,
    required this.rewardFen,
    required this.creditCost,
    required this.deadlineAt,
    required this.tasksTotal,
    required this.tasksTaken,
    required this.requirements,
    required this.status,
    this.myAcceptanceStatus,
    this.createdAt,
  });

  final int id;
  final String orderNo;
  final String title;
  final String brandName;
  final String description;
  final OrderMediaType mediaType;
  final int rewardFen;
  final int creditCost;
  final DateTime? deadlineAt;
  final int tasksTotal;
  final int tasksTaken;
  final List<String> requirements;
  final OrderStatus status;
  final String? myAcceptanceStatus;
  final DateTime? createdAt;

  double get rewardYuan => rewardFen / 100;

  int get tasksLeft => (tasksTotal - tasksTaken).clamp(0, tasksTotal);

  bool get hasQuota => tasksLeft > 0 && status == OrderStatus.open;

  factory CreatorOrder.fromJson(Map<String, dynamic> json) {
    return CreatorOrder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNo: json['orderNo'] as String? ?? '',
      title: json['title'] as String? ?? '未命名订单',
      brandName: json['brandName'] as String? ?? '未知需求方',
      description: json['description'] as String? ?? '',
      mediaType: OrderMediaType.fromValue(json['mediaType'] as String?),
      rewardFen: (json['rewardFen'] as num?)?.toInt() ?? 0,
      creditCost: (json['creditCost'] as num?)?.toInt() ?? 0,
      deadlineAt: _parseDate(json['deadlineAt']),
      tasksTotal: (json['tasksTotal'] as num?)?.toInt() ?? 0,
      tasksTaken: (json['tasksTaken'] as num?)?.toInt() ?? 0,
      requirements: (json['requirements'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      status: OrderStatus.fromValue(json['status'] as String?),
      myAcceptanceStatus: json['myAcceptanceStatus'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return null;
  }
}

/// 订单详情，对应后端 `OrderDetailResponse`。
@immutable
class CreatorOrderDetail {
  const CreatorOrderDetail({
    required this.order,
    required this.canAccept,
    this.myAcceptance,
    this.unavailableReason,
  });

  final CreatorOrder order;
  final bool canAccept;
  final Map<String, dynamic>? myAcceptance;
  final String? unavailableReason;

  factory CreatorOrderDetail.fromJson(Map<String, dynamic> json) {
    final orderJson = json['order'];
    return CreatorOrderDetail(
      order: orderJson is Map
          ? CreatorOrder.fromJson(Map<String, dynamic>.from(orderJson))
          : CreatorOrder.fromJson(const {}),
      canAccept: json['canAccept'] as bool? ?? false,
      myAcceptance: json['myAcceptance'] is Map
          ? Map<String, dynamic>.from(json['myAcceptance'] as Map)
          : null,
      unavailableReason: json['unavailableReason'] as String?,
    );
  }
}

/// 从订单详情“去创作”时传给创作页的参数。
@immutable
class CreatorCreationArgs {
  const CreatorCreationArgs({this.prompt = '', this.orderId});

  final String prompt;
  final int? orderId;
}

/// 后端返回的当前工作动作。
enum CreatorWorkAction {
  continueCreate('CONTINUE_CREATE'),
  resubmit('RESUBMIT'),
  viewReview('VIEW_REVIEW'),
  viewResult('VIEW_RESULT'),
  none('NONE');

  const CreatorWorkAction(this.value);

  final String value;

  static CreatorWorkAction fromValue(String? value) {
    return CreatorWorkAction.values.firstWhere(
      (action) => action.value == value,
      orElse: () => CreatorWorkAction.none,
    );
  }
}

/// 当前用户工作上下文，对应 `/api/orders/my/current`。
@immutable
class CreatorWorkContext {
  const CreatorWorkContext({
    required this.hasActiveWork,
    required this.action,
    required this.canGenerate,
    required this.canSubmit,
    required this.canAcceptNew,
    this.order,
    this.acceptance,
    this.latestSubmission,
    this.reason,
  });

  final bool hasActiveWork;
  final CreatorOrder? order;
  final Map<String, dynamic>? acceptance;
  final Map<String, dynamic>? latestSubmission;
  final CreatorWorkAction action;
  final bool canGenerate;
  final bool canSubmit;
  final bool canAcceptNew;
  final String? reason;

  String? get acceptanceStatus => acceptance?['status'] as String?;

  int? get latestSubmissionId =>
      (latestSubmission?['id'] as num?)?.toInt();

  factory CreatorWorkContext.fromJson(Map<String, dynamic> json) {
    final orderJson = json['order'];
    final acceptanceJson = json['acceptance'];
    final submissionJson = json['latestSubmission'];
    return CreatorWorkContext(
      hasActiveWork: json['hasActiveWork'] as bool? ?? false,
      order: orderJson is Map
          ? CreatorOrder.fromJson(Map<String, dynamic>.from(orderJson))
          : null,
      acceptance: acceptanceJson is Map
          ? Map<String, dynamic>.from(acceptanceJson)
          : null,
      latestSubmission: submissionJson is Map
          ? Map<String, dynamic>.from(submissionJson)
          : null,
      action: CreatorWorkAction.fromValue(json['action'] as String?),
      canGenerate: json['canGenerate'] as bool? ?? false,
      canSubmit: json['canSubmit'] as bool? ?? false,
      canAcceptNew: json['canAcceptNew'] as bool? ?? true,
      reason: json['reason'] as String?,
    );
  }
}
