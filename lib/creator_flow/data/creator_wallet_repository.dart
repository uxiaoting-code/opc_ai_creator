import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/creator_wallet.dart';

/// 用户钱包与个人统计数据源。
///
/// 所有金额都以整数分传递，页面不能自行拼接或计算最终余额。
class CreatorWalletRepository {
  CreatorWalletRepository(this._api);

  final ApiClient _api;

  Future<CreatorProfileStats> fetchProfileStats() async {
    final raw = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.profileStats,
      parser: _asMap,
    );
    if (raw == null) {
      throw const ApiException(message: '个人统计为空，请稍后重试');
    }
    return CreatorProfileStats.fromJson(raw);
  }

  Future<CreatorWalletSummary> fetchSummary() async {
    final raw = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.walletSummary,
      parser: _asMap,
    );
    if (raw == null) {
      throw const ApiException(message: '钱包信息为空，请稍后重试');
    }
    return CreatorWalletSummary.fromJson(raw);
  }

  Future<PageResult<CreatorWalletTransaction>> fetchTransactions({
    int page = 1,
    int pageSize = 10,
  }) async {
    final raw = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.walletTransactions,
      query: {'page': page, 'pageSize': pageSize},
      parser: _asMap,
    );
    if (raw == null) return const PageResult.empty();
    return PageResult<CreatorWalletTransaction>.fromJson(
      raw,
      itemParser: CreatorWalletTransaction.fromJson,
    );
  }

  Future<List<CreatorPaymentChannel>> fetchRechargeChannels() async {
    return _fetchChannels(ApiEndpoints.rechargeChannels);
  }

  Future<List<CreatorPaymentChannel>> fetchWithdrawChannels() async {
    return _fetchChannels(ApiEndpoints.withdrawChannels);
  }

  Future<CreatorRechargeOrder> createRecharge({
    required int amountFen,
    required String channelCode,
  }) async {
    final raw = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.recharges,
      body: {'amountFen': amountFen, 'channelCode': channelCode},
      parser: _asMap,
    );
    if (raw == null) {
      throw const ApiException(message: '充值订单创建失败，请稍后重试');
    }
    return CreatorRechargeOrder.fromJson(raw);
  }

  Future<CreatorRechargeOrder> fetchRecharge(int id) async {
    final raw = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.rechargeDetail(id),
      parser: _asMap,
    );
    if (raw == null) {
      throw const ApiException(message: '充值订单不存在');
    }
    return CreatorRechargeOrder.fromJson(raw);
  }

  Future<CreatorWithdrawal> createWithdrawal({
    required int amountFen,
    required String channelCode,
    required String accountName,
    required String accountNo,
  }) async {
    final raw = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.withdrawals,
      body: {
        'amountFen': amountFen,
        'channelCode': channelCode,
        'accountName': accountName,
        'accountNo': accountNo,
      },
      parser: _asMap,
    );
    if (raw == null) {
      throw const ApiException(message: '提现申请提交失败，请稍后重试');
    }
    return CreatorWithdrawal.fromJson(raw);
  }

  Future<CreatorWithdrawal> fetchWithdrawal(int id) async {
    final raw = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.withdrawalDetail(id),
      parser: _asMap,
    );
    if (raw == null) {
      throw const ApiException(message: '提现申请不存在');
    }
    return CreatorWithdrawal.fromJson(raw);
  }

  Future<List<CreatorPaymentChannel>> _fetchChannels(String path) async {
    final raw = await _api.get<List<CreatorPaymentChannel>>(
      path,
      parser: (data) {
        if (data is! List) return const [];
        return data
            .whereType<Map>()
            .map(
              (item) => CreatorPaymentChannel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      },
    );
    return raw ?? const [];
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is! Map) {
      throw const FormatException('接口返回的数据不是对象');
    }
    return Map<String, dynamic>.from(data);
  }
}
