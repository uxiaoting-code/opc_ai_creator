# 用户端 v2 · 接单创作业务闭环

> 实现日期：2026-10-29
> 入口：`lib/app.dart` → `lib/creator_flow/creator_router.dart`
> 目标：替换旧 13 页演示导航，交付老师要求的接单创作基础业务闭环。

---

## 1. 已实现的 16 个页面

| # | 页面 | Flutter 文件 | 路由 |
|---:|---|---|---|
| 1 | 登录 / 注册 | `pages/login_page.dart` | `/login` |
| 2 | 接单大厅 | `pages/order_market_page.dart` | `/market` |
| 3 | 订单详情 | `pages/order_detail_page.dart` | `/market/:orderId` |
| 4 | 创作工作台 | `pages/workbench_page.dart` | `/workbench` |
| 5 | 文生图 | `pages/creation_pages.dart` | `/create/image` |
| 6 | 图生视频 | `pages/creation_pages.dart` | `/create/video` |
| 7 | 生成音频 | `pages/creation_pages.dart` | `/create/audio` |
| 8 | 作品提交 | `pages/submission_page.dart` | `/submission` |
| 9 | 审核状态 | `pages/review_status_page.dart` | `/review/:submissionId` |
| 10 | 审核记录 | `pages/submissions_page.dart` | `/submissions` |
| 11 | 作品详情 | `pages/work_detail_page.dart` | `/submissions/:submissionId` |
| 12 | 我的 / 钱包 | `pages/profile_page.dart` | `/profile` |
| 13 | 充值 | `pages/recharge_pages.dart` | `/recharge` |
| 14 | 充值渠道 | `pages/recharge_pages.dart` | `/recharge/channel` |
| 15 | 提现 | `pages/withdraw_pages.dart` | `/withdraw` |
| 16 | 提现渠道 | `pages/withdraw_pages.dart` | `/withdraw/channel` |

底部一级导航为：

```text
接单 | 工作台 | 审核 | 我的
```

---

## 2. 已实现的业务流程

```text
登录 / 注册
  → 接单大厅
  → 订单详情
  → 立即接单
  → 创作工作台
  → 文生图 / 图生视频 / 生成音频
  → 生成草稿
  → 填写作品标题和交付说明
  → 提交审核
  → 查看审核状态
  → 审核通过
  → 审核通过收入进入可提现余额
  → 提现
  → 选择提现渠道
```

充值链路：

```text
我的 / 钱包
  → 充值页面
  → 选择金额
  → 充值渠道页面
  → 确认渠道
  → 算力到账
```

审核状态包括：

- 审核中
- 已通过
- 未通过

作品审核记录支持图片、视频、音频三种创作类型。

---

## 3. 当前数据层说明

当前业务状态由：

```text
lib/creator_flow/creator_flow_provider.dart
```

统一维护，包括：

- 订单列表与订单状态
- 接单上下文
- 生成草稿
- 提交记录
- 审核状态
- 算力余额
- 可提现余额
- 钱包流水
- 充值 / 提现操作

这一层是页面和未来 repository / API 之间的边界。现在使用内存演示数据和模拟生成结果，保证不启动后端也能把整条流程演示完。

后续接后端时，页面不需要重写，只需要把 Provider 内部方法替换为真实接口调用：

| 能力 | 后续接口建议 |
|---|---|
| 登录注册 | `/api/auth/**`（已存在） |
| 接单大厅 | `/api/orders/available` |
| 接单详情 | `/api/orders/{id}` |
| 接单 | `POST /api/orders/{id}/accept` |
| 工作台上下文 | `GET /api/orders/{id}/workbench` |
| 文生图 | `POST /api/creation/text-to-image`（已存在） |
| 图生视频 | `POST /api/creation/image-to-video`（已存在） |
| 生成音频 | `POST /api/creation/text-to-audio`（待后端新增） |
| 作品提交 | `POST /api/submissions` |
| 审核状态 | `GET /api/submissions/{id}` |
| 审核列表 | `GET /api/submissions/my` |
| 充值下单 | `POST /api/wallet/recharges` |
| 充值渠道 | `GET /api/wallet/payment-channels` |
| 提现申请 | `POST /api/wallet/withdrawals` |
| 提现渠道 | `GET /api/wallet/withdraw-channels` |
| 钱包流水 | `GET /api/wallet/transactions` |

**红线：** API Key、模型供应商凭证和 Harness 编排细节只能留在 `server/`，不能进入 Flutter 客户端。

---

## 4. 当前验收状态

- `flutter analyze`：通过
- `flutter test`：通过
- 测试覆盖：
  - 登录注册页显示
  - 演示账号登录
  - 接单进入工作台
  - 文生图页面跳转和小屏无溢出
  - 接单 → 生成 → 提交 → 审核 → 入账 → 提现状态闭环

## 5. 下一步

1. 将 `CreatorFlowProvider` 中的订单、提交、审核和钱包状态拆成 Repository。
2. 后端新增订单市场、提交审核、充值和提现接口。
3. 把文生图 / 图生视频页面接到现有 Harness 任务接口。
4. 生成音频接入后端 TTS Provider。
5. 将演示版“模拟审核”按钮替换为后端审核轮询。
6. 充值渠道和提现渠道接入真实支付配置；支付回调必须由后端接收。