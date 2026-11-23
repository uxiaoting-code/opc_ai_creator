import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/network/api_response.dart';
import '../providers/auth_provider.dart';
import 'data/creator_wallet_repository.dart';
import 'models/creator_wallet.dart';

/// 个人中心与钱包的统一页面状态。
///
/// 数据按登录用户隔离；退出或切换账号时会立即清空，避免短暂显示上一个
/// 用户的余额。页面只读取此 Provider，不再直接接触演示钱包数据。
class CreatorWalletProvider extends ChangeNotifier {
  CreatorWalletProvider(this._repository, {required AuthProvider auth})
    : _auth = auth,
      _boundUserId = auth.user?.id {
    _auth.addListener(_handleAuthChanged);
  }

  final CreatorWalletRepository _repository;
  final AuthProvider _auth;

  CreatorProfileStats? _stats;
  List<CreatorWalletTransaction> _recentTransactions = const [];
  int _transactionTotal = 0;
  bool _loading = false;
  bool _refreshing = false;
  String? _error;
  DateTime? _lastUpdated;
  int? _boundUserId;
  int _generation = 0;
  Future<void>? _activeLoad;

  CreatorProfileStats? get stats => _stats;
  List<CreatorWalletTransaction> get recentTransactions =>
      List.unmodifiable(_recentTransactions);
  int get transactionTotal => _transactionTotal;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get hasData => _stats != null;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> load({bool force = false}) {
    final active = _activeLoad;
    if (active != null) return active;
    if (!force && _stats != null) return Future<void>.value();

    late final Future<void> request;
    request = _performLoad().whenComplete(() {
      if (identical(_activeLoad, request)) _activeLoad = null;
    });
    _activeLoad = request;
    return request;
  }

  Future<void> reload() async {
    final active = _activeLoad;
    if (active != null) await active;
    await load(force: true);
  }

  Future<void> _performLoad() async {
    final generation = ++_generation;
    _loading = _stats == null;
    _refreshing = _stats != null;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _repository.fetchProfileStats(),
        _repository.fetchTransactions(page: 1, pageSize: 8),
      ]);
      final stats = results[0] as CreatorProfileStats;
      final transactions = results[1] as PageResult<CreatorWalletTransaction>;
      if (generation != _generation) return;

      _stats = stats;
      _recentTransactions = transactions.list;
      _transactionTotal = transactions.total;
      _lastUpdated = DateTime.now();
    } on ApiException catch (error) {
      if (generation == _generation) _error = error.message;
    } catch (error) {
      if (generation == _generation) {
        _error = '个人中心数据加载失败，请稍后重试';
        debugPrint('CreatorWalletProvider load failed: $error');
      }
    } finally {
      if (generation == _generation) {
        _loading = false;
        _refreshing = false;
        notifyListeners();
      }
    }
  }

  Future<PageResult<CreatorWalletTransaction>> fetchTransactions({
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.fetchTransactions(page: page, pageSize: pageSize);
  }

  Future<List<CreatorPaymentChannel>> fetchRechargeChannels() {
    return _repository.fetchRechargeChannels();
  }

  Future<List<CreatorPaymentChannel>> fetchWithdrawChannels() {
    return _repository.fetchWithdrawChannels();
  }

  Future<CreatorRechargeOrder> createRecharge({
    required int amountFen,
    required String channelCode,
  }) {
    return _repository.createRecharge(
      amountFen: amountFen,
      channelCode: channelCode,
    );
  }

  Future<CreatorRechargeOrder> fetchRecharge(int id) {
    return _repository.fetchRecharge(id);
  }

  Future<CreatorWithdrawal> createWithdrawal({
    required int amountFen,
    required String channelCode,
    required String accountName,
    required String accountNo,
  }) async {
    final withdrawal = await _repository.createWithdrawal(
      amountFen: amountFen,
      channelCode: channelCode,
      accountName: accountName,
      accountNo: accountNo,
    );
    await reload();
    return withdrawal;
  }

  Future<CreatorWithdrawal> fetchWithdrawal(int id) {
    return _repository.fetchWithdrawal(id);
  }

  Future<void> refreshBalanceIfChanged({
    CreatorRechargeOrder? recharge,
    CreatorWithdrawal? withdrawal,
  }) async {
    final changed =
        recharge?.status == CreatorRechargeStatus.paid ||
        withdrawal?.status == CreatorWithdrawStatus.success ||
        withdrawal?.status == CreatorWithdrawStatus.failed ||
        withdrawal?.status == CreatorWithdrawStatus.cancelled;
    if (changed) await reload();
  }

  void clear() {
    _generation++;
    _activeLoad = null;
    _stats = null;
    _recentTransactions = const [];
    _transactionTotal = 0;
    _loading = false;
    _refreshing = false;
    _error = null;
    _lastUpdated = null;
    notifyListeners();
  }

  void _handleAuthChanged() {
    final nextUserId = _auth.user?.id;
    if (nextUserId == _boundUserId) return;
    _boundUserId = nextUserId;
    clear();
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
