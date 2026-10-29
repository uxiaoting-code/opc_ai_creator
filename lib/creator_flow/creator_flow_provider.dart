import 'package:flutter/foundation.dart';

import 'models/creator_models.dart';

/// 用户端接单、创作、审核和钱包的演示状态。
///
/// 这一层是页面与未来后端接口之间的边界。订单市场、审核、钱包目前使用
/// 内存数据保证演示流程完整；后续接入真实接口时，只需要把方法内部替换为
/// repository 调用，页面和路由不需要重写。
class CreatorFlowProvider extends ChangeNotifier {
  CreatorFlowProvider() {
    _orders.addAll(_seedOrders());
    _submissions.addAll(_seedSubmissions());
    _walletEntries.addAll(_seedWalletEntries());
  }

  final List<MarketOrder> _orders = [];
  final List<SubmissionItem> _submissions = [];
  final List<WalletEntry> _walletEntries = [];

  String? _acceptedOrderId;
  GeneratedDraft? _draft;
  double _credits = 1286;
  double _withdrawable = 368;
  int _draftSequence = 100;
  int _submissionSequence = 1000;

  List<MarketOrder> get orders => List.unmodifiable(_orders);
  List<SubmissionItem> get submissions => List.unmodifiable(_submissions);
  List<WalletEntry> get walletEntries => List.unmodifiable(_walletEntries);
  GeneratedDraft? get draft => _draft;
  double get credits => _credits;
  double get withdrawable => _withdrawable;

  MarketOrder? get currentOrder {
    final id = _acceptedOrderId;
    if (id == null) return null;
    return _orderById(id);
  }

  int get pendingReviewCount =>
      _submissions.where((item) => item.status == ReviewStatus.pending).length;

  int get approvedCount =>
      _submissions.where((item) => item.status == ReviewStatus.approved).length;

  MarketOrder? orderById(String id) => _orderById(id);

  SubmissionItem? submissionById(String id) {
    for (final item in _submissions) {
      if (item.id == id) return item;
    }
    return null;
  }

  void acceptOrder(String id) {
    final order = _orderById(id);
    if (order == null) return;
    _acceptedOrderId = id;
    _replaceOrder(order.copyWith(status: MarketOrderStatus.accepted));
    _draft = null;
    notifyListeners();
  }

  bool createDraft({
    required CreationMode mode,
    required String prompt,
    required String model,
    Map<String, String> options = const {},
  }) {
    final order = currentOrder;
    if (order == null) return false;
    final cost = switch (mode) {
      CreationMode.image => 12.0,
      CreationMode.video => 48.0,
      CreationMode.audio => 8.0,
    };
    if (_credits < cost) return false;

    _credits -= cost;
    _draft = GeneratedDraft(
      mode: mode,
      prompt: prompt,
      model: model,
      createdAt: DateTime.now(),
      artworkSeed: ++_draftSequence,
      options: options,
    );
    _walletEntries.insert(
      0,
      WalletEntry(
        id: 'credit-${DateTime.now().microsecondsSinceEpoch}',
        type: WalletEntryType.consume,
        title: '${mode.label}消耗',
        amount: cost,
        createdAt: DateTime.now(),
        isCredit: true,
      ),
    );
    notifyListeners();
    return true;
  }

  SubmissionItem? submitDraft({required String title, required String note}) {
    final order = currentOrder;
    final draft = _draft;
    if (order == null || draft == null) return null;

    final submission = SubmissionItem(
      id: 'S${++_submissionSequence}',
      orderId: order.id,
      orderTitle: order.title,
      title: title.trim().isEmpty ? order.title : title.trim(),
      mode: draft.mode,
      prompt: draft.prompt,
      model: draft.model,
      reward: order.reward,
      createdAt: DateTime.now(),
      artworkSeed: draft.artworkSeed,
      note: note.trim(),
    );
    _submissions.insert(0, submission);
    _replaceOrder(order.copyWith(status: MarketOrderStatus.submitted));
    _draft = null;
    notifyListeners();
    return submission;
  }

  void reviewSubmission(String id, {required bool approved}) {
    final index = _submissions.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final item = _submissions[index];
    if (item.status != ReviewStatus.pending) return;

    final updated = item.copyWith(
      status: approved ? ReviewStatus.approved : ReviewStatus.rejected,
      reviewNote: approved ? '作品符合订单要求，审核通过。' : '画面与订单要求有偏差，请调整后重新提交。',
    );
    _submissions[index] = updated;
    final order = _orderById(item.orderId);
    if (order != null) {
      _replaceOrder(
        order.copyWith(
          status: approved
              ? MarketOrderStatus.approved
              : MarketOrderStatus.rejected,
        ),
      );
    }

    if (approved) {
      _withdrawable += item.reward;
      _walletEntries.insert(
        0,
        WalletEntry(
          id: 'income-${DateTime.now().microsecondsSinceEpoch}',
          type: WalletEntryType.income,
          title: '订单收入 · ${item.orderTitle}',
          amount: item.reward,
          createdAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  void recharge({required double amount, required String channel}) {
    final points = amount * 100;
    _credits += points;
    _walletEntries.insert(
      0,
      WalletEntry(
        id: 'recharge-${DateTime.now().microsecondsSinceEpoch}',
        type: WalletEntryType.recharge,
        title: '充值 · $channel',
        amount: amount,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  bool withdraw({required double amount, required String channel}) {
    if (amount <= 0 || amount > _withdrawable) return false;
    _withdrawable -= amount;
    _walletEntries.insert(
      0,
      WalletEntry(
        id: 'withdraw-${DateTime.now().microsecondsSinceEpoch}',
        type: WalletEntryType.withdraw,
        title: '提现 · $channel',
        amount: amount,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  void clearCurrentOrder() {
    _acceptedOrderId = null;
    _draft = null;
    notifyListeners();
  }

  MarketOrder? _orderById(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  void _replaceOrder(MarketOrder updated) {
    final index = _orders.indexWhere((order) => order.id == updated.id);
    if (index >= 0) _orders[index] = updated;
  }

  List<MarketOrder> _seedOrders() {
    return const [
      MarketOrder(
        id: 'o-1001',
        title: '春季香水商品主图套组',
        brand: '花漾美妆',
        description: '为一款春季香水制作 4 张商品主图，要求高级、干净、有自然光感。',
        mode: CreationMode.image,
        reward: 68,
        creditCost: 12,
        deadline: '剩余 26 小时',
        tasksLeft: 8,
        requirements: ['1:1 方图', '纯白或奶油背景', '保留瓶身真实质感', '提交 PNG'],
      ),
      MarketOrder(
        id: 'o-1002',
        title: '咖啡机 15 秒展示视频',
        brand: '森屿家电',
        description: '生成一段咖啡机旋转展示视频，带蒸汽和生活化场景，适合抖音竖屏。',
        mode: CreationMode.video,
        reward: 128,
        creditCost: 48,
        deadline: '剩余 18 小时',
        tasksLeft: 3,
        requirements: ['9:16 竖屏', '15 秒左右', '镜头平稳', '包含产品正面'],
      ),
      MarketOrder(
        id: 'o-1003',
        title: '跨境耳机英文口播',
        brand: 'GlobalTrade',
        description: '根据商品卖点生成 30 秒英文口播音频，语气自然、适合电商详情页。',
        mode: CreationMode.audio,
        reward: 88,
        creditCost: 8,
        deadline: '剩余 2 天',
        tasksLeft: 12,
        requirements: ['美式英语', '约 30 秒', '语速适中', '无背景音乐'],
      ),
      MarketOrder(
        id: 'o-1004',
        title: '女装数字人讲解视频',
        brand: 'MUSE 女装',
        description: '使用数字人口播展示新品卖点，画风亲和，适合直播间预热。',
        mode: CreationMode.video,
        reward: 158,
        creditCost: 48,
        deadline: '剩余 34 小时',
        tasksLeft: 6,
        requirements: ['9:16 竖屏', '女性数字人', '口型自然', '时长 45 秒'],
      ),
      MarketOrder(
        id: 'o-1005',
        title: '护肤详情页长图',
        brand: '溪野实验室',
        description: '生成一张适合详情页的商品长图，包含产品、成分和核心卖点。',
        mode: CreationMode.image,
        reward: 78,
        creditCost: 12,
        deadline: '剩余 3 天',
        tasksLeft: 15,
        requirements: ['3:4 比例', '清爽绿色调', '留出文字区域', '提交 JPG'],
      ),
      MarketOrder(
        id: 'o-1006',
        title: '食品礼盒多语言配音',
        brand: '东瀛优品',
        description: '生成日语和中文两版礼盒介绍音频，语气温柔，适合短视频。',
        mode: CreationMode.audio,
        reward: 56,
        creditCost: 8,
        deadline: '剩余 4 天',
        tasksLeft: 20,
        requirements: ['中日双语', '女声', '30 秒内', '可下载 MP3'],
      ),
    ];
  }

  List<SubmissionItem> _seedSubmissions() {
    return [
      SubmissionItem(
        id: 'S0991',
        orderId: 'demo-order',
        orderTitle: '夏日饰品氛围图',
        title: '夏日饰品氛围图 · 最终稿',
        mode: CreationMode.image,
        prompt: '香槟金首饰，奶油色背景，柔和自然光，电商广告质感',
        model: 'GPT-4o Image',
        reward: 96,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        artworkSeed: 72,
        status: ReviewStatus.approved,
        note: '已按要求补齐三张横版场景图。',
        reviewNote: '客户确认通过，作品已入库。',
      ),
      SubmissionItem(
        id: 'S0992',
        orderId: 'demo-order-2',
        orderTitle: '运动鞋短视频',
        title: '运动鞋短视频 · 第一版',
        mode: CreationMode.video,
        prompt: '白色运动鞋，未来感跑道，镜头环绕，产品广告',
        model: '可灵 Kling',
        reward: 120,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        artworkSeed: 33,
        status: ReviewStatus.pending,
        note: '等待客户确认背景颜色。',
      ),
    ];
  }

  List<WalletEntry> _seedWalletEntries() {
    final now = DateTime.now();
    return [
      WalletEntry(
        id: 'seed-income',
        type: WalletEntryType.income,
        title: '订单收入 · 夏日饰品氛围图',
        amount: 96,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      WalletEntry(
        id: 'seed-recharge',
        type: WalletEntryType.recharge,
        title: '充值 · 支付宝',
        amount: 500,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      WalletEntry(
        id: 'seed-consume',
        type: WalletEntryType.consume,
        title: '视频生成消耗',
        amount: 48,
        createdAt: now.subtract(const Duration(days: 5)),
        isCredit: true,
      ),
    ];
  }
}
