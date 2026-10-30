# OPC AI 后台 · 管理端接口契约

> 冻结日期：2026-10-14（v1）
> 依据：《OPC 文生图/图生视频 App 后台需求文档》（7 页）+ 老师给的 `admin-web/` 原型（7 个页面，415 行）
> **本文件是两人并行开发的唯一契约**。字段名一旦写进来就**不许单方面改**：
> 要改 → 先在群里说 → 改完在文末「变更记录」加一行 → 两人同步。

---

## 0. 通用约定

> 原则：**能复用就复用**，不要另立一套。现有 C 端的约定已经跑通，管理端照抄即可。

### 0.1 基础地址与鉴权

| 项 | 值 |
|---|---|
| 前缀 | `/api/admin` |
| 鉴权头 | `Authorization: Bearer <token>` |
| 登录 | `POST /api/admin/auth/login`，**校验 `t_user.role = 'ADMIN'`**，非管理员返回 403 |
| 拦截范围 | `/api/admin/**` 全部要求 ADMIN 角色 |
| 唯一放行 | `POST /api/admin/auth/login` + 浏览器 `OPTIONS` 预检 |
| ⚠️ 后门隔离 | `opc.security.dev-token`（固定令牌 `mock-token-for-scaffold`）**不放行 `/api/admin/**`**，必须在 `AuthInterceptor` 里单独判死 |

### 0.2 统一返回体

复用 `com.opc.server.common.Result`，**字段名不许改**（前端 `admin-web/js/api.js` 直接照着写）：

```json
{ "code": 200, "message": "success", "data": { }, "timestamp": 1760000000000 }
```

- `code == 200` 即成功，其余全部按失败处理
- 401 例外：**鉴权失败时 HTTP 状态码也必须是 401**（前端靠它踢回登录页），沿用现有 `GlobalExceptionHandler` 行为

### 0.3 分页（管理端只允许这一套）

列表接口统一返回 `com.opc.server.common.PageResult`：

```json
{ "list": [ ], "page": 1, "pageSize": 10, "total": 12846 }
```

- **`page` 从 1 开始**，服务层写 `PageRequest.of(page - 1, pageSize)`
- 查询参数统一命名 `page` / `pageSize`
- ⚠️ 存量 C 端 `GET /api/materials/my` 用的是 Spring 原生 `content` 字段且 page 从 0 开始 —— 那是历史包袱，**管理端不要模仿**

### 0.4 错误码分段（防两人撞码，务必遵守）

| 码段 | 归属 | 模块 |
|---|---|---|
| 1000-1099 | 已有 | 用户 / 鉴权 |
| 2000-2099 | 已有 | Skill 创作线路 |
| 3000-3099 | 已有 | Harness 任务 |
| 4000-4099 | 已有 | 文件 |
| 5000-5099 | 已有 | 作品 |
| **6000-6099** | 后端线 | 模型 / API 配置 |
| **6100-6199** | 后端线 | 调试面板 |
| **6200-6299** | 后端线 | MCP 接入 |
| **6300-6399** | 后端线 | 智能体与工作台 |
| **6400-6499** | 后端线 | 知识库 |
| **6500-6599** | **前端线** | Prompt(6500-6509) / 用户管理(6510-6519) / 系统设置(6520-6529) / 素材库后台 |
| **6600-6699** | **前端线** | 预留 |
| **6700-6779** | 后端线 | 数据概览 / 算力 / 账单 |
| **6780-6799** | 后端线 | API 网关 |
| 9000-9099 | 公共 | 管理端通用码 |

新增错误码一律加进 `com.opc.server.common.ErrorCode`，不要抛裸 `RuntimeException`。
（归属已定稿：`server/` 主体归你，`server/.../admin/{material,user,setting}` + `PromptController` 归搭档；前端页面与 `lib/` 全部归搭档。详见 `docs/admin-freeze.md` §4.1。）

**管理端通用码（先加这几个，公共段）**

| code | 枚举名 | message |
|---|---|---|
| 9001 | ADMIN_LOGIN_REQUIRED | 请先以管理员身份登录 |
| 9002 | ADMIN_FORBIDDEN | 该账号不是管理员，无权访问后台 |
| 9003 | ADMIN_PARAM_INVALID | 参数不合法 |
| 9004 | ADMIN_RESOURCE_NOT_FOUND | 目标资源不存在或已被删除 |
| 9005 | ADMIN_OPERATION_NOT_ALLOWED | 当前状态不允许该操作 |

### 0.5 枚举字典（冻结）

所有枚举接口**同时返回 value 和 label**（沿用现有 `TaskResponse.statusLabel` 的风格），前端直接渲染 label，不要在 JS 里做中文映射。

| 枚举 | 取值（value） | label | 来源 |
|---|---|---|---|
| `ProviderType` | CHAT / IMAGE / VIDEO / AUDIO | 聊天 / 图片 / 视频 / 音频 | 原型「大模型配置」类型徽章 |
| `AuthType` | NONE / API_KEY / OAUTH / CUSTOM_HEADER | — | 需求 3.1 第 2 步 |
| `PriceUnit` | TOKEN / SECOND / CALL | 百万token / 秒 / 次 | 原型价格列 |
| `AgentStatus` | DRAFT / PUBLISHED / OFFLINE | 草稿 / 已发布 / 已下线 | 原型「智能体」状态列 |
| `AgentCategory` | CUSTOMER_SERVICE / MARKETING / DESIGN / DATA_ANALYSIS / OTHER | 客服 / 营销 / 设计 / 数据分析 / 其他 | 原型分类下拉 |
| `ToolSource` | MODEL / KNOWLEDGE / MCP / BUILTIN | 模型 / 知识库 / MCP / 内置 | 冻结项 ② |
| `ToolKind` | MODEL_CALL / WEB_SEARCH / KB_RETRIEVE / CODE_RUN / IMAGE_PROCESS / DB_QUERY / HTTP_REQUEST / HUMAN_REVIEW | 模型调用 / 联网搜索 / 知识库检索 / 代码执行 / 图像处理 / 数据查询 / HTTP 请求 / 人工审核 | 原型「添加 Skill」弹窗 8 个类型 |
| `CreditTxnType` | RECHARGE / CONSUME / REFUND / GIFT / ADMIN_ADJUST | 充值 / 消耗 / 退款 / 赠送 / 后台调整 | 冻结项 ③ |
| `DocSourceType` | TEXT / FILE / URL / API_SYNC | 手动录入 / 文件 / 网址 / 接口同步 | 需求 3.4.1 |
| `McpTransport` | STDIO / SSE / HTTP | — | 需求 3.3 |
| 用户状态 | `1` / `0` | 正常 / 冻结 | 沿用现有 `t_user.status`，**不加新列** |

---
## 管理端通用

### `POST /api/admin/auth/login`

校验 `role = 'ADMIN'`，其他字段与 C 端登录一致。

请求：
```json
{ "username": "admin", "password": "admin123" }
```

响应 `data`（复用现有 `AuthResponse` 形状）：
```json
{ "token": "xxx.yyy.zzz", "user": { "id": 2, "username": "admin", "nickname": "超级管理员", "role": "ADMIN", "avatar": null } }
```
> 原型登录页写的是 `admin / admin@2026`，那是**假密码**。真密码以 `DataSeeder` 里的 `admin / admin123` 为准；要跟原型一致就改种子数据，别改代码。

### `GET /api/admin/auth/profile`
返回当前管理员信息，用于顶部栏「超级管理员」与「退出」按钮。

---

## ① 数据概览 `pg-dash`

原型元素：4 张统计卡（各带环比）+ 近 14 日营收柱状图 + 模型调用占比 + 最近订单表。

| 原型控件 | 字段 | 接口 |
|---|---|---|
| 总用户数 / 今日活跃 / 今日营收 / 今日算力消耗 | `totalUsers` `activeUsersToday` `revenueToday` `creditsUsedToday` + 各自的 `*Delta`（百分比，可正可负） | `GET /api/admin/dashboard/overview` |
| 近 14 日营收趋势 | `date` + `revenue` | `GET /api/admin/dashboard/revenue-trend?days=14` |
| 模型调用占比 | `modelName` `calls` `percent` | `GET /api/admin/dashboard/model-share?range=today` |

> P7 阶段 `t_call_log` 还没有 model 字段，`model-share` 先按 `toolKind`（能力类型）聚合，前端显示为「能力调用占比」；后续补模型字段后再切换。
| 最近订单（「查看全部」跳账单页） | 同账单行 | `GET /api/admin/dashboard/recent-orders?limit=5` |

`GET /api/admin/dashboard/overview` → `data`：
```json
{
  "totalUsers": 12846,      "totalUsersDelta": 3.2,
  "activeUsersToday": 1932, "activeUsersDelta": 8.4,
  "revenueToday": 48210.00, "revenueDelta": 12.6,
  "creditsUsedToday": 9260000, "creditsUsedDelta": -2.1
}
```

`GET /api/admin/dashboard/revenue-trend?days=14` → `data`：
```json
[ { "date": "2026-09-01", "revenue": 38210.00 } ]
```

`GET /api/admin/dashboard/model-share?range=today` → `data`：
```json
[ { "modelName": "TT Image 2 系列", "calls": 48210, "percent": 38.0 } ]
```

`GET /api/admin/dashboard/recent-orders?limit=5` → `data`：数组，元素同 ③ 账单行。

> 环比 `*Delta` 的算法冻结：`(今天 - 昨天) / 昨天 * 100`，昨天为 0 时返回 `null`（前端显示「—」，不要显示 Infinity）。

---

## ② 用户管理 `pg-users`

原型元素：搜索（用户名/邮箱）+ 状态筛选 + 加算力 + 冻结/解冻 + 重置密码。

**原型列 → 字段**

| 原型列 | 字段 | 落地说明 |
|---|---|---|
| UID | `id` | 直接用 `t_user.id`，不新增 UID 列 |
| 用户（头像+昵称+账号） | `avatar` `nickname` `username` `phone` | 昵称空时回退 `username` |
| 邮箱 | `email` | 支持关键词检索 |
| 算力余额 | `credits` | `t_user.credits` |
| 状态 | `status` + `statusLabel` | 沿用 `1`/`0` → 正常/冻结 |
| 注册日期 | `createdAt` | `BaseEntity.createdAt` |
| 最近活跃 | `lastActiveAt` | ⚠️ **需新增列 `t_user.last_active_at`**，由 `AuthInterceptor` 鉴权成功时节流更新（距上次 >5 分钟才写，避免每个请求都 UPDATE） |
| 操作 | 加算力 / 冻结·解冻 / 重置密码 | 三个接口，见下 |

**接口**

| 方法 | 路径 | 入参 | 说明 |
|---|---|---|---|
| GET | `/api/admin/users?page&pageSize&keyword&status` | `keyword` 匹配用户名/邮箱；`status` 传 1/0 | `PageResult<AdminUserResponse>` |
| POST | `/api/admin/users/{id}/credits` | `{delta}` | 调整算力；调整后余额不能小于 0 |
| PUT | `/api/admin/users/{id}/status` | `{status}` | 1 正常 / 0 冻结；冻结时吊销该用户全部旧令牌 |
| POST | `/api/admin/users/{id}/reset-password` | `{newPassword?}` | 不传则生成随机密码，并在响应中返回一次；旧令牌立即失效 |

`AdminUserResponse`：
```json
{
  "id": 1, "username": "demo", "nickname": "未知仙女座", "email": "demo@example.com",
  "phone": "186****3000", "credits": 10000,
  "status": 1, "statusLabel": "正常", "role": "USER",
  "createdAt": "2026-03-14T10:20:30", "lastActiveAt": "2026-09-14T12:41:00"
}
```

用户管理使用 6510-6519 错误码子段：用户不存在、算力调整非法、状态非法、密码非法、参数非法和无权限。

---

## ③ 账单管理 `pg-bills`

原型元素：分段筛选（全部/充值/消耗/退款）+ 日期区间 + 导出对账单；表格 8 列；底部汇总行。

**原型列 → 字段**：`orderNo` / `userName` / `type`(RECHARGE|CONSUME|REFUND) / `amount` / `creditsDelta` / `channel` / `status` / `createdAt`

**接口**

| 方法 | 路径 | 入参 | 返回 |
|---|---|---|---|
| GET | `/api/admin/bills?page&pageSize&type&startDate&endDate&keyword` | `type` 空=全部 | `PageResult<BillResponse>` |
| GET | `/api/admin/bills/summary?date=2026-09-14` | — | `{ "count": 12842, "totalRecharge": 48210.00, "totalConsume": 39606.00 }` |
| POST | `/api/admin/bills/recharge` | `{userId, amount, channel, remark}` | 模拟充值：写 `RECHARGE` 流水 + 给用户加算力（`amount / creditPrice`） |
| POST | `/api/admin/bills/{id}/refund` | `{remark}` | 写 `REFUND` 流水 + 扣回算力 |
| GET | `/api/admin/bills/export` | 同列表筛选 | CSV 流 |

`BillResponse`：
```json
{
  "id": 1, "orderNo": "P20260914001", "userId": 100231, "userName": "未知仙女座",
  "type": "RECHARGE", "typeLabel": "充值", "amount": 198.00, "creditsDelta": 200,
  "channel": "微信支付", "status": "SUCCESS", "statusLabel": "成功",
  "createdAt": "2026-09-14T12:41:00"
}
```
> 订单号规则冻结：充值 `P` + `yyyyMMdd` + 3 位序号；消耗 `C` + …；退款 `R` + …（服务端生成，前端只展示）。

---
## ④ 大模型配置 `pg-models` —— 需求 3.1 的正式版，**后端核心**

原型元素：搜索 + 类型筛选 + 「接入新模型」按钮；表格 9 列（含「上架」开关 + 编辑/调价）。

**原型列 → 字段**

| 原型列 | 字段 | 说明 |
|---|---|---|
| 模型（名称 + 厂商） | `name` / `vendor` | |
| 类型徽章 | `type` + `typeLabel` | CHAT/IMAGE/VIDEO/AUDIO |
| 渠道 | `channel` | 如 `DE-TT-oai-pro` |
| 输入价 / 百万token | `inputPrice` | 随 `priceUnit` 变（SECOND 时表示 元/秒） |
| 输出价 / 百万token | `outputPrice` | CALL 计价时可为空 |
| 今日调用 | `todayCalls` | 聚合 `t_call_log` |
| 成功率 | `successRate` | 聚合 `t_call_log`，无数据返回 `null`（前端显示「—」） |
| 上架开关 | `online` | **必须能点，点完立刻落库** |
| 操作 编辑 / 调价 | — | 见接口表 |

**接口**

| 方法 | 路径 | 入参（要点） |
|---|---|---|
| GET | `/api/admin/providers?page&pageSize&type&keyword` | `keyword` 匹配 名称/厂商/渠道 |
| POST | `/api/admin/providers` | `{name, vendor, type, channel, modelName, baseUrl, providerImpl, inputPrice, outputPrice, priceUnit, timeoutSeconds}` |
| GET | `/api/admin/providers/{id}` | 详情：基础信息 + 鉴权 + 请求模板 + 响应模板（一次返回，供弹窗/抽屉用） |
| PUT | `/api/admin/providers/{id}` | 基础信息 |
| PUT | `/api/admin/providers/{id}/auth` | `{authType, apiKey, headerName, headerValue, oauthTokenUrl, oauthClientId, oauthClientSecret}` |
| PUT | `/api/admin/providers/{id}/request-template` | `{method, path, contentType, queryJson, headersJson, bodyJson}` |
| PUT | `/api/admin/providers/{id}/response-template` | `{successPath, resultUrlPath, thumbPath, errorPath, taskIdPath}` |
| **POST** | **`/api/admin/providers/{id}/test`** | `{prompt?}` → 见下，**需求 3.1 第 5 步，答辩必演** |
| PUT | `/api/admin/providers/{id}/online` / `/offline` | — |
| PUT | `/api/admin/providers/{id}/pricing` | `{inputPrice, outputPrice, priceUnit}` |
| DELETE | `/api/admin/providers/{id}` | 逻辑删除（契约补充能力，方便运营清理误接入的模型） |

> 说明：`todayCalls` / `successRate` 依赖调用日志表（P3 调试面板才建）。P1 阶段列表返回 `0` / `null`，前端显示「—」。

**`providerImpl` 是这一页的关键**：它决定"走哪个 Java 实现"，取值与 `ProviderNames` 对齐：

| `providerImpl` | 走哪个实现 | 用途 |
|---|---|---|
| `mock` | `MockAiProvider` | 无密钥也能演示（**默认**，别删） |
| `stable-diffusion` | `StableDiffusionProvider` | 已有实现，接 SD WebUI |
| `http` | **新增 `HttpApiProvider`** | **配置驱动**：读本表的请求/响应模板发 HTTP，接任何兼容服务商 |

连通性测试响应 `data`：
```json
{
  "success": true, "httpStatus": 200, "elapsedMs": 1843,
  "extractedResultUrl": "http://xx/out.png", "extractedError": null,
  "rawResponse": "{\"data\":[{\"url\":\"...\"}]}", "rawResponseTruncated": false,
  "message": "连通性正常，已按响应模板提取到结果地址"
}
```
- `rawResponse` **截断到 2000 字符**，超长置 `rawResponseTruncated = true`
- 测试失败不抛异常，用 `success = false` + `message` 返回（否则前端只能弹一个「未知错误」）

**模板变量冻结**（请求模板里可用，`HttpApiProvider` 负责替换）：

```
{{prompt}} {{negativePrompt}} {{modelName}} {{width}} {{height}}
{{steps}} {{cfgScale}} {{seed}} {{refImageUrl}} {{taskNo}} {{apiKey}}
```
> 这些变量名**就是 `AiTaskRequest` 的字段名**，新增变量必须同步改 `AiTaskRequest` 与 `HttpApiProvider`，不许前端自己造。

---

## ⑤ 智能体 Skill 配置 `pg-agents` —— 需求 3.5 工作台，**后端核心**

原型是**两层结构**，两层的接口都要做。

### 第一层：智能体列表

原型列 → 字段：

| 原型列 | 字段 |
|---|---|
| 智能体（名称 + 英文标识） | `name` / `code` |
| 分类 | `category` + `categoryLabel` |
| 编排模型数 | `modelCount` |
| 已启用 Skill | `enabledSkillCount` / `skillCount`（原型显示「4」，列表页只展示启用数） |
| 今日调用 | `todayCalls` |
| 平均耗时 | `avgElapsedMs` |
| 成功率 | `successRate` |
| 状态 | `status` + `statusLabel` |
| 操作 | 配置 / 调试 / 复制 / 下线·发布 |

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/admin/agents?page&pageSize&keyword&category&status` | 列表 |
| POST | `/api/admin/agents` | `{name, code, category, description, icon}` 新建（原型弹窗 5 个字段） |
| POST | `/api/admin/agents/import` | 导入配置 JSON（原型有「导入配置 JSON」按钮，体量小，可用文件上传） |
| POST | `/api/admin/agents/{id}/duplicate` | 复制 |
| DELETE | `/api/admin/agents/{id}` | 逻辑删除（契约补充能力） |
| POST | `/api/admin/agents/{id}/publish` / `/offline` | 发布 / 下线 |
| GET | `/api/admin/agents/{id}/versions` | 版本列表 `[{versionNo, createdAt, remark, operator}]` |
| POST | `/api/admin/agents/{id}/versions/{versionNo}/rollback` | 回滚 |

### 第二层：编排详情

原型是**三栏 + 底部预览**，接口按三栏拆：

| 原型栏位 | 内容 | 对应 |
|---|---|---|
| 左栏 基础信息 | 名称 / 标识 / 分类 / **绑定模型** / 头像 emoji / System Prompt / 开场白 | `PUT /api/admin/agents/{id}` |
| 中栏 Skill 编排 | Skill 列表（启用开关 + 排序）+ 「添加 Skill」 | `PUT /api/admin/agents/{id}/nodes`、`GET /api/admin/tools`、`POST /api/admin/agents/{id}/nodes` |
| 右栏 调用与计费 | 单次基础算力 / 各 Skill 附加算力汇总 / 最大轮次 / 超时 / 每日上限 / 两个开关 | 同 `PUT /api/admin/agents/{id}` |
| 底部 调用流程实时预览 | 静态示意 → 做成**真预览** | `POST /api/admin/agents/{id}/preview` |

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/admin/agents/{id}` | 详情：`{ 基础信息, nodes: [...], billing: {...} }` |
| PUT | `/api/admin/agents/{id}` | 保存编排（原型「保存编排」按钮）。**整体覆盖式保存**：前端提交完整 `nodes` 数组，服务端按 `nodeKey` 对齐增删改，并**自动存一个版本** |
| PUT | `/api/admin/agents/{id}/nodes` | 工作台保存编排的语义化路由，请求体与行为同 `PUT /api/admin/agents/{id}` |
| POST | `/api/admin/agents/{id}/nodes` | 添加一个节点（原型「添加 Skill」弹窗） |
| PUT | `/api/admin/agents/{id}/nodes/{nodeId}` | 单节点配置（含启停、排序、条件路由关键词） |
| DELETE | `/api/admin/agents/{id}/nodes/{nodeId}` | 删除节点 |
| **GET** | **`/api/admin/tools`** | **统一工具库**（冻结项 ②），返回所有可编排的能力：内置 8 类 + 已上架模型 + 已启用 MCP 工具 + 知识库 |
| POST | `/api/admin/agents/{id}/preview` | 跑一次预览，返回每个节点的执行轨迹（原型底部聊天预览） |

**保存编排请求体**（这是工作量最大的一段，字段先冻结）：
```json
{
  "name": "跨境电商选品助手", "code": "cross-border-picker",
  "category": "MARKETING", "description": "…", "icon": "🤖",
  "modelProviderId": 3,
  "systemPrompt": "你是跨境电商选品专家…",
  "greeting": "你好，告诉我目标市场与品类…",
  "billing": {
    "baseCost": 2.0, "maxRounds": 8, "timeoutSeconds": 60, "dailyQuota": 5000,
    "allowUserSkill": false, "logFullConversation": true
  },
  "nodes": [
    {
      "nodeKey": "n1", "name": "意图识别", "orderIndex": 0, "enabled": true,
      "toolSource": "MODEL", "toolRefId": 3, "toolKey": "MODEL_CALL",
      "paramsJson": "{\"prompt\":\"识别用户意图\"}",
      "routeKeywords": "选品,爆品", "routeTargetKey": "n3"
    }
  ]
}
```

`toolSource / toolRefId / toolKey` 三个字段**就是冻结项 ②，一个都不能少**。

---
## ⑥ 算力使用 `pg-usage`

原型元素：4 张卡 + 分模型消耗表（6 列）+ 用户消耗 TOP 8。

| 方法 | 路径 | 返回 `data` |
|---|---|---|
| GET | `/api/admin/credits/stats?range=today` | `{ "todayUsed": 9260000, "todayDelta": -2.1, "yesterdayUsed": 9460000, "monthUsed": 128000000, "monthDelta": 6.8, "platformStock": 460000000, "stockDays": 36 }` |
| GET | `/api/admin/credits/by-model?range=today` | `[ { "modelName": "TT Image 2 系列", "calls": 48210, "inputTokens": 3120000000, "outputTokens": 980000000, "creditsUsed": 3520000, "percent": 38.0 } ]` |
| GET | `/api/admin/credits/top-users?limit=8` | `[ { "rank": 1, "userId": 100072, "userName": "短视频工厂", "creditsUsed": 1864000 } ]` |

> `range` 取值冻结：`today` / `yesterday` / `month` / `all`。`inputTokens`/`outputTokens` 模型侧拿不到就返回 `null`，前端显示「—」（原型里「即梦 3.5 Pro」那行就是「—」）。

---

## ⑦ 系统设置 `pg-settings`

原型元素：平台参数（4 个输入框 + 保存）+ 公告与维护（公告文本 + 3 个开关 + 发布公告）。

| 方法 | 路径 | 入参 / 返回 |
|---|---|---|
| GET | `/api/admin/settings` | 见下 |
| PUT | `/api/admin/settings` | 同结构；字段均可选，支持单项或批量更新 |
| PUT | `/api/admin/settings/switches` | `{signupEnabled, rechargeEnabled, maintenanceMode}` |
| POST | `/api/admin/announcements` | `{content}` |

`data`：
```json
{
  "platformName": "星枢 AI 聚合平台",
  "signupBonusCredits": 10000,
  "generationCostCredits": 10,
  "rechargeBonusPercent": 5.0,
  "creditPrice": 1.00,
  "announcement": "TT Image 2.5 官转通道已上线…",
  "announcementEnabled": true,
  "signupEnabled": true,
  "rechargeEnabled": true,
  "maintenanceMode": false,
  "aiDebugLogEnabled": false
}
```

系统设置使用 `6520-6529` 错误码子段：更新参数非法返回 `6520`，空更新返回 `6521`，非管理员修改返回 `6522`。
> ⚠️ **`signupBonusCredits` 必须接管现有数据初始化**：现在「新用户送 10000 点」硬编码在 3 个地方（`User` 实体默认值、`AuthService` 注册、`DataSeeder`）。改成读本设置项，**三处一起改**（这是 `docs/HANDOFF.md` 里点名的坑）。

当前落地：注册接口已读取 `signupEnabled` / `signupBonusCredits`；创建生成任务已读取 `maintenanceMode` / `generationCostCredits`；执行任务时由 `aiDebugLogEnabled` 控制额外诊断日志。

---

## ⑧ 调试面板 `pg-debug` —— 需求 3.2（原型没画，新页）★后端线

新页面按原型设计语言画（工具栏 + 面板 + 表格 + 分页）。

| 需求 3.2 的能力 | 接口 |
|---|---|
| 单节点调试 | `POST /api/admin/debug/node` ← `{agentId, nodeId, input}` |
| 全链路调试 | `POST /api/admin/debug/chain` ← `{agentId, input, saveLog?}` |
| 对话式调试 | `POST /api/admin/debug/chat` ← `{agentId, message, sessionId}` |
| 日志追踪 | `GET /api/admin/debug/logs?agentId&taskNo&status&page&pageSize` |
| 版本对比 | `GET /api/admin/debug/compare?agentId&versionA&versionB&input` |
| 回归测试 | `POST /api/admin/debug/regression`（跑用例集）、`GET/POST /api/admin/debug/regression/cases` |

**统一执行轨迹结构**（6 个接口共用，前端只写一套渲染）：
```json
{
  "sessionId": "s-20260914-001", "totalElapsedMs": 3241, "totalCredits": 5.8,
  "success": true, "finalOutput": "已为你锁定 3 款高潜品类…",
  "nodes": [
    {
      "nodeId": 11, "nodeKey": "n1", "name": "联网搜索", "toolKind": "WEB_SEARCH",
      "success": true, "elapsedMs": 812, "credits": 1.2,
      "input": "东南亚夏季家居爆品", "output": "抓取到 12 条热销数据",
      "errorMessage": null
    }
  ]
}
```
> `totalCredits` 是**演示算力**，不扣真实余额（调试不该花用户的钱），但要在页面标明「调试消耗不扣费」。

---
## ⑨ MCP 接入 `pg-mcp` —— 需求 3.3（原型没画，新页）★后端线

需求 3.3 的五步 → 五个接口：

| 需求步骤 | 接口 |
|---|---|
| 1 注册 MCP Server | `POST /api/admin/mcp/servers` ← `{name, transport, endpoint, command, envJson, authType, apiKey}` |
| 2 发现能力与参数定义 | `POST /api/admin/mcp/servers/{id}/discover` → 自动拉取工具列表落库 |
| 3 选择性启用 | `GET /api/admin/mcp/tools?serverId=` + `PUT /api/admin/mcp/tools/{id}/enable` ← `{enabled}` |
| 4 映射到平台 | 映射关系由 `t_mcp_tool.tool_key` 承载（见冻结项 ②），无需单独接口 |
| 5 测试调用 | `POST /api/admin/mcp/tools/{id}/invoke` ← `{params}` |

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/admin/mcp/servers?page&pageSize` | 列表（含 `toolCount` / `enabledToolCount` / `lastDiscoverAt` / `status`） |
| PUT | `/api/admin/mcp/servers/{id}` | 编辑连接信息 |
| DELETE | `/api/admin/mcp/servers/{id}` | 删除（连带禁用其工具） |
| GET | `/api/admin/mcp/servers/{id}/tools` | 工具列表，含 `inputSchema`（JSON 字符串，原样透传别解析） |

`McpToolResponse`：
```json
{
  "id": 5, "serverId": 2, "toolName": "web_search", "toolKey": "mcp_2_web_search",
  "displayName": "联网搜索", "description": "…", "enabled": true,
  "inputSchema": "{\"type\":\"object\",\"properties\":{...}}",
  "lastInvokedAt": "2026-09-14T12:00:00"
}
```

> 冻结：`toolKey` 生成规则 = `mcp_{serverId}_{toolName}`。工作台节点引用它时 `toolSource = 'MCP'` + `toolRefId = mcpTool.id`。

---

## ⑩ 知识库 `pg-kb` —— 需求 3.4.1（原型没画，新页）★后端线

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/admin/kbs?page&pageSize&keyword` | 列表：`{id, name, description, embeddingModel, documentCount, chunkCount, updatedAt, boundAgentCount}` |
| POST | `/api/admin/kbs` | `{name, description, embeddingModel}`（需求：名称/描述/向量化模型） |
| GET/PUT/DELETE | `/api/admin/kbs/{id}` | 详情 / 修改 / 删除 |
| POST | `/api/admin/kbs/{id}/documents` | 录入，`type` 决定分支，见下 |
| POST | `/api/admin/kbs/{id}/documents/upload` | multipart `file`；当前支持 TXT/MD/CSV/JSON/HTML |
| GET | `/api/admin/kbs/{id}/documents?page` | 文档列表 |
| DELETE | `/api/admin/kbs/{id}/documents/{docId}` | 删除文档（连带 chunk） |
| POST | `/api/admin/kbs/{id}/reindex` | 重新分段 + 向量化（全量替换） |
| POST | `/api/admin/kbs/{id}/search` | `{query, topK}` → 检索测试 |
| PUT | `/api/admin/kbs/{id}/bind-agents` | `{agentIds: [1,2]}` 绑定智能体 |

> 文件解析说明：当前离线环境未引入 PDFBox/POI，PDF/Word/Excel 会返回明确的「待装依赖」提示；
> 装上依赖后在 `KnowledgeBaseService.uploadDocument` 里扩展即可，接口形状不变。

**录入的 4 种方式（需求 3.4.1）**

| `type` | 入参 | 解析方式 |
|---|---|---|
| `TEXT` | `{name, content}` | 直接入库 |
| `FILE` | `multipart: file` | TXT/MD 直接读；PDF → **PDFBox**；Word/Excel → **Apache POI** |
| `URL` | `{name, url}` | 抓取网页正文（用 JDK HttpClient + 简单正文提取） |
| `API_SYNC` | `{name, syncUrl, cron, headersJson}` | 定时拉取（Spring `@Scheduled`） |

检索测试返回：
```json
{
  "query": "平台规则", "elapsedMs": 42,
  "items": [ { "chunkId": 88, "documentName": "平台规则.pdf", "content": "…", "score": 0.87 } ]
}
```

> ⚠️ **第一版不要上向量库**（见 `ADMIN_PLAN.md` 坑 5）：用 MySQL 全文索引 / `LIKE` + 关键词打分把「分段 → 检索 → 引用」跑通就够。`embeddingModel` 字段先存着不用。

---

## ⑪ 素材库后台 `pg-materials` —— 需求 3.4.2（原型没画，新页）★前端线

C 端已有「上传 / 我的 / 删除」，这里只做**后台视角的增强**，别重复实现。

**接口**

| 方法 | 路径 | 入参 | 返回 |
|---|---|---|---|
| GET | `/api/admin/materials?page&pageSize&keyword&categoryId&tagIds&type&startDate&endDate` | `tagIds` 可重复；父分类/父标签筛选自动包含后代 | `PageResult<MaterialAdminResponse>` |
| GET | `/api/admin/materials/{id}` | — | `MaterialAdminResponse` |
| POST | `/api/admin/materials` | `{title,categoryId,tagIds,fileUrl,thumbUrl,mimeType,fileSize,width,height}` | `MaterialAdminResponse` |
| PUT | `/api/admin/materials/{id}` | 上述字段（均可部分更新）+ `{newVersion,changeNote}` | `MaterialAdminResponse` |
| DELETE | `/api/admin/materials/{id}` | — | 逻辑下架，`data: null` |
| GET | `/api/admin/material-categories` | — | `{categories:[树],tags:[树]}` |
| GET | `/api/admin/materials/{id}/versions` | — | `MaterialVersionResponse[]` |
| POST | `/api/admin/materials/{id}/versions/{versionNo}/restore` | `{changeNote?}` | 恢复后生成新版本并返回 `MaterialAdminResponse` |

`MaterialAdminResponse`：
```json
{
  "id": 1, "title": "春季新品主图", "categoryId": 3,
  "categoryName": "商品主图", "categoryPath": "电商视觉 / 商品主图",
  "tags": [{ "id": 8, "name": "新品", "parentId": 7 }],
  "fileUrl": "/upload/material_xxx.png", "thumbUrl": null,
  "mimeType": "image/png", "mediaType": "IMAGE",
  "fileSize": 1887437, "width": 1920, "height": 1080,
  "version": 2, "createdAt": "2026-10-19T10:12:00",
  "updatedAt": "2026-10-27T11:30:00"
}
```

分类和标签使用同一套树节点形状 `{id,name,parentId,sortOrder,children}`。
`categoryId` 只能指向 `categories` 节点，`tagIds` 只能指向 `tags` 节点。
素材名称 1-100 字；文件地址支持 `/upload/...`、`http://`、`https://`。

**错误码（素材专用子段 6530-6539）**

| code | 枚举名 | message |
|---|---|---|
| 6530 | MATERIAL_NOT_FOUND | 素材不存在或已下架 |
| 6531 | MATERIAL_PARAMETER_INVALID | 素材参数不合法 |
| 6532 | MATERIAL_TITLE_INVALID | 素材名称不合法 |
| 6533 | MATERIAL_FILE_INVALID | 素材文件地址不合法 |
| 6534 | MATERIAL_CATEGORY_NOT_FOUND | 素材分类不存在 |
| 6535 | MATERIAL_TAG_NOT_FOUND | 素材标签不存在 |
| 6536 | MATERIAL_VERSION_NOT_FOUND | 素材版本不存在 |
| 6537 | MATERIAL_FORBIDDEN | 没有素材库管理权限 |

> 新增实体会与现有 `t_material` 共存：C 端上传接口继续写 `name/url`，管理端补充
> `title/category_id/version` 与标签关联表；C 端 `/api/materials/**` 契约不变。

---

## ⑫ API 网关 `pg-gateway` —— 需求 1.3（原型没画，新页）★后端线

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/admin/gateway/endpoints` | 对外暴露的接口定义列表：`{id, name, method, path, agentId, authRequired, rateLimit, online, callCount}` |
| POST/PUT/DELETE | `/api/admin/gateway/endpoints[/{id}]` | 定义管理（把某个智能体包装成一个对外接口） |
| GET | `/api/admin/gateway/export/openapi` | 导出 OpenAPI 3.0 JSON 文件 |

> 这是**答辩加分项**：把「后台能对外暴露标准化接口」这件事证明出来即可，不必真做限流网关。

---
## ⑫.1 用户订单作品审核（M2）

> 该接口服务于用户端“接单 → 提交作品 → 审核 → 入账”的运营审核环节。
> 用户端接口契约完整字段以 `docs/api-user.md` §4 为准。

| 方法 | 路径 | 说明 |
|---|---|---|
| PUT | `/api/admin/submissions/{id}/review` | 审核用户提交的作品 |

请求体：

```json
{
  "decision": "APPROVED",
  "comment": "作品符合订单要求"
}
```

规则：

- 只有 `PENDING` 可以审核；
- `decision` 只能是 `APPROVED` / `REJECTED`；
- 审核记录写入 `t_review_record`；
- 审核通过后用户接单记录进入 `APPROVED`；
- 审核驳回后用户接单记录进入 `REJECTED`，允许重新提交；
- 同一 submission 重复审核返回 `5606`。

---

## ⑬ 与现有 C 端代码的关系（**红线，动之前先读**）

管理端是**纯增量**，下面的东西一行都不许改坏：

| 不许动 | 原因 |
|---|---|
| `lib/` 全部 Flutter 代码 | App 11 个页面已跑通，改后端接口必须保证它们继续能跑 |
| `/api/**`（22 个 C 端接口）的 URL、入参、返回字段 | App 全靠它们 |
| `t_skill` 表结构与语义 | 它是**创作线路**（二次元插画/写实摄影…），App 首页在用；**不是**原型里的「Skill」 |
| `MockAiProvider` | 没有商用密钥，答辩出图/出视频全靠它 |
| `HarnessScheduler` / `TaskStateService` | 需求文档的 Harness 已完整实现 |

**唯一需要"改造"的现有文件（改造点已在冻结文档里写明）**：

| 文件 | 改造内容 |
|---|---|
| `security/AuthInterceptor.java` | 加 `/api/admin/**` 的 ADMIN 校验；dev-token 不放行 admin |
| `ai/AiProviderRouter.java` | **新增** `routeByConfig(AiProviderConfig)` 方法；**保留**原 `route(String)` 不动（App 的 6 条线路继续走它） |
| `init/DataSeeder.java` | 补 admin 演示数据（**拆成 `AdminSeederA` / `AdminSeederB` 两个类，别都往里塞**） |
| `entity/User.java` | 新增列 `last_active_at` |
| `common/ErrorCode.java` | 追加 §0.4 的新错误码 |

---

## ⑭ 自测顺序（Postman / curl，前一个的产物给后一个用）

```
1.  POST /api/auth/login            {"username":"admin","password":"admin123"}   → 拿 token
2.  GET  /api/admin/auth/profile    带 Bearer <token>                            → 确认 role=ADMIN
3.  GET  /api/admin/dashboard/overview                                          → 4 张卡有数
4.  GET  /api/admin/users?page=1&pageSize=10                                    → 分页结构 list/page/pageSize/total
5.  POST /api/admin/providers       接一个 providerImpl=mock 的模型
6.  POST /api/admin/providers/{id}/test                                         → 连通性测试返回 success
7.  PUT  /api/admin/providers/{id}/online                                       → 上架
8.  GET  /api/admin/tools                                                       → 工具库能看到刚上架的模型
9.  POST /api/admin/agents          新建智能体 → 拿到 id
10. PUT  /api/admin/agents/{id}     保存编排（带 nodes 数组）
11. POST /api/admin/agents/{id}/publish
12. POST /api/admin/debug/chain     {"agentId":1,"input":"测试"}                 → 看到每个节点的轨迹
13. POST /api/admin/kbs + documents 传一份 TXT/MD → POST /kbs/{id}/search      → 检索出片段（PDF 需装 PDFBox）
14. GET  /api/admin/bills?page=1    账单流水
15. GET  /api/admin/settings        平台参数
```

**反向验证（确认没把 App 搞坏）**：

```
16. GET  /api/skills?type=TEXT_TO_IMAGE      → 仍是 6 条线路
17. POST /api/creation/text-to-image         → 仍能建任务
18. flutter run -d chrome                    → App 首页/文生图/任务/画廊仍正常
```

---

## ⑮ 变更记录

| 日期 | 版本 | 改动 | 谁 |
|---|---|---|---|
| 2026-10-14 | v1 | 首次冻结：通用约定 + 错误码分段 + 枚举字典 + 12 个页面的完整接口契约 | — |
| 2026-10-22 | v1.1 | P1 实现：模型配置 CRUD / 鉴权 / 请求响应模板 / 连通性测试 / HttpApiProvider；补充 DELETE 接口；注明 todayCalls/successRate 在 P3 前返回 0/null | 后端线 |
| 2026-10-27 | v1.3 | 系统设置落地：增加单次生成消耗、公告启用、AI 调试日志开关；PUT 支持部分更新；使用 6520-6529 错误码 | 前端线 |
| 2026-10-22 | v1.2 | P2 实现：Agent / AgentNode / AgentVersion、编排保存、发布/复制/版本回滚、统一工具库、编排预览；补充 DELETE /api/admin/agents/{id} | 后端线 |
| 2026-10-27 | v1.4 | 素材库落地：分类/多级标签树、分页检索、新增/编辑/下架、版本快照与恢复；使用 6530-6539 错误码 | 前端线 |
| 2026-10-27 | v1.5 | 智能体工作台前端落地：增加 `PUT /api/admin/agents/{id}/nodes` 语义化保存别名，保留原 `PUT /api/admin/agents/{id}` 兼容 | 前端线 |
| 2026-10-28 | v1.6 | P3 调试面板 + P4 MCP 接入：CallLog / 回归用例、单节点·全链路·对话式·版本对比·回归、MCP 注册/发现/启用/试调用、工具库接入 MCP；调试日志新增 `status` 字段 | 后端线 |
| 2026-10-28 | v1.7 | P5 知识库落地：KnowledgeBase/KbDocument/KbChunk、文本/文件/URL/API 同步、分段检索、绑定智能体；新增 documents/upload；工具库接入知识库；当前文件解析支持 TXT/MD/CSV/JSON/HTML | 后端线 |
| 2026-10-28 | v1.8 | P7 运营落地：CreditTransaction 流水、账单/充值/退款/导出、概览/营收趋势/调用占比、算力统计/TOP 用户；建任务与后台加算力自动写流水；API 网关接口定义 + OpenAPI 导出 | 后端线 |
| 2026-10-30 | v1.9 | M2 用户订单作品审核：`PUT /api/admin/submissions/{id}/review`，审核状态回写 submission/acceptance，并使用 5601～5607 错误码 | 后端线 |

> 规则：接口一旦开工，**改字段名 = 改契约**，必须两人同时改代码 + 在这里记一行。
