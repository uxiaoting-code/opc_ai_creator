import 'package:flutter/foundation.dart';

/// 把后端金额（分）格式化为两位小数。
///
/// 金额计算全程使用整数分，只有最终展示时才转换成字符串。
String formatFen(int fen) {
  final sign = fen < 0 ? '-' : '';
  final absolute = fen.abs();
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '$sign${absolute ~/ 100}.$fraction';
}

/// 把用户输入的元金额解析成整数分。
///
/// 不接受负数、科学计数法或超过两位的小数，避免 double 精度和金额歧义。
int? parseYuanToFen(String raw) {
  final value = raw.trim();
  if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(value)) return null;

  final parts = value.split('.');
  final yuan = int.tryParse(parts[0]);
  if (yuan == null) return null;
  final fractionText = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
  final fraction = int.tryParse(fractionText);
  if (fraction == null) return null;
  return yuan * 100 + fraction;
}

DateTime? parseWalletDate(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  return null;
}

/// 个人中心统一统计，对应 `GET /api/profile/stats`。
@immutable
class CreatorProfileStats {
  const CreatorProfileStats({
    required this.credits,
    required this.withdrawableFen,
    required this.frozenFen,
    required this.totalIncomeFen,
    required this.totalWithdrawnFen,
    required this.pendingReviewCount,
    required this.approvedReviewCount,
    required this.rejectedReviewCount,
    required this.taskStats,
  });

  final int credits;
  final int withdrawableFen;
  final int frozenFen;
  final int totalIncomeFen;
  final int totalWithdrawnFen;
  final int pendingReviewCount;
  final int approvedReviewCount;
  final int rejectedReviewCount;
  final Map<String, int> taskStats;

  factory CreatorProfileStats.fromJson(Map<String, dynamic> json) {
    final rawTaskStats = json['taskStats'];
    return CreatorProfileStats(
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      withdrawableFen: (json['withdrawableFen'] as num?)?.toInt() ?? 0,
      frozenFen: (json['frozenFen'] as num?)?.toInt() ?? 0,
      totalIncomeFen: (json['totalIncomeFen'] as num?)?.toInt() ?? 0,
      totalWithdrawnFen: (json['totalWithdrawnFen'] as num?)?.toInt() ?? 0,
      pendingReviewCount: (json['pendingReviewCount'] as num?)?.toInt() ?? 0,
      approvedReviewCount: (json['approvedReviewCount'] as num?)?.toInt() ?? 0,
      rejectedReviewCount: (json['rejectedReviewCount'] as num?)?.toInt() ?? 0,
      taskStats: rawTaskStats is Map
          ? {
              for (final entry in rawTaskStats.entries)
                entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
            }
          : const {},
    );
  }
}

/// 钱包汇总，对应 `GET /api/wallet/summary`。
@immutable
class CreatorWalletSummary {
  const CreatorWalletSummary({
    required this.withdrawableFen,
    required this.frozenFen,
    required this.totalIncomeFen,
    required this.totalWithdrawnFen,
    required this.credits,
  });

  final int withdrawableFen;
  final int frozenFen;
  final int totalIncomeFen;
  final int totalWithdrawnFen;
  final int credits;

  factory CreatorWalletSummary.fromJson(Map<String, dynamic> json) {
    return CreatorWalletSummary(
      withdrawableFen: (json['withdrawableFen'] as num?)?.toInt() ?? 0,
      frozenFen: (json['frozenFen'] as num?)?.toInt() ?? 0,
      totalIncomeFen: (json['totalIncomeFen'] as num?)?.toInt() ?? 0,
      totalWithdrawnFen: (json['totalWithdrawnFen'] as num?)?.toInt() ?? 0,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
    );
  }
}

enum WalletTransactionKind {
  orderIncome('ORDER_INCOME', '订单收入'),
  withdrawFreeze('WITHDRAW_FREEZE', '提现冻结'),
  withdrawSuccess('WITHDRAW_SUCCESS', '提现成功'),
  withdrawRefund('WITHDRAW_REFUND', '提现退回'),
  manualAdjust('MANUAL_ADJUST', '人工调整'),
  unknown('UNKNOWN', '钱包变动');

  const WalletTransactionKind(this.value, this.label);

  final String value;
  final String label;

  static WalletTransactionKind fromValue(String? value) {
    return WalletTransactionKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => WalletTransactionKind.unknown,
    );
  }
}

/// 现金钱包流水，对应 `GET /api/wallet/transactions`。
@immutable
class CreatorWalletTransaction {
  const CreatorWalletTransaction({
    required this.id,
    required this.transactionNo,
    required this.kind,
    required this.typeLabel,
    required this.amountFen,
    required this.balanceAfterFen,
    required this.description,
    this.referenceType,
    this.referenceId,
    this.createdAt,
  });

  final int id;
  final String transactionNo;
  final WalletTransactionKind kind;
  final String typeLabel;
  final int amountFen;
  final int balanceAfterFen;
  final String description;
  final String? referenceType;
  final int? referenceId;
  final DateTime? createdAt;

  /// 展示用的现金方向。提现冻结和提现成功都代表资金离开展现余额。
  int get displayDeltaFen {
    return switch (kind) {
      WalletTransactionKind.withdrawFreeze ||
      WalletTransactionKind.withdrawSuccess => -amountFen.abs(),
      WalletTransactionKind.orderIncome ||
      WalletTransactionKind.withdrawRefund => amountFen.abs(),
      WalletTransactionKind.manualAdjust ||
      WalletTransactionKind.unknown => amountFen,
    };
  }

  factory CreatorWalletTransaction.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    final kind = WalletTransactionKind.fromValue(rawType);
    return CreatorWalletTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      transactionNo: json['transactionNo'] as String? ?? '',
      kind: kind,
      typeLabel: json['typeLabel'] as String? ?? kind.label,
      amountFen: (json['amountFen'] as num?)?.toInt() ?? 0,
      balanceAfterFen: (json['balanceAfterFen'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '钱包变动',
      referenceType: json['referenceType'] as String?,
      referenceId: (json['referenceId'] as num?)?.toInt(),
      createdAt: parseWalletDate(json['createdAt']),
    );
  }
}

/// 支付/提现渠道，对应 `PaymentChannelResponse`。
@immutable
class CreatorPaymentChannel {
  const CreatorPaymentChannel({
    required this.code,
    required this.name,
    required this.direction,
    required this.enabled,
    required this.minFen,
    required this.maxFen,
    required this.feeRateBps,
    required this.sortOrder,
    this.icon,
  });

  final String code;
  final String name;
  final String direction;
  final String? icon;
  final bool enabled;
  final int minFen;
  final int maxFen;
  final int feeRateBps;
  final int sortOrder;

  bool supportsAmount(int amountFen) {
    return enabled && amountFen >= minFen && amountFen <= maxFen;
  }

  factory CreatorPaymentChannel.fromJson(Map<String, dynamic> json) {
    return CreatorPaymentChannel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '支付渠道',
      direction: json['direction'] as String? ?? '',
      icon: json['icon'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      minFen: (json['minFen'] as num?)?.toInt() ?? 0,
      maxFen: (json['maxFen'] as num?)?.toInt() ?? 0,
      feeRateBps: (json['feeRateBps'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

enum CreatorRechargeStatus {
  pending('PENDING', '待支付'),
  paid('PAID', '已支付'),
  failed('FAILED', '支付失败'),
  closed('CLOSED', '已关闭'),
  refunded('REFUNDED', '已退款');

  const CreatorRechargeStatus(this.value, this.label);

  final String value;
  final String label;

  bool get isTerminal => this != pending;

  static CreatorRechargeStatus fromValue(String? value) {
    return CreatorRechargeStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CreatorRechargeStatus.pending,
    );
  }
}

/// 充值订单，对应 `RechargeOrderResponse`。
@immutable
class CreatorRechargeOrder {
  const CreatorRechargeOrder({
    required this.id,
    required this.rechargeNo,
    required this.amountFen,
    required this.credits,
    required this.channelCode,
    required this.status,
    required this.statusLabel,
    required this.payUrl,
    this.createdAt,
    this.paidAt,
  });

  final int id;
  final String rechargeNo;
  final int amountFen;
  final int credits;
  final String channelCode;
  final CreatorRechargeStatus status;
  final String statusLabel;
  final String? payUrl;
  final DateTime? createdAt;
  final DateTime? paidAt;

  factory CreatorRechargeOrder.fromJson(Map<String, dynamic> json) {
    final status = CreatorRechargeStatus.fromValue(json['status'] as String?);
    return CreatorRechargeOrder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rechargeNo: json['rechargeNo'] as String? ?? '',
      amountFen: (json['amountFen'] as num?)?.toInt() ?? 0,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      channelCode: json['channelCode'] as String? ?? '',
      status: status,
      statusLabel: json['statusLabel'] as String? ?? status.label,
      payUrl: json['payUrl'] as String?,
      createdAt: parseWalletDate(json['createdAt']),
      paidAt: parseWalletDate(json['paidAt']),
    );
  }
}

enum CreatorWithdrawStatus {
  pending('PENDING', '待处理'),
  processing('PROCESSING', '处理中'),
  success('SUCCESS', '已到账'),
  failed('FAILED', '提现失败'),
  cancelled('CANCELLED', '已取消');

  const CreatorWithdrawStatus(this.value, this.label);

  final String value;
  final String label;

  bool get isTerminal => this != pending && this != processing;

  static CreatorWithdrawStatus fromValue(String? value) {
    return CreatorWithdrawStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CreatorWithdrawStatus.pending,
    );
  }
}

/// 提现申请，对应 `WithdrawRequestResponse`。
@immutable
class CreatorWithdrawal {
  const CreatorWithdrawal({
    required this.id,
    required this.withdrawNo,
    required this.amountFen,
    required this.channelCode,
    required this.accountName,
    required this.accountNoMasked,
    required this.status,
    required this.statusLabel,
    this.failureReason,
    this.createdAt,
    this.processedAt,
  });

  final int id;
  final String withdrawNo;
  final int amountFen;
  final String channelCode;
  final String accountName;
  final String accountNoMasked;
  final CreatorWithdrawStatus status;
  final String statusLabel;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? processedAt;

  factory CreatorWithdrawal.fromJson(Map<String, dynamic> json) {
    final status = CreatorWithdrawStatus.fromValue(json['status'] as String?);
    return CreatorWithdrawal(
      id: (json['id'] as num?)?.toInt() ?? 0,
      withdrawNo: json['withdrawNo'] as String? ?? '',
      amountFen: (json['amountFen'] as num?)?.toInt() ?? 0,
      channelCode: json['channelCode'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      accountNoMasked: json['accountNoMasked'] as String? ?? '',
      status: status,
      statusLabel: json['statusLabel'] as String? ?? status.label,
      failureReason: json['failureReason'] as String?,
      createdAt: parseWalletDate(json['createdAt']),
      processedAt: parseWalletDate(json['processedAt']),
    );
  }
}
