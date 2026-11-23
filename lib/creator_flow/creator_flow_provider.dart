import 'package:flutter/foundation.dart';

import 'models/creator_models.dart';
import 'models/creator_order.dart';

/// 当前创作上下文的页面状态。
///
/// 订单、生成任务、提交审核、钱包和个人统计均有各自的数据仓库；
/// 这里只保留跨页面共享的“当前接单订单/当前工作动作”，避免出现第二套
/// 订单或钱包事实来源。
class CreatorFlowProvider extends ChangeNotifier {
  MarketOrder? _currentOrder;
  CreatorWorkContext? _workContext;

  MarketOrder? get currentOrder => _currentOrder;
  CreatorWorkContext? get workContext => _workContext;

  /// 把真实接单结果同步到创作流程状态。
  void setAcceptedApiOrder(CreatorOrder order, {String? acceptanceStatus}) {
    _workContext = null;
    _currentOrder = _fromApiOrder(order, acceptanceStatus);
    notifyListeners();
  }

  /// 登录恢复、刷新或回到前台时同步后端当前工作上下文。
  void applyWorkContext(CreatorWorkContext context) {
    _workContext = context;
    _currentOrder = context.order == null
        ? null
        : _fromApiOrder(context.order!, context.acceptanceStatus);
    notifyListeners();
  }

  void clearCurrentOrder() {
    _workContext = null;
    _currentOrder = null;
    notifyListeners();
  }

  MarketOrder _fromApiOrder(CreatorOrder order, String? acceptanceStatus) {
    return MarketOrder(
      id: 'api-${order.id}',
      title: order.title,
      brand: order.brandName,
      description: order.description,
      mode: switch (order.mediaType) {
        OrderMediaType.image => CreationMode.image,
        OrderMediaType.video => CreationMode.video,
        OrderMediaType.audio => CreationMode.audio,
      },
      reward: order.rewardYuan,
      creditCost: order.creditCost,
      deadline: order.deadlineAt == null ? '订单进行中' : '截止 ${order.deadlineAt}',
      tasksLeft: order.tasksLeft,
      requirements: order.requirements,
      status: switch (acceptanceStatus) {
        'SUBMITTED' => MarketOrderStatus.submitted,
        'REJECTED' => MarketOrderStatus.rejected,
        'APPROVED' => MarketOrderStatus.approved,
        _ => MarketOrderStatus.accepted,
      },
    );
  }
}
