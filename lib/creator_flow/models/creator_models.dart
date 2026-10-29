import 'package:flutter/foundation.dart';

/// 当前工作台的创作类型。
enum CreationMode {
  image('图片生成', '文生图'),
  video('视频生成', '图生视频'),
  audio('音频生成', '文本转语音');

  const CreationMode(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}

/// 接单任务在用户侧的状态。
enum MarketOrderStatus {
  open('可接单'),
  accepted('制作中'),
  submitted('待审核'),
  approved('已完成'),
  rejected('需修改');

  const MarketOrderStatus(this.label);
  final String label;
}

/// 提交内容的审核状态。
enum ReviewStatus {
  pending('审核中'),
  approved('已通过'),
  rejected('未通过');

  const ReviewStatus(this.label);
  final String label;
}

/// 接单大厅里的订单。
@immutable
class MarketOrder {
  const MarketOrder({
    required this.id,
    required this.title,
    required this.brand,
    required this.description,
    required this.mode,
    required this.reward,
    required this.creditCost,
    required this.deadline,
    required this.tasksLeft,
    required this.requirements,
    this.status = MarketOrderStatus.open,
  });

  final String id;
  final String title;
  final String brand;
  final String description;
  final CreationMode mode;
  final double reward;
  final int creditCost;
  final String deadline;
  final int tasksLeft;
  final List<String> requirements;
  final MarketOrderStatus status;

  MarketOrder copyWith({MarketOrderStatus? status}) {
    return MarketOrder(
      id: id,
      title: title,
      brand: brand,
      description: description,
      mode: mode,
      reward: reward,
      creditCost: creditCost,
      deadline: deadline,
      tasksLeft: tasksLeft,
      requirements: requirements,
      status: status ?? this.status,
    );
  }
}

/// 用户在创作页生成但尚未提交的草稿。
@immutable
class GeneratedDraft {
  const GeneratedDraft({
    required this.mode,
    required this.prompt,
    required this.model,
    required this.createdAt,
    required this.artworkSeed,
    this.options = const {},
  });

  final CreationMode mode;
  final String prompt;
  final String model;
  final DateTime createdAt;
  final int artworkSeed;
  final Map<String, String> options;
}

/// 提交给订单方审核的作品。
@immutable
class SubmissionItem {
  const SubmissionItem({
    required this.id,
    required this.orderId,
    required this.orderTitle,
    required this.title,
    required this.mode,
    required this.prompt,
    required this.model,
    required this.reward,
    required this.createdAt,
    required this.artworkSeed,
    this.note = '',
    this.status = ReviewStatus.pending,
    this.reviewNote,
  });

  final String id;
  final String orderId;
  final String orderTitle;
  final String title;
  final CreationMode mode;
  final String prompt;
  final String model;
  final double reward;
  final DateTime createdAt;
  final int artworkSeed;
  final String note;
  final ReviewStatus status;
  final String? reviewNote;

  SubmissionItem copyWith({
    String? title,
    String? note,
    ReviewStatus? status,
    String? reviewNote,
  }) {
    return SubmissionItem(
      id: id,
      orderId: orderId,
      orderTitle: orderTitle,
      title: title ?? this.title,
      mode: mode,
      prompt: prompt,
      model: model,
      reward: reward,
      createdAt: createdAt,
      artworkSeed: artworkSeed,
      note: note ?? this.note,
      status: status ?? this.status,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }
}

enum WalletEntryType { recharge, consume, income, withdraw }

@immutable
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.createdAt,
    this.isCredit = false,
  });

  final String id;
  final WalletEntryType type;
  final String title;
  final double amount;
  final DateTime createdAt;
  final bool isCredit;
}
