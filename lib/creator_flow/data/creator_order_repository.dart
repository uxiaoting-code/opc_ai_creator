import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/creator_order.dart';

/// 接单成功后返回的关键信息。
class AcceptedOrderResult {
  const AcceptedOrderResult({
    required this.acceptanceId,
    this.recommendedMediaType,
  });

  final int acceptanceId;
  final OrderMediaType? recommendedMediaType;
}

/// 接单市场数据仓库，对应后端 `/api/orders/**`。
class CreatorOrderRepository {
  CreatorOrderRepository(this._api);

  final ApiClient _api;

  Future<PageResult<CreatorOrder>> fetchAvailable({
    OrderMediaType? mediaType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final raw = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.ordersAvailable,
      query: {
        'mediaType': ?mediaType?.value,
        'page': page,
        'pageSize': pageSize,
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (raw == null) return const PageResult.empty();
    return PageResult<CreatorOrder>.fromJson(
      raw,
      itemParser: CreatorOrder.fromJson,
    );
  }

  Future<CreatorOrderDetail> fetchDetail(int orderId) async {
    final raw = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.orderDetail(orderId),
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (raw == null) {
      throw const ApiException(message: '订单不存在或已被删除');
    }
    return CreatorOrderDetail.fromJson(raw);
  }

  Future<AcceptedOrderResult> accept(int orderId) async {
    final raw = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.orderAccept(orderId),
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (raw == null) {
      throw const ApiException(message: '接单失败，请稍后重试');
    }

    final acceptance = raw['acceptance'];
    final workbench = raw['workbench'];
    return AcceptedOrderResult(
      acceptanceId: acceptance is Map
          ? ((acceptance['id'] as num?)?.toInt() ?? 0)
          : 0,
      recommendedMediaType: workbench is Map
          ? OrderMediaType.fromValue(workbench['recommendedMediaType'] as String?)
          : null,
    );
  }
}
