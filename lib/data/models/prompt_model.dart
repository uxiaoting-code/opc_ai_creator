import 'package:flutter/foundation.dart';

/// Prompt 知识库条目，对应后端 `PromptResponse`。
@immutable
class PromptModel {
  const PromptModel({
    required this.id,
    required this.title,
    required this.content,
    this.userId,
    this.negativeContent,
    this.category,
    this.tags = '',
    this.coverUrl,
    this.favoriteCount = 0,
    this.useCount = 0,
    this.isPublic = true,
    this.favorited = false,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int? userId;
  final String title;
  final String content;
  final String? negativeContent;
  final String? category;
  final String tags;
  final String? coverUrl;
  final int favoriteCount;
  final int useCount;
  final bool isPublic;
  final bool favorited;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<String> get tagList => tags
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);

  PromptModel copyWith({int? favoriteCount, bool? favorited}) {
    return PromptModel(
      id: id,
      userId: userId,
      title: title,
      content: content,
      negativeContent: negativeContent,
      category: category,
      tags: tags,
      coverUrl: coverUrl,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      useCount: useCount,
      isPublic: isPublic,
      favorited: favorited ?? this.favorited,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory PromptModel.fromJson(Map<String, dynamic> json) {
    return PromptModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt(),
      title: json['title'] as String? ?? '未命名 Prompt',
      content: json['content'] as String? ?? '',
      negativeContent: json['negativeContent'] as String?,
      category: json['category'] as String?,
      tags: json['tags'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
      isPublic: _parseBool(json['isPublic'], fallback: true),
      favorited: _parseBool(json['favorited'], fallback: false),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'content': content,
    'negativeContent': negativeContent,
    'category': category,
    'tags': tags,
    'coverUrl': coverUrl,
    'favoriteCount': favoriteCount,
    'useCount': useCount,
    'isPublic': isPublic,
    'favorited': favorited,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static bool _parseBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return fallback;
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PromptModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
