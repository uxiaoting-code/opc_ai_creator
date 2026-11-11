# 用户端 v2 · 接单创作业务闭环

> 实现日期：2026-10-29 · 最后核对：2026-11-07
> 入口：`lib/app.dart` → `lib/creator_flow/creator_router.dart`
> 当前口径：文档保留 v2 页面历史；实际路由、四 Tab 和接口状态以 `docs/SCHEDULE.md` §A～§H 及 `lib/creator_flow/` 代码为准。

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
课程 | 创作 | 接单 | 我的
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

早期演示版本由 `CreatorFlowProvider` 维护；当前主链路订单、生成、提交和审核已通过 `creator_order_repository.dart`、`creator_submission_repository.dart` 调用真实后端。仍在收尾的是钱包、充值、提现和个人中心统一统计。

真实接口适配层：

```text
lib/creator_flow/data/creator_order_repository.dart
lib/creator_flow/data/creator_submission_repository.dart
```

订单列表、接单上下文、提交记录、审核状态和 AI 任务已使用真实接口；钱包与个人统计正在按 F8 迁移。

当前主流程使用真实接口；不要再用演示数据伪装订单、审核或 AI 生成成功。钱包和个人统计按 F8 逐步切换到 `/api/wallet/**` 与 `/api/profile/stats`。

当前接口适配清单：

| 能力 | M0 冻结接口（以 `docs/api-user.md` 为准） |
|---|---|
| 登录注册 | `/api/auth/**`（已存在） |
| 接单大厅 | `/api/orders/available` |
| 接单详情 | `/api/orders/{id}` |
| 接单 | `POST /api/orders/{id}/accept` |
| 工作台上下文 | `GET /api/orders/{id}/workbench` |
| 文生图 | `POST /api/creation/text-to-image`（已存在） |
| 图生视频 | `POST /api/creation/image-to-video`（已存在） |
| 生成音频 | `POST /api/creation/text-to-audio`（已完成） |
| 作品提交 | `POST /api/submissions` |
| 审核状态 | `GET /api/submissions/{id}` |
| 审核列表 | `GET /api/submissions/my` |
| 充值下单 | `POST /api/wallet/recharges` |
| 充值渠道 | `GET /api/wallet/recharge/channels` |
| 提现申请 | `POST /api/wallet/withdrawals` |
| 提现渠道 | `GET /api/wallet/withdraw/channels` |
| 钱包汇总 | `GET /api/wallet/summary` |
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

1. 前端完成 F8：个人中心、钱包、充值、提现接入真实接口和统一统计。
2. 前端完善作品分页、视频详情、结果下载和小屏回归。
3. 前后端按 `docs/SCHEDULE.md` 执行 P0-11 端到端复验。
4. 支付回调继续由后端接收；前端只展示渠道和后端返回的状态。
