import 'package:flutter/foundation.dart';

/// 用户模型，对应后端 `t_user` 表。
///
/// 字段与数据库列一一对应，见 docs/ARCHITECTURE.md 的表设计。
@immutable
class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    this.nickname,
    this.avatar,
    this.email,
    this.phone,
    this.role,
    this.credits,
    this.createdAt,
  });

  /// 用户 ID（主键）
  final int id;

  /// 登录账号，唯一
  final String username;

  /// 昵称，展示用；为空时回退到 [username]
  final String? nickname;

  /// 头像 URL
  final String? avatar;

  final String? email;
  final String? phone;

  /// 角色：USER / ADMIN
  final String? role;

  /// 剩余算力点，创建 AI 任务时扣减
  final int? credits;

  /// 注册时间（ISO8601 字符串）
  final String? createdAt;

  /// 界面上显示的名字。
  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : username;

  /// 头像占位字符（没有头像时显示首字母）。
  String get avatarInitial =>
      displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();

  /// 是否是管理员。
  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      credits: (json['credits'] as num?)?.toInt(),
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'avatar': avatar,
        'email': email,
        'phone': phone,
        'role': role,
        'credits': credits,
        'createdAt': createdAt,
      };

  UserModel copyWith({
    int? id,
    String? username,
    String? nickname,
    String? avatar,
    String? email,
    String? phone,
    String? role,
    int? credits,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      credits: credits ?? this.credits,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
