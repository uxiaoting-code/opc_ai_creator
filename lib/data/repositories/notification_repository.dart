import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../datasources/mock_data.dart';
import '../models/notification_model.dart';

/// 消息通知数据仓库。
///
/// 首页顶部「消息入口」的红点角标与消息列表用。
///
/// 后端接入后对应接口：
/// - `GET /api/notifications`        消息列表
/// - `GET /api/notifications/unread` 未读数（单独一个轻量接口，首页只关心数字）
class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  /// 拉取消息列表。
  Future<List<NotificationModel>> fetchNotifications({int limit = 20}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(MockData.latency);
      return MockData.notifications.take(limit).toList();
    }

    final list = await _api.get<List<Map<String, dynamic>>>(
      '/notifications',
      query: {'limit': limit},
      parser: (data) {
        if (data is! List) return const [];
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );
    return (list ?? const []).map(NotificationModel.fromJson).toList();
  }

  /// 只拉未读数，用于首页红点。
  ///
  /// 单独一个接口而不是复用列表接口，是为了让首页启动时少传数据。
  Future<int> fetchUnreadCount() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(MockData.latency);
      return MockData.unreadCount;
    }

    final count = await _api.get<int>(
      '/notifications/unread',
      parser: (data) => (data as num?)?.toInt() ?? 0,
    );
    return count ?? 0;
  }
}
