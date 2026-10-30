# OPC AI · 用户端业务接口契约（M0 冻结 / M1、M2 已实现）

> 版本：v1.2 · 冻结日期：2026-10-29 · M1/M2 实现日期：2026-10-29～2026-10-30
> 状态：**M0 契约已冻结；M1 订单、M2 作品提交/审核接口已实现**
> 适用范围：Flutter 用户 App 的接单、工作台、提交、审核、钱包、充值、提现。
> 现有登录、Skill、任务查询、素材等接口仍以 `docs/api.md` 为准；本文只新增用户端业务接口，不重复定义已有接口。

---

## 0. 强制约定

1. **后端暴露 HTTP 接口，Flutter 调用接口。** Flutter 不直接调用模型供应商，不持有 API Key。
2. 除特例外统一返回：

```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": 1789800000000
}
```

3. 401 是唯一使用真实 HTTP 401 的鉴权失败；其他业务失败使用 HTTP 200 + 业务 `code`。
4. 所有需要登录的接口必须带：

```http
Authorization: Bearer <token>
```

5. **金额字段一律使用整数分**，字段名以 `Fen` 结尾。例如 `rewardFen=6800` 表示 68.00 元。禁止用 double 计算钱。
6. **算力字段仍使用整数点**，字段名 `credits`。算力与人民币钱包是两个账本，不能混用。
7. 用户提交的资源地址使用后端相对路径，例如 `/upload/task_xxx.png`；前端展示时再拼 host。
8. 分页统一使用项目现有 `PageResult`：

```json
{
  "list": [],
  "page": 1,
  "pageSize": 10,
  "total": 0
}
```

9. 所有时间使用 ISO-8601 字符串，例如 `2026-10-29T17:30:00`。
10. 任一接口失败时 `data=null`，`message` 可直接展示给用户。

---

## 1. 共用枚举（冻结）

### 1.1 `MediaType` 创作媒体类型

| 值 | 含义 |
|---|---|
| `IMAGE` | 图片 |
| `VIDEO` | 视频 |
| `AUDIO` | 音频 |

### 1.2 `MarketOrderStatus` 订单公共状态

> 这是订单在整个市场中的公共状态，不是某一个用户的状态。
> 一个订单可以有多个人接单，因此不能用公共订单状态表示“我已经做到哪一步”。

| 值 | 含义 |
|---|---|
| `OPEN` | 可接单 |
| `CLOSED` | 后台关闭，不再展示和接单 |
| `COMPLETED` | 名额已满或订单周期结束，不再接单 |

允许流转：

```text
OPEN → CLOSED
OPEN → COMPLETED
```

某个用户接单后，订单仍可以是 `OPEN`，直到名额耗尽或后台关闭。

### 1.3 `AcceptanceStatus` 当前用户接单状态

| 值 | 含义 | 用户可操作 |
|---|---|---|
| `ACCEPTED` | 已接单、制作中 | 可以创作并提交 |
| `SUBMITTED` | 已提交待审核 | 只能查看，不能重复提交 |
| `APPROVED` | 审核通过 | 只能查看 |
| `REJECTED` | 审核驳回 | 可以重新创作并提交 |
| `CANCELLED` | 已取消或订单关闭 | 不能操作 |

允许流转：

```text
ACCEPTED → SUBMITTED → APPROVED
SUBMITTED → REJECTED → ACCEPTED
ACCEPTED / SUBMITTED / REJECTED → CANCELLED
```

### 1.4 `ReviewStatus` 审核状态

| 值 | 含义 |
|---|---|
| `PENDING` | 待审核 |
| `APPROVED` | 审核通过 |
| `REJECTED` | 审核驳回 |

允许流转：

```text
PENDING → APPROVED
PENDING → REJECTED
```

**终态不能再次审核入账。**

### 1.5 `WalletTransactionType`

| 值 | 含义 | 方向 |
|---|---|---|
| `ORDER_INCOME` | 订单审核通过收入 | 入账 |
| `WITHDRAW_FREEZE` | 提现冻结 | 冻结 |
| `WITHDRAW_SUCCESS` | 提现成功 | 扣减 |
| `WITHDRAW_REFUND` | 提现失败退回 | 解冻/退回 |
| `MANUAL_ADJUST` | 后台人工调整 | 入账或扣减 |

### 1.6 `RechargeOrderStatus`

```text
PENDING → PAID
PENDING → FAILED
PENDING → CLOSED
PAID → REFUNDED
```

充值成功后增加 `User.credits`，不增加可提现现金。

### 1.7 `WithdrawStatus`

```text
PENDING → PROCESSING → SUCCESS
PENDING / PROCESSING → FAILED
PENDING → CANCELLED
```

### 1.8 `PaymentChannelDirection`

| 值 | 含义 |
|---|---|
| `RECHARGE` | 仅充值 |
| `WITHDRAW` | 仅提现 |
| `BOTH` | 充值、提现都支持 |

---

## 2. 共用业务模型（冻结）

### 2.1 `MarketOrderResponse`

```json
{
  "id": 1001,
  "orderNo": "MO202610290001",
  "title": "春季香水商品主图套组",
  "brandName": "花漾美妆",
  "description": "为一款春季香水制作 4 张商品主图",
  "mediaType": "IMAGE",
  "rewardFen": 6800,
  "creditCost": 12,
  "deadlineAt": "2026-10-30T20:00:00",
  "tasksTotal": 20,
  "tasksTaken": 12,
  "requirements": ["1:1 方图", "纯白背景", "提交 PNG"],
  "status": "OPEN",
  "myAcceptanceStatus": null,
  "createdAt": "2026-10-29T10:00:00"
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | long | 订单 ID |
| `orderNo` | string | 对外订单号，唯一 |
| `title` | string | 订单标题 |
| `brandName` | string | 需求方名称 |
| `description` | string | 需求说明 |
| `mediaType` | enum | `IMAGE/VIDEO/AUDIO` |
| `rewardFen` | long | 订单报酬，单位分 |
| `creditCost` | int | 预计消耗算力点，展示用；最终以后端任务扣费为准 |
| `deadlineAt` | datetime | 截止时间 |
| `tasksTotal` | int | 总名额 |
| `tasksTaken` | int | 已接名额 |
| `requirements` | string[] | 交付要求 |
| `status` | enum | 订单公共状态 |
| `myAcceptanceStatus` | enum/null | 当前用户接单状态；未接单为 null |
| `createdAt` | datetime | 发布时间 |

### 2.2 `OrderAcceptanceResponse`

```json
{
  "id": 501,
  "acceptanceNo": "OA202610290001",
  "orderId": 1001,
  "userId": 1,
  "status": "ACCEPTED",
  "acceptedAt": "2026-10-29T11:00:00",
  "submittedAt": null,
  "approvedAt": null
}
```

### 2.3 `WorkbenchContextResponse`

```json
{
  "order": {},
  "acceptance": {},
  "recommendedMediaType": "IMAGE",
  "activeSubmission": null,
  "canGenerate": true,
  "unavailableReason": null
}
```

### 2.4 `SubmissionResponse`

```json
{
  "id": 8001,
  "submissionNo": "SB202610290001",
  "orderId": 1001,
  "orderTitle": "春季香水商品主图套组",
  "acceptanceId": 501,
  "taskId": 9001,
  "mediaType": "IMAGE",
  "title": "香水主图最终稿",
  "note": "已完成 4 张主图",
  "resultUrl": "/upload/task_9001.png",
  "thumbnailUrl": "/upload/task_9001.png",
  "durationMs": null,
  "status": "PENDING",
  "reviewNote": null,
  "submittedAt": "2026-10-29T12:00:00",
  "reviewedAt": null,
  "rewardFen": 6800
}
```

### 2.5 `WalletSummaryResponse`

```json
{
  "withdrawableFen": 36800,
  "frozenFen": 0,
  "totalIncomeFen": 9600,
  "totalWithdrawnFen": 0,
  "credits": 1286
}
```

### 2.6 `WalletTransactionResponse`

```json
{
  "id": 7001,
  "transactionNo": "WT202610290001",
  "type": "ORDER_INCOME",
  "amountFen": 9600,
  "balanceAfterFen": 36800,
  "referenceType": "SUBMISSION",
  "referenceId": 8001,
  "description": "订单收入 · 夏日饰品氛围图",
  "createdAt": "2026-10-29T12:00:00"
}
```

### 2.7 `PaymentChannelResponse`

```json
{
  "code": "ALIPAY",
  "name": "支付宝",
  "direction": "RECHARGE",
  "icon": "alipay",
  "enabled": true,
  "minFen": 100,
  "maxFen": 500000,
  "feeRateBps": 0,
  "sortOrder": 10
}
```

### 2.8 `RechargeOrderResponse`

```json
{
  "id": 3001,
  "rechargeNo": "RC202610290001",
  "amountFen": 5000,
  "credits": 5000,
  "channelCode": "ALIPAY",
  "status": "PENDING",
  "payUrl": "/mock-pay/RC202610290001",
  "createdAt": "2026-10-29T12:00:00",
  "paidAt": null
}
```

### 2.9 `WithdrawRequestResponse`

```json
{
  "id": 4001,
  "withdrawNo": "WD202610290001",
  "amountFen": 10000,
  "channelCode": "ALIPAY",
  "accountName": "张三",
  "accountNoMasked": "138****1234",
  "status": "PENDING",
  "failureReason": null,
  "createdAt": "2026-10-29T12:00:00",
  "processedAt": null
}
```

---

## 3. 订单接口

### 3.1 可接订单列表

```http
GET /api/orders/available?mediaType=IMAGE&page=1&pageSize=10
```

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `mediaType` | string | 否 | `IMAGE/VIDEO/AUDIO` |
| `page` | int | 否 | 默认 1 |
| `pageSize` | int | 否 | 默认 10，最大 50 |

返回 `data`：`PageResult<MarketOrderResponse>`。

只返回 `status=OPEN`、未过截止时间、还有名额，且当前用户尚未接过的订单。

### 3.2 订单详情

```http
GET /api/orders/{orderId}
```

返回 `data`：

```json
{
  "order": {},
  "myAcceptance": null,
  "canAccept": true,
  "unavailableReason": null
}
```

失败码：`5501` 订单不存在。

### 3.3 接单

```http
POST /api/orders/{orderId}/accept
```

无请求体。返回 `data`：

```json
{
  "acceptance": {},
  "workbench": {}
}
```

规则：

- 只有 `OPEN` 可接；
- 同一用户同一订单只能接一次；
- 演示版限制同一用户同时只能有 1 个进行中的接单；
- 接单成功后新增 `AcceptanceStatus=ACCEPTED` 的接单记录，订单 `tasksTaken+1`；仍有名额时订单继续保持 `OPEN`；
- 接单和名额扣减必须使用事务和乐观锁。

失败码：`5501/5502/5503/5504/5507/5508`。

### 3.4 我的接单列表

```http
GET /api/orders/my?status=ACCEPTED&page=1&pageSize=10
```

返回 `data`：`PageResult<OrderAcceptanceResponse>`。
用途：用户刷新后恢复工作台当前订单。

### 3.5 工作台上下文

```http
GET /api/orders/{orderId}/workbench
```

返回 `data`：`WorkbenchContextResponse`。

规则：

- 只有当前用户已接该订单才能访问；
- 已有活动提交时返回 `activeSubmission`；
- 当前用户 acceptance 为 `SUBMITTED/APPROVED` 时 `canGenerate=false`；
- 当前用户 acceptance 为 `ACCEPTED/REJECTED` 时可以继续生成。

失败码：`5501/5505/5506`。

### 3.6 M1 快速自测（curl）

以下命令使用开发令牌，后端需运行在 `http://localhost:8080`：

```bash
# 1. 可接订单
curl -H "Authorization: Bearer mock-token-for-scaffold" \
  "http://localhost:8080/api/orders/available?page=1&pageSize=10"

# 2. 订单详情
curl -H "Authorization: Bearer mock-token-for-scaffold" \
  "http://localhost:8080/api/orders/1"

# 3. 接单（把 1 换成实际订单 ID）
curl -X POST -H "Authorization: Bearer mock-token-for-scaffold" \
  "http://localhost:8080/api/orders/1/accept"

# 4. 我的接单
curl -H "Authorization: Bearer mock-token-for-scaffold" \
  "http://localhost:8080/api/orders/my?page=1&pageSize=10"

# 5. 工作台上下文
curl -H "Authorization: Bearer mock-token-for-scaffold" \
  "http://localhost:8080/api/orders/1/workbench"
```

---

## 4. 提交与审核接口

### 4.1 提交作品

```http
POST /api/submissions
```

请求体：

```json
{
  "orderId": 1001,
  "taskId": 9001,
  "title": "香水主图最终稿",
  "note": "已完成 4 张主图"
}
```

| 字段 | 类型 | 必填 | 校验 |
|---|---|---|---|
| `orderId` | long | 是 | 当前用户已接单 |
| `taskId` | long | 是 | 任务属于当前用户，且已成功 |
| `title` | string | 是 | 1～120 字 |
| `note` | string | 否 | ≤ 1000 字 |

服务端从 `taskId` 读取结果地址、媒体类型和耗时，客户端不直接提交任意 `resultUrl`。

返回 `data`：`SubmissionResponse`。

规则：

- 任务类型必须与订单 `mediaType` 匹配；
- 没有成功结果的任务不能提交；
- 同一订单已有 `PENDING` 提交时不允许重复提交；
- 提交成功后，当前用户的 acceptance 进入 `SUBMITTED`；订单公共状态不因单个用户提交改变；
- 被驳回后允许创建新版本提交，`versionNo` 递增。

失败码：`5501/5505/5506/5601/5602/5603/5607`。

### 4.2 我的提交列表

```http
GET /api/submissions/my?status=PENDING&mediaType=IMAGE&page=1&pageSize=10
```

返回 `data`：`PageResult<SubmissionResponse>`。

### 4.3 提交详情 / 审核状态

```http
GET /api/submissions/{submissionId}
```

返回 `data`：`SubmissionResponse`。

这是 Flutter 审核状态页使用的唯一详情接口。前端展示：

- `status=PENDING`：审核中；
- `status=APPROVED`：已通过；
- `status=REJECTED`：未通过，并展示 `reviewNote`。

失败码：`5601`。

### 4.4 后台审核（M2 配套，不由 Flutter 用户端调用）

```http
PUT /api/admin/submissions/{submissionId}/review
```

请求体：

```json
{
  "decision": "APPROVED",
  "comment": "作品符合订单要求"
}
```

规则：

- 只有 `PENDING` 可审核；
- 审核必须写 `t_review_record`；
- `APPROVED` 时：
  - 更新 submission 和当前用户 acceptance 状态；订单公共状态不因单个用户审核结果改变；
  - 只写一次订单收入流水；
  - 增加钱包可提现余额。
- `REJECTED` 时：
  - 更新状态；
  - 订单允许重新提交；
  - 不入账。

失败码：`5601/5604/5605/5606`。

### 4.5 作品详情

```http
GET /api/submissions/{submissionId}/result
```

返回 `data`：

```json
{
  "submission": {},
  "task": {},
  "mediaType": "VIDEO",
  "playableUrl": "/upload/task_9001.mp4",
  "thumbnailUrl": "/upload/task_9001.jpg"
}
```

前端作品详情页优先使用该接口，不依赖任务列表分页。

### 4.6 M2 快速自测（curl）

前置条件：当前用户已接订单，并且有一个状态为 `SUCCESS`、结果地址非空的任务。

```bash
# 1. 提交作品，taskId 换成自己的成功任务 ID
curl -X POST -H "Authorization: Bearer mock-token-for-scaffold" \
  -H "Content-Type: application/json" \
  -d '{"orderId":1,"taskId":33,"title":"香水主图最终稿","note":"已完成 4 张主图"}' \
  "http://localhost:8080/api/submissions"

# 2. 我的提交
curl -H "Authorization: Bearer mock-token-for-scaffold" \
  "http://localhost:8080/api/submissions/my?page=1&pageSize=10"

# 3. 审核状态
curl -H "Authorization: Bearer mock-token-for-scaffold" \
  "http://localhost:8080/api/submissions/1"

# 4. 作品结果
curl -H "Authorization: Bearer mock-token-for-scaffold" \
  "http://localhost:8080/api/submissions/1/result"

# 5. 管理员审核
ADMIN_TOKEN="<管理员登录返回的 token>"
curl -X PUT -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"decision":"APPROVED","comment":"符合订单要求"}' \
  "http://localhost:8080/api/admin/submissions/1/review"
```

---

## 5. 钱包、充值和提现接口

### 5.1 钱包汇总

```http
GET /api/wallet/summary
```

返回 `data`：`WalletSummaryResponse`。

首次访问时自动创建钱包账户，初始金额均为 0。

### 5.2 钱包流水

```http
GET /api/wallet/transactions?type=ORDER_INCOME&page=1&pageSize=10
```

返回 `data`：`PageResult<WalletTransactionResponse>`。

### 5.3 充值渠道

```http
GET /api/wallet/recharge/channels
```

返回 `data`：`PaymentChannelResponse[]`，只返回 `enabled=true` 且方向包含 `RECHARGE` 的渠道。

### 5.4 创建充值订单

```http
POST /api/wallet/recharges
```

请求体：

```json
{
  "amountFen": 5000,
  "channelCode": "ALIPAY"
}
```

返回 `data`：`RechargeOrderResponse`。

规则：

- `amountFen` 必须在渠道 `minFen～maxFen` 之间；
- 算力到账数量 `credits = amountFen`，即 1 分钱 = 1 算力点（1 元 = 100 算力点）；
- 创建充值订单不立即加算力；
- 只有支付成功回调后才增加 `User.credits`；
- 同一 `rechargeNo` 回调必须幂等。

失败码：`5704/5705/5708/5710`。

### 5.5 查询充值订单

```http
GET /api/wallet/recharges/{rechargeOrderId}
```

返回 `data`：`RechargeOrderResponse`。

### 5.6 充值支付回调（后端内部接口）

```http
POST /api/payments/callback/{channelCode}
```

请求头必须校验渠道签名。请求体由具体支付渠道定义，服务端统一转换为：

```json
{
  "rechargeNo": "RC202610290001",
  "externalTradeNo": "ALI202610290001",
  "paidFen": 5000,
  "paidAt": "2026-10-29T12:05:00",
  "signature": "..."
}
```

回调必须：

- 验签；
- 校验金额；
- 幂等处理；
- 成功后增加算力并记录流水；
- 不能由 Flutter 直接调用。

### 5.7 提现渠道

```http
GET /api/wallet/withdraw/channels
```

返回 `data`：`PaymentChannelResponse[]`，只返回方向包含 `WITHDRAW` 的渠道。

### 5.8 创建提现申请

```http
POST /api/wallet/withdrawals
```

请求体：

```json
{
  "amountFen": 10000,
  "channelCode": "ALIPAY",
  "accountName": "张三",
  "accountNo": "13800001234"
}
```

返回 `data`：`WithdrawRequestResponse`。

规则：

- 最低提现 `1000` 分（10 元）；
- 不能超过 `withdrawableFen`；
- 创建时从 `withdrawableFen` 移到 `frozenFen`，写 `WITHDRAW_FREEZE` 流水；
- 后台处理成功后扣减 `frozenFen`，写 `WITHDRAW_SUCCESS`；
- 失败时退回 `withdrawableFen`，写 `WITHDRAW_REFUND`；
- `accountNo` 只存脱敏值或加密快照，响应不得返回完整账号。

失败码：`5702/5703/5704/5709/5710`。

### 5.9 查询提现申请

```http
GET /api/wallet/withdrawals/{withdrawRequestId}
```

返回 `data`：`WithdrawRequestResponse`。

### 5.10 后台处理提现（后台接口）

```http
PUT /api/admin/withdrawals/{id}/status
```

请求体：

```json
{
  "status": "SUCCESS",
  "failureReason": null,
  "externalTradeNo": "PAYOUT202610290001"
}
```

M3 实现；Flutter 用户端只读自己的提现状态。

---

## 6. 音频生成接口（M4）

### 6.1 文本生成音频

```http
POST /api/creation/text-to-audio
```

请求体：

```json
{
  "skillId": null,
  "prompt": "欢迎来到花漾美妆直播间",
  "negativePrompt": null,
  "voiceCode": "warm_female",
  "language": "zh-CN",
  "speed": 1.0,
  "format": "MP3"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `prompt` | string | 是 | 配音文案，≤ 2000 字 |
| `voiceCode` | string | 是 | 后端提供的音色编码 |
| `language` | string | 是 | `zh-CN/en-US/ja-JP` |
| `speed` | decimal | 否 | 0.5～2.0，默认 1.0 |
| `format` | string | 否 | `MP3/WAV`，默认 MP3 |

返回 `data`：与现有 `TaskResponse` 相同，但：

- `type = TEXT_TO_AUDIO`
- `typeLabel = 文本转音频`
- 成功结果使用 `resultUrl` 指向音频文件。

前端复用现有任务轮询接口查询进度。

### 6.2 现有图片/视频接口

Flutter 用户端继续使用：

```http
POST /api/creation/text-to-image
POST /api/creation/image-to-video
GET  /api/tasks/{taskId}
GET  /api/tasks
```

具体字段以 `docs/api.md` §4、§5 为准。

---

## 7. 错误码冻结（5500～5799）

> M0 只冻结编号；实现阶段再写入 `ErrorCode.java`。
> 已有错误码 6000～9099 不被占用。

| 错误码 | 常量建议 | 文案 |
|---:|---|---|
| 5501 | `ORDER_NOT_FOUND` | 订单不存在或已下架 |
| 5502 | `ORDER_NOT_OPEN` | 当前订单不可接取 |
| 5503 | `ORDER_ALREADY_ACCEPTED` | 你已经接过该订单 |
| 5504 | `ORDER_QUOTA_FULL` | 该订单名额已满 |
| 5505 | `ORDER_ACCESS_DENIED` | 无权访问该订单 |
| 5506 | `ORDER_STATUS_ILLEGAL` | 当前订单状态不允许该操作 |
| 5507 | `ORDER_DEADLINE_PASSED` | 订单已过截止时间 |
| 5508 | `ORDER_ACTIVE_EXISTS` | 你已有进行中的接单，请先完成或放弃 |
| 5601 | `SUBMISSION_NOT_FOUND` | 作品提交记录不存在 |
| 5602 | `SUBMISSION_NOT_ALLOWED` | 当前订单状态不允许提交 |
| 5603 | `SUBMISSION_ALREADY_PENDING` | 该订单已有待审核作品 |
| 5604 | `REVIEW_NOT_FOUND` | 审核记录不存在 |
| 5605 | `REVIEW_NOT_PENDING` | 当前作品不在待审核状态 |
| 5606 | `REVIEW_ALREADY_FINALIZED` | 该作品已经审核完成 |
| 5607 | `SUBMISSION_MEDIA_INVALID` | 任务媒体类型与订单要求不匹配 |
| 5701 | `WALLET_ACCOUNT_NOT_FOUND` | 钱包账户不存在 |
| 5702 | `WALLET_INSUFFICIENT_BALANCE` | 可提现余额不足 |
| 5703 | `WITHDRAW_AMOUNT_INVALID` | 提现金额不合法 |
| 5704 | `PAYMENT_CHANNEL_UNSUPPORTED` | 不支持的支付渠道 |
| 5705 | `RECHARGE_AMOUNT_INVALID` | 充值金额不合法 |
| 5706 | `RECHARGE_ORDER_NOT_FOUND` | 充值订单不存在 |
| 5707 | `RECHARGE_STATUS_ILLEGAL` | 充值订单状态不允许该操作 |
| 5708 | `PAYMENT_CALLBACK_INVALID` | 支付回调校验失败 |
| 5709 | `WITHDRAW_STATUS_ILLEGAL` | 提现状态不允许该操作 |
| 5710 | `WALLET_DUPLICATE_OPERATION` | 重复的钱包操作 |

---

## 8. 数据库模型冻结

新增 9 张表，不修改已有 `t_user`、`t_ai_task`、`t_work` 的业务语义。

### 8.1 `t_market_order`

```sql
CREATE TABLE `t_market_order` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `order_no` VARCHAR(32) NOT NULL,
  `title` VARCHAR(120) NOT NULL,
  `brand_name` VARCHAR(100) NOT NULL,
  `description` TEXT NOT NULL,
  `media_type` VARCHAR(20) NOT NULL,
  `reward_fen` BIGINT NOT NULL,
  `credit_cost` INT NOT NULL DEFAULT 0,
  `requirements_json` JSON DEFAULT NULL,
  `deadline_at` DATETIME NOT NULL,
  `tasks_total` INT NOT NULL DEFAULT 0,
  `tasks_taken` INT NOT NULL DEFAULT 0,
  `status` VARCHAR(20) NOT NULL DEFAULT 'OPEN',
  `version` BIGINT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_status_deadline` (`status`, `deadline_at`),
  KEY `idx_media_type` (`media_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='接单市场订单';
```

### 8.2 `t_order_acceptance`

```sql
CREATE TABLE `t_order_acceptance` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `acceptance_no` VARCHAR(32) NOT NULL,
  `order_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'ACCEPTED',
  `accepted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `submitted_at` DATETIME DEFAULT NULL,
  `approved_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_acceptance_no` (`acceptance_no`),
  UNIQUE KEY `uk_order_user` (`order_id`, `user_id`),
  KEY `idx_user_status` (`user_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户接单记录';
```

### 8.3 `t_submission`

```sql
CREATE TABLE `t_submission` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `submission_no` VARCHAR(32) NOT NULL,
  `order_id` BIGINT NOT NULL,
  `acceptance_id` BIGINT NOT NULL,
  `user_id` BIGINT NOT NULL,
  `task_id` BIGINT NOT NULL,
  `media_type` VARCHAR(20) NOT NULL,
  `title` VARCHAR(120) NOT NULL,
  `note` VARCHAR(1000) DEFAULT NULL,
  `result_url` VARCHAR(500) NOT NULL,
  `thumbnail_url` VARCHAR(500) DEFAULT NULL,
  `duration_ms` BIGINT DEFAULT NULL,
  `version_no` INT NOT NULL DEFAULT 1,
  `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  `review_note` VARCHAR(1000) DEFAULT NULL,
  `submitted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reviewed_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_submission_no` (`submission_no`),
  UNIQUE KEY `uk_order_user_version` (`order_id`, `user_id`, `version_no`),
  KEY `idx_user_status` (`user_id`, `status`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单作品提交记录';
```

### 8.4 `t_review_record`

```sql
CREATE TABLE `t_review_record` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `submission_id` BIGINT NOT NULL,
  `reviewer_id` BIGINT DEFAULT NULL,
  `decision` VARCHAR(20) NOT NULL,
  `comment` VARCHAR(1000) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_review_submission` (`submission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='作品审核记录';
```

### 8.5 `t_wallet_account`

```sql
CREATE TABLE `t_wallet_account` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `withdrawable_fen` BIGINT NOT NULL DEFAULT 0,
  `frozen_fen` BIGINT NOT NULL DEFAULT 0,
  `total_income_fen` BIGINT NOT NULL DEFAULT 0,
  `total_withdrawn_fen` BIGINT NOT NULL DEFAULT 0,
  `version` BIGINT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_wallet_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户现金钱包账户';
```

### 8.6 `t_wallet_transaction`

```sql
CREATE TABLE `t_wallet_transaction` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `transaction_no` VARCHAR(32) NOT NULL,
  `user_id` BIGINT NOT NULL,
  `type` VARCHAR(30) NOT NULL,
  `amount_fen` BIGINT NOT NULL,
  `balance_after_fen` BIGINT NOT NULL,
  `reference_type` VARCHAR(30) DEFAULT NULL,
  `reference_id` BIGINT DEFAULT NULL,
  `description` VARCHAR(255) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_transaction_no` (`transaction_no`),
  KEY `idx_wallet_user_created` (`user_id`, `created_at`),
  KEY `idx_reference` (`reference_type`, `reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='现金钱包流水';
```

### 8.7 `t_recharge_order`

```sql
CREATE TABLE `t_recharge_order` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `recharge_no` VARCHAR(32) NOT NULL,
  `user_id` BIGINT NOT NULL,
  `amount_fen` BIGINT NOT NULL,
  `credits` INT NOT NULL,
  `channel_code` VARCHAR(30) NOT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  `external_trade_no` VARCHAR(100) DEFAULT NULL,
  `pay_url` VARCHAR(500) DEFAULT NULL,
  `paid_at` DATETIME DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_recharge_no` (`recharge_no`),
  UNIQUE KEY `uk_external_trade_no` (`external_trade_no`),
  KEY `idx_recharge_user` (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='算力充值订单';
```

### 8.8 `t_withdraw_request`

```sql
CREATE TABLE `t_withdraw_request` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `withdraw_no` VARCHAR(32) NOT NULL,
  `user_id` BIGINT NOT NULL,
  `amount_fen` BIGINT NOT NULL,
  `channel_code` VARCHAR(30) NOT NULL,
  `account_name` VARCHAR(100) NOT NULL,
  `account_no_masked` VARCHAR(100) NOT NULL,
  `account_snapshot_json` JSON DEFAULT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  `failure_reason` VARCHAR(500) DEFAULT NULL,
  `external_trade_no` VARCHAR(100) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `processed_at` DATETIME DEFAULT NULL,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_withdraw_no` (`withdraw_no`),
  UNIQUE KEY `uk_withdraw_external` (`external_trade_no`),
  KEY `idx_withdraw_user` (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='提现申请';
```

### 8.9 `t_payment_channel`

```sql
CREATE TABLE `t_payment_channel` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `direction` VARCHAR(20) NOT NULL,
  `icon` VARCHAR(50) DEFAULT NULL,
  `enabled` TINYINT NOT NULL DEFAULT 1,
  `min_fen` BIGINT NOT NULL DEFAULT 100,
  `max_fen` BIGINT NOT NULL DEFAULT 500000,
  `fee_rate_bps` INT NOT NULL DEFAULT 0,
  `config_json` JSON DEFAULT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_channel_code` (`code`),
  KEY `idx_channel_direction` (`direction`, `enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付渠道配置';
```

### 8.10 ER 关系

```text
t_user 1:N t_market_order（通过 t_order_acceptance）
t_market_order 1:N t_order_acceptance
t_order_acceptance 1:N t_submission
t_submission 1:N t_review_record
t_user 1:1 t_wallet_account
t_wallet_account 1:N t_wallet_transaction
t_user 1:N t_recharge_order
t_user 1:N t_withdraw_request
t_payment_channel 1:N t_recharge_order / t_withdraw_request（按 channel_code）
```

---

## 9. 事务与并发规则

1. 接单：订单状态校验、名额扣减、接单记录写入必须在同一事务。
2. 提交：任务所有权校验、提交记录创建、订单状态更新必须在同一事务。
3. 审核通过：审核记录、提交状态、接单状态、订单状态、钱包入账、钱包流水必须在同一事务。
4. 提现：余额扣减、冻结金额增加、冻结流水必须在同一事务。
5. 充值回调：验签、状态更新、算力增加必须幂等。
6. 钱包账户使用乐观锁 `@Version`，防止并发提现超额。
7. 审核接口必须防止重复入账，唯一依据是 submission 的终态和审核记录。
8. 订单名额使用乐观锁或行锁，不能只做“先查后改”。

---

## 10. 演示种子数据要求

M1/M3/M4 实现时至少准备：

- 6 个 `OPEN` 订单：图片 2、视频 2、音频 2；
- 1 个已接单、可进入工作台的订单；
- 1 个待审核提交；
- 1 个审核通过并已入账作品；
- 充值渠道：支付宝、微信支付、银联云闪付；
- 提现渠道：支付宝、微信零钱、银行卡；
- 钱包演示账户：可提现 36800 分、0 冻结、流水若干。

---

## 11. 变更记录

| 版本 | 日期 | 内容 |
|---|---|---|
| v1.0 | 2026-10-29 | M0 首次冻结：订单、接单、提交、审核、钱包、充值、提现、音频生成及 9 张新表 |
| v1.1 | 2026-10-29 | M1 实现：`t_market_order`、`t_order_acceptance`、订单列表/详情/接单/我的接单/工作台接口，并加入 5501～5508 错误码 |
| v1.2 | 2026-10-30 | M2 实现：`t_submission`、`t_review_record`、作品提交/我的提交/审核状态/作品结果/后台审核接口，并加入 5601～5607 错误码 |