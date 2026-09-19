import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

/// 消息通知状态管理。
///
/// 首页顶部「消息入口」的红点角标与消息弹层用。
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required this._repository});

  final NotificationRepository _repository;

  List<NotificationModel> _notifications = const [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;

  /// 未读数量，决定红点是否显示。
  int get unreadCount => _unreadCount;

  bool get hasUnread => _unreadCount > 0;

  bool get isLoading => _isLoading;

  String? get error => _error;

  /// 角标文案：超过 99 显示 99+，避免把顶部栏撑开。
  String get badgeLabel => _unreadCount > 99 ? '99+' : '$_unreadCount';

  Future<void> loadIfNeeded() async {
    if (_notifications.isNotEmpty || _isLoading) return;
    await load();
  }

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _notifications.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 列表和未读数一起拉，两个请求并发，减少等待
      final results = await Future.wait([
        _repository.fetchNotifications(),
        _repository.fetchUnreadCount(),
      ]);
      _notifications = results[0] as List<NotificationModel>;
      _unreadCount = results[1] as int;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '加载消息失败：$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);

  /// 本地标记全部已读。
  ///
  /// 后端接入后这里还要调 `POST /api/notifications/read-all`，
  /// 目前先做本地状态更新，保证交互是通的。
  void markAllRead() {
    if (_unreadCount == 0) return;
    _notifications = _notifications
        .map((n) => NotificationModel(
              id: n.id,
              title: n.title,
              content: n.content,
              type: n.type,
              createdAt: n.createdAt,
              isRead: true,
            ))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }
}
