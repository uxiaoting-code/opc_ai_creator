# OPC AI 后台 · 三项共用模型冻结 + 共享文件切分

> 冻结日期：2026-10-14（v1）
> 配套文件：`docs/api-admin.md`（接口契约）、`docs/ADMIN_PLAN.md`（盘点/顺序/分工）
> 分工口径：**按"前后端"分**（一人 `server/`，一人 `admin-web/` + `lib/`），归属见 §4.1
>
> **为什么要有这份文件**：接口契约只解决"接口长什么样"。如果两人各写各的数据结构，
> 到合并那天才会发现工作台节点引用不了模型配置、MCP 工具、内置工具 ——
> 它们各自成了两套东西 —— 那就白干了。**下面三项必须在动手前定死。**

---

## 冻结项 ① `AiProviderConfig`（模型 / API 配置）

对应需求文档 3.1 的六步配置流水线；对应原型「大模型配置」页。

### 1.1 Java 实体字段（`com.opc.server.entity.AiProviderConfig`）

```java
/** 模型名称，如 TT Image 2 */          private String  name;
/** 厂商，如 字节跳动 */                 private String  vendor;
/** CHAT / IMAGE / VIDEO / AUDIO */      private String  type;          // 用 String + 校验，别用 @Enumerated（脏数据会 500，参照 SkillTypeConverter 的教训）
/** 渠道标识，如 DE-TT-oai-pro，唯一 */  private String  channel;
/** 传给服务商的模型名，如 sd-xl-anime */ private String  modelName;
/** 服务地址 */                          private String  baseUrl;
/** 走哪个 Java 实现：mock / stable-diffusion / http */ private String providerImpl = "mock";

// ---- 鉴权（需求 3.1 第 2 步）----
/** NONE / API_KEY / OAUTH / CUSTOM_HEADER */ private String authType = "NONE";
private String apiKey;
private String headerName;      // CUSTOM_HEADER 用
private String headerValue;
private String oauthTokenUrl;   // OAUTH 预留
private String oauthClientId;
private String oauthClientSecret;

// ---- 请求模板（需求 3.1 第 3 步）----
private String requestMethod = "POST";   // GET / POST
private String requestPath;              // 如 /sdapi/v1/txt2img，支持 {{modelName}} 变量
private String requestContentType = "application/json";
private String requestQueryJson;         // {"key":"{{apiKey}}"} 或 null
private String requestHeadersJson;       // 自定义请求头
private String requestBodyJson;          // 含 {{prompt}} {{width}} 等变量，见 api-admin.md §④

// ---- 响应模板（需求 3.1 第 4 步）----
private String responseSuccessPath;      // 如 data.0.url（点号路径，数字段表示数组下标）
private String responseResultUrlPath;
private String responseThumbPath;
private String responseErrorPath;
private String responseTaskIdPath;       // 异步服务商回查用

// ---- 计价与状态 ----
private java.math.BigDecimal inputPrice;
private java.math.BigDecimal outputPrice;
/** TOKEN / SECOND / CALL */ private String priceUnit = "TOKEN";
private Integer timeoutSeconds = 180;
/** 上架开关：true 才允许被智能体节点引用 */ private Boolean online = false;
private Integer sortOrder = 0;
private String remark;
private Boolean deleted = false;
```

### 1.2 建表语句（追加到 `server/docs/schema.sql` 末尾）

```sql
-- =============================================================================
--  8. t_ai_provider_config 模型/API 配置表（管理端新增，需求 3.1）
--     与 t_skill 的关系：t_skill 是「创作线路」（面向 App 用户），
--     本表是「可接入的模型通道」（面向运营人员）。两者不是一回事，不要合并。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_ai_provider_config` (
  `id`                     BIGINT        NOT NULL AUTO_INCREMENT COMMENT '配置ID',
  `name`                   VARCHAR(100)  NOT NULL                COMMENT '模型名称，如 TT Image 2',
  `vendor`                 VARCHAR(50)            DEFAULT NULL   COMMENT '厂商，如 字节跳动',
  `type`                   VARCHAR(20)   NOT NULL               COMMENT 'CHAT/IMAGE/VIDEO/AUDIO',
  `channel`                VARCHAR(50)            DEFAULT NULL   COMMENT '渠道标识，如 DE-TT-oai-pro',
  `model_name`             VARCHAR(100)           DEFAULT NULL   COMMENT '传给服务商的模型名',
  `base_url`               VARCHAR(255)           DEFAULT NULL   COMMENT '服务地址',
  `provider_impl`          VARCHAR(50)   NOT NULL DEFAULT 'mock' COMMENT '走哪个Java实现：mock/stable-diffusion/http',
  `auth_type`              VARCHAR(20)   NOT NULL DEFAULT 'NONE' COMMENT 'NONE/API_KEY/OAUTH/CUSTOM_HEADER',
  `api_key`                VARCHAR(255)           DEFAULT NULL   COMMENT '密钥（展示时脱敏）',
  `header_name`            VARCHAR(100)           DEFAULT NULL   COMMENT '自定义头名',
  `header_value`           VARCHAR(255)           DEFAULT NULL   COMMENT '自定义头值',
  `oauth_token_url`        VARCHAR(255)           DEFAULT NULL,
  `oauth_client_id`        VARCHAR(100)           DEFAULT NULL,
  `oauth_client_secret`    VARCHAR(255)           DEFAULT NULL,
  `request_method`         VARCHAR(10)   NOT NULL DEFAULT 'POST',
  `request_path`           VARCHAR(255)           DEFAULT NULL   COMMENT '请求路径，支持 {{变量}}',
  `request_content_type`   VARCHAR(100)  NOT NULL DEFAULT 'application/json',
  `request_query_json`     VARCHAR(2000)          DEFAULT NULL,
  `request_headers_json`   VARCHAR(2000)          DEFAULT NULL,
  `request_body_json`      VARCHAR(4000)          DEFAULT NULL   COMMENT '请求体模板，含 {{prompt}} 等变量',
  `response_success_path`  VARCHAR(255)           DEFAULT NULL   COMMENT '成功判定路径，如 data.0.url',
  `response_result_url_path` VARCHAR(255)         DEFAULT NULL   COMMENT '结果地址提取路径',
  `response_thumb_path`    VARCHAR(255)           DEFAULT NULL,
  `response_error_path`    VARCHAR(255)           DEFAULT NULL   COMMENT '错误信息提取路径',
  `response_task_id_path`  VARCHAR(255)           DEFAULT NULL   COMMENT '异步任务ID路径',
  `input_price`            DECIMAL(10,4)          DEFAULT NULL,
  `output_price`           DECIMAL(10,4)          DEFAULT NULL,
  `price_unit`             VARCHAR(20)   NOT NULL DEFAULT 'TOKEN' COMMENT 'TOKEN/SECOND/CALL',
  `timeout_seconds`        INT           NOT NULL DEFAULT 180,
  `online`                 TINYINT       NOT NULL DEFAULT 0      COMMENT '1上架 0下线',
  `sort_order`             INT           NOT NULL DEFAULT 0,
  `remark`                 VARCHAR(500)           DEFAULT NULL,
  `deleted`                TINYINT       NOT NULL DEFAULT 0,
  `created_at`             DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`             DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_channel` (`channel`),
  KEY `idx_type_online` (`type`, `online`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='模型API配置表';
```

### 1.3 与现有 `AiProviderRouter` 的接线（**这条最要紧，关系到 App 会不会被搞坏**）

```
现有链路（App 的 6 条创作线路）：
  t_skill.provider ("mock"/"stable-diffusion")  →  AiProviderRouter.route(String)  →  AiProvider 实现
  ⚠️ 这条链路一行都不改，App 继续跑

新增链路（管理端配置出来的模型，给智能体节点用）：
  t_ai_provider_config.provider_impl  →  AiProviderRouter.routeByConfig(AiProviderConfig)  →  AiProvider 实现
  其中 providerImpl = "http" 时 → 新增的 HttpApiProvider（读本表的请求/响应模板发 HTTP）
```

- `AiProviderRouter` **只新增方法，不修改原方法签名**
- `AiTask.provider` 快照存的是 `providerImpl`（"mock"/"stable-diffusion"/"http"），语义与现在一致
- `HttpApiProvider` 的 `getName()` 返回 `"http"`，需要在 `ProviderNames` 里加一个常量

---
## 冻结项 ② 能力 / 工具统一抽象

### 2.1 为什么必须先冻结这个

工作台的一个"节点"= 调用一个"能力"。而这个能力有 **4 个来源**：

| 来源 | 谁做 | 例子 |
|---|---|---|
| `MODEL` | **后端** | ④ 里配置出来的模型（TT Image 2） |
| `KNOWLEDGE` | **后端** | ⑩ 里建的知识库（平台规则库） |
| `MCP` | **后端** | ⑨ 里注册的 MCP Server 暴露的工具（联网搜索） |
| `BUILTIN` | **后端** | 写死在代码里的 8 类内置工具（代码执行、数据查询…） |

**如果不统一，工作台就要维护 4 种节点类型**，工作台写完，以后每加一个 MCP 能力就得改一次 —— 越写越烂。

### 2.2 统一形状：`ToolRef`（三件套）

任何节点引用任何能力，都用这三个字段：

```
toolSource   // MODEL | KNOWLEDGE | MCP | BUILTIN
toolRefId    // 对应表的 id（BUILTIN 时为 null）
toolKey      // 工具标识：BUILTIN 用常量；MCP 用 mcp_{serverId}_{toolName}；MODEL/KNOWLEDGE 用 "MODEL_CALL"/"KB_RETRIEVE"
```

`toolName` **同时存一份快照**（`tool_name_snapshot`），这样某个模型被下线后，工作台仍然能显示出"这个节点原本引用的是谁"。

### 2.3 `ToolKind`：8 个能力类型（**直接照原型「添加 Skill」弹窗抄**）

原型弹窗的下拉就是这 8 项，一个不多一个不少：

| `kind` | 原型文案 | 默认 `toolSource` |
|---|---|---|
| `MODEL_CALL` | 模型调用 | MODEL |
| `WEB_SEARCH` | 联网搜索 | BUILTIN（或 MCP） |
| `KB_RETRIEVE` | 知识库检索 | KNOWLEDGE |
| `CODE_RUN` | 代码执行 | BUILTIN |
| `IMAGE_PROCESS` | 图像处理 | BUILTIN |
| `DB_QUERY` | 数据查询 | BUILTIN |
| `HTTP_REQUEST` | HTTP 请求 | BUILTIN（或 MCP） |
| `HUMAN_REVIEW` | 人工审核 | BUILTIN |

内置工具的 `toolKey` 常量（放 `com.opc.server.admin.tool.ToolKeys`）：

```java
WEB_SEARCH / CODE_RUN / IMAGE_PROCESS / DB_QUERY / HTTP_REQUEST / HUMAN_REVIEW
```

### 2.4 工作台只有一种节点表

```sql
-- =============================================================================
--  9. t_agent 智能体表（管理端新增，需求 3.5）
--     注意：与 t_skill（App 的创作线路）是完全不同的两个概念，不要混淆、不要合并。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_agent` (
  `id`                 BIGINT       NOT NULL AUTO_INCREMENT,
  `name`               VARCHAR(100) NOT NULL               COMMENT '智能体名称',
  `code`               VARCHAR(50)  NOT NULL               COMMENT '英文标识，用于API调用',
  `category`           VARCHAR(30)  NOT NULL DEFAULT 'OTHER' COMMENT 'CUSTOMER_SERVICE/MARKETING/DESIGN/DATA_ANALYSIS/OTHER',
  `description`        VARCHAR(500)          DEFAULT NULL,
  `icon`               VARCHAR(20)           DEFAULT NULL  COMMENT 'emoji 头像',
  `model_provider_id`  BIGINT                DEFAULT NULL  COMMENT '绑定模型，指向 t_ai_provider_config.id',
  `system_prompt`      TEXT                  DEFAULT NULL,
  `greeting`           VARCHAR(500)          DEFAULT NULL  COMMENT '开场白',
  `base_cost`          DECIMAL(10,2) NOT NULL DEFAULT 0    COMMENT '单次调用基础算力',
  `max_rounds`         INT          NOT NULL DEFAULT 8,
  `timeout_seconds`    INT          NOT NULL DEFAULT 60,
  `daily_quota`        INT          NOT NULL DEFAULT 5000,
  `allow_user_skill`   TINYINT      NOT NULL DEFAULT 0,
  `log_full_conversation` TINYINT   NOT NULL DEFAULT 1,
  `status`             VARCHAR(20)  NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT/PUBLISHED/OFFLINE',
  `current_version`    INT          NOT NULL DEFAULT 1,
  `today_calls`        INT          NOT NULL DEFAULT 0     COMMENT '今日调用（可由 t_call_log 聚合，先留列便于演示）',
  `avg_elapsed_ms`     BIGINT                DEFAULT NULL,
  `success_rate`       DECIMAL(5,2)         DEFAULT NULL,
  `deleted`            TINYINT      NOT NULL DEFAULT 0,
  `created_at`         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_category_status` (`category`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='智能体表';

-- =============================================================================
--  10. t_agent_node 智能体节点表（工作台编排的最小单元）
--      node 不区分「内置/模型/MCP/知识库」四种类型，统一用 tool_source + tool_ref_id 定位，
--      这样工作台只需要一套渲染逻辑，新增能力来源不用改工作台。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_agent_node` (
  `id`                  BIGINT       NOT NULL AUTO_INCREMENT,
  `agent_id`            BIGINT       NOT NULL,
  `node_key`            VARCHAR(50)  NOT NULL               COMMENT '节点标识，编排内唯一，如 n1',
  `name`                VARCHAR(100) NOT NULL               COMMENT '节点显示名，如 意图识别',
  `tool_source`         VARCHAR(20)  NOT NULL               COMMENT 'MODEL/KNOWLEDGE/MCP/BUILTIN',
  `tool_ref_id`         BIGINT                DEFAULT NULL  COMMENT '对应表id，BUILTIN 为 null',
  `tool_key`            VARCHAR(100) NOT NULL               COMMENT '工具标识，见 2.2',
  `tool_name_snapshot`  VARCHAR(100)          DEFAULT NULL  COMMENT '引用时的名称快照，防原对象被删后显示不出来',
  `params_json`         VARCHAR(4000)         DEFAULT NULL  COMMENT '节点参数',
  `enabled`             TINYINT      NOT NULL DEFAULT 1,
  `order_index`         INT          NOT NULL DEFAULT 0     COMMENT '顺序，从小到大执行',
  `route_keywords`      VARCHAR(255)          DEFAULT NULL  COMMENT '条件路由：命中这些关键词(逗号分隔)时改走下一节点',
  `route_target_key`    VARCHAR(50)           DEFAULT NULL  COMMENT '条件路由的目标 node_key',
  `created_at`          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agent_node` (`agent_id`, `node_key`),
  KEY `idx_agent_order` (`agent_id`, `order_index`),
  KEY `idx_tool` (`tool_source`, `tool_ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='智能体节点表';

-- =============================================================================
--  11. t_agent_version 智能体版本表（需求 3.5「版本保存和回滚」）
--     保存编排时自动存一份快照（nodes 全量 JSON），回滚 = 用快照覆盖当前编排。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_agent_version` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT,
  `agent_id`      BIGINT       NOT NULL,
  `version_no`    INT          NOT NULL,
  `snapshot_json` TEXT         NOT NULL COMMENT '整份编排快照（基础信息 + billing + nodes）',
  `remark`        VARCHAR(255)          DEFAULT NULL,
  `operator`      VARCHAR(50)           DEFAULT NULL COMMENT '谁保存的',
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agent_version` (`agent_id`, `version_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='智能体版本表';
```

### 2.5 工具库接口 `GET /api/admin/tools`（前后端唯一的交接口）

由**后端实现**（工作台要用），数据来自模型配置表 + MCP 工具表：

```json
[
  { "toolSource": "BUILTIN",   "toolRefId": null, "toolKey": "WEB_SEARCH",  "toolKind": "WEB_SEARCH",  "name": "联网搜索",   "enabled": true },
  { "toolSource": "MODEL",     "toolRefId": 3,    "toolKey": "MODEL_CALL",  "toolKind": "MODEL_CALL",  "name": "TT Image 2", "enabled": true },
  { "toolSource": "MCP",       "toolRefId": 5,    "toolKey": "mcp_2_web_search", "toolKind": "WEB_SEARCH", "name": "联网搜索(MCP)", "enabled": true },
  { "toolSource": "KNOWLEDGE", "toolRefId": 1,    "toolKey": "KB_RETRIEVE", "toolKind": "KB_RETRIEVE", "name": "平台规则库",  "enabled": true }
]
```

- 只返回 `online = true` 的模型、`enabled = true` 的 MCP 工具
- 返回形状**一旦冻结，以后接 MCP、接知识库都不用改前端**

### 2.6 条件路由（降级方案，别自研画布）

需求 3.5 要"条件路由"，但**不要自研拖拽画布**。用节点上两个字段实现：

```
route_keywords    "选品,爆品"      ← 当输入命中这些词
route_target_key  "n3"            ← 就跳过中间节点，直接走 n3
```

UI 形态：**列表 + 启用开关 + 上/下移按钮 + 这行的条件填两个输入框**（老师原型就是这个形态）。有余力再上 AntV X6。

---
## 冻结项 ③ 算力口径

### 3.1 三个数字，一次说清

| 概念 | 值 | 存在哪 |
|---|---|---|
| **算力的存储单位** | `点`，**整数**（`t_user.credits` 是 `Integer`） | `t_user.credits` |
| **扣费标准** | 文生图 10 点 / 图生视频 15 点 | `opc.harness.credits-per-task`，管理端设置可覆盖 |
| **算力单价** | 默认 `1.00 元 / 点` | 新增平台设置项 `creditPrice` |

**换算只有一个方向**：`金额(元) = 点数 × creditPrice`。

### 3.2 绝对不允许出现的事

| ❌ 不要 | ✅ 要 |
|---|---|
| 把 `credits` 改成 `BigDecimal` / 小数 | 保持 `Integer`，全程整数 |
| 页面里再定义一套"万/亿"的存储口径 | **接口一律返回原始点数（number）** |
| 为了对上原型的「926 万」去改数据库里的数 | 只改**展示**，见 3.3 |
| 前端各页自己写一套数字格式化 | 统一走 `admin-web/js/util.js` 的 `formatCredits()` |
| 把 App 端 10/15 点的语义改掉 | 保持原语义，只在管理端做展示换算 |

### 3.3 展示规则（前端 `admin-web/js/util.js`）

```js
// 接口返回多少就是多少，只在这一处做显示转换
//   9260000   → "926 万"
//   128000000 → "1.28 亿"
//   27        → "27"
//   1286.5    → "1,286.5"
function formatCredits(n) { /* ≥1e8 → 亿；≥1e4 → 万；否则千分位 */ }
```

Java 侧**不要**做格式化。后端返回 `9260000`，前端显示「926 万」—— 老师原型上的「926 万」就是这么来的。

### 3.4 交易流水表（**所有算力变动都必须写一条**）

```sql
-- =============================================================================
--  12. t_credit_transaction 算力流水表（管理端新增，需求 1.3「算力计量」）
--     规则：任何算力变动都必须落一条流水 —— 用户充值、任务消耗、退款、后台加算力。
--     账单页、算力统计页、用户「累计消费」全部从这张表算，不再各算各的。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_credit_transaction` (
  `id`             BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`        BIGINT       NOT NULL,
  `type`           VARCHAR(20)  NOT NULL               COMMENT 'RECHARGE/CONSUME/REFUND/GIFT/ADMIN_ADJUST',
  `amount`         INT          NOT NULL               COMMENT '算力变动，正数增加负数减少',
  `balance_after`  INT          NOT NULL               COMMENT '变动后余额，对账用',
  `money_amount`   DECIMAL(10,2)         DEFAULT NULL  COMMENT '对应金额（元），消耗类可为空',
  `order_no`       VARCHAR(40)           DEFAULT NULL  COMMENT '订单号 P/C/R + yyyyMMdd + 序号',
  `channel`        VARCHAR(30)           DEFAULT NULL  COMMENT '微信支付/支付宝/算力余额/后台调整',
  `status`         VARCHAR(20)  NOT NULL DEFAULT 'SUCCESS' COMMENT 'SUCCESS/PENDING/FAILED',
  `remark`         VARCHAR(255)          DEFAULT NULL,
  `ref_task_id`    BIGINT                DEFAULT NULL  COMMENT '消耗时关联的任务ID',
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_created` (`user_id`, `created_at`),
  KEY `idx_type_created` (`type`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='算力流水表';
```

### 3.5 接线要求（**这里会碰到已在跑的 C 端代码，改之前先读**）

| 位置 | 现状 | 改成 |
|---|---|---|
| `AuthService.register` / `DataSeeder` / `User` 实体默认值 | 「新用户送 10000 点」**硬编码在 3 处** | 三处统一读平台设置 `signupBonusCredits` |
| 建任务扣费（`HarnessService` 或 `CreationController`） | 只改 `User.credits`，不留痕 | **额外写一条 `CONSUME` 流水**（追加，不改原有扣费逻辑） |
| 管理端「加算力」 | — | 写 `ADMIN_ADJUST` 流水 + 改余额，**必须放同一个事务** |
| 管理端充值/退款 | — | 写 `RECHARGE` / `REFUND` 流水 |

> ⚠️ 因为建任务扣费要补流水，这一处**由后端做**（后端负责账单页，最清楚流水需要什么），改完跑一遍 `api-admin.md` §⑭ 的反向验证，确认 App 没被搞坏。

---

## 共享文件切分（防合并冲突）

### 4.1 归属表（**已定稿**：前后端 + 3 个 CRUD 后端模块）

> **分工已定，别再看别处：**
> - **后端线**：`server/` 主体 —— 模型配置 / 工作台 / 调试 / MCP / 知识库 / 概览·算力·账单 / 网关
> - **前端线**：`admin-web/` + `lib/`，**外加 3 个纯 CRUD 后端模块** —— 素材库后台 / 用户管理 / 系统设置 + `PromptController`
>
> 这样两边 ≈ **21 : 19 人天**，基本持平；否则后端 26、前端 13，后端会变成唯一瓶颈。
>
> （`docs/ADMIN_PLAN.md` 里那张分工表是"业务纵切"版，**已作废**，以本表为准。）

| 文件 | 归属 | 规则 |
|---|---|---|
| `server/**`（除下面单列的） | **后端线** | 前端线不碰 |
| `server/.../admin/material/`（素材库后台） | **前端线** | 3 个后端模块之一 |
| `server/.../admin/user/`（用户管理） | **前端线** | 同上 |
| `server/.../admin/setting/`（系统设置） | **前端线** | 同上 |
| `controller/PromptController.java` | **前端线** | 照 `SkillController` 抄，最简单的一个 |
| `server/docs/schema.sql` | **两人共写** | 各自只**追加**自己的表：后端线追加冻结项①②③ 的 5 张；前端线追加标签/分类相关表 |
| `common/ErrorCode.java` | **两人共写** | 各用各的码段：后端线 6000-6499 / 6700-6799；前端线 6500-6599（见 `api-admin.md` §0.4） |
| `init/DataSeeder.java` | **两人共写** | **必须拆成 `CoreSeeder`（后端线）/ `CrudSeeder`（前端线）两个类**，各自 `@Component` + `@Order` |
| `entity/User.java` | 后端线 | 新增列 `last_active_at`；前端线只读使用 |
| `security/AuthInterceptor.java` | 后端线 | `/api/admin/**` 的 ADMIN 校验 + dev-token 隔离 |
| `config/WebConfig.java` | 后端线 | 拦截器注册路径调整 |
| `ai/**`（`AiProviderRouter` + 新增 `HttpApiProvider`） | 后端线 | 含模型配置的接线改造 |
| `harness/**` | 后端线 | 补算力流水时只加一行调用，不改状态机 |
| `application.yml` | 后端线 | 前端线有需求提给后端线 |
| `admin-web/**`（原型、`js/api.js`、`js/pages/*`、`mock/`） | **前端线** | 后端线不碰 |
| `lib/**`（Flutter App） | 前端线（**收尾阶段**） | 前面阶段谁都不动；收尾只补 2 个占位页 + 设置页 |
| `docs/api-admin.md` | **两人共写** | 唯一真共享文档。**改接口先改它**，并在「变更记录」加一行 |
| `docs/admin-freeze.md` | 两人共写 | 本文件。改冻结项要两人都同意 |

### 4.2 关键目录的归属（一眼看懂）

```
server/src/main/java/com/opc/server/
├── admin/
│   ├── provider/   ← 后端线（模型配置）
│   ├── debug/      ← 后端线（调试）
│   ├── mcp/        ← 后端线（MCP）
│   ├── gateway/    ← 后端线（网关）
│   ├── credit/     ← 后端线（账单/算力/概览）
│   ├── tool/       ← 后端线（工具库 + ToolKeys）
│   ├── agent/      ← 后端线（智能体工作台）
│   ├── kb/         ← 后端线（知识库）
│   ├── material/   ← 前端线（素材库后台）
│   └── user/       ← 前端线（用户管理）+ setting/（系统设置）
├── ai/             ← 后端线独占（改造）
├── harness/        ← 后端线独占（补流水）
└── security/       ← 后端线独占

admin-web/
├── css/admin.css   ← 前端独占（新样式追加到末尾）
├── js/api.js       ← 前端建，全站共用
├── js/util.js      ← 前端（formatCredits 等）
├── js/pages/       ← 前端（一页一个文件）
├── mock/           ← 前端（mock JSON，字段照 api-admin.md 抄）
└── index.html      ← 前端独占（保留原型 7 页结构，追加 5 页）
```

### 4.3 变更流程（3 条纪律）

1. **接口变了** → 先改 `docs/api-admin.md`，在「变更记录」加一行，再改代码，**两人同时改**（前后端分法下尤其重要）。
2. **要动别人的文件** → 群里先说一句，别直接改；`ErrorCode` 只用自己的码段。
3. **每次合并前** → 先 `git pull`，再 commit；`index.html` 冲突时**两边都留**，不要 `--ours/--theirs` 一把梭。

---

## 开工检查清单（两人一起过一遍再动手）

- [ ] 读完 `docs/api-admin.md` §0 通用约定（返回体 / 分页 / 错误码分段 / 枚举字典）
- [ ] 三项冻结都确认无异议：① `AiProviderConfig` 字段 ② 工具统一抽象 ③ 算力口径
- [ ] 建分支 `codex/admin-backend`
- [ ] `docs/api-admin.md` 的「变更记录」已建好
- [ ] `server/`（后端独占）与 `admin-web/`（前端独占）的归属已确认；`docs/api-admin.md` 是唯一共享文档
- [ ] `admin-web/index.html` 追加 5 个新页 `<section>` 的位置已确认
- [ ] 确认**红线**：不删 `MockAiProvider`、不改 `t_skill` 语义、不改坏 `/api/**` 22 个 C 端接口
- [ ] 跑一次基线：`./mvnw spring-boot:run` 能起、`flutter run -d chrome` 能跑、`admin-web/index.html` 能打开

> 基线跑通后再开工。**如果开工第一天基线就是坏的，先修基线，别急着写新功能。**
