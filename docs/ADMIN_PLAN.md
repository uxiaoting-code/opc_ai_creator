# OPC AI 后台 · 现状盘点 / 开发顺序 / 两人分工

> 盘点时间：2026-10-13
> 依据：《OPC 文生图/图生视频 App 后台需求文档》（7 页）+ 仓库现有代码
>
> **一句话结论：App 端已经基本做完，需求文档要的「AI 后台」几乎为零。**
> 学长的判断是对的 —— 先做 AI 后台。
>
> ⚠️ **分工口径提醒（2026-10-14 更新）**：本文的 **A / B** 是"业务纵切"分法的代号。
> **分工已于 2026-10-14 定稿为"前后端 + 3 个 CRUD 模块"**，请以 `docs/admin-freeze.md` §4.1 的归属表为准（本文 §5 那张表已作废）。

---

## 0. 先看结论

| 问题 | 结论 |
|---|---|
| 老师给的 `web/` 是什么 | 后台控制台的**静态原型**（HTML+CSS+JS，7 个页面，**全站 0 处网络请求**，数据写死在 HTML 里） |
| 之前 Claude Code 做的是什么 | **面向 App 的后端**（22 个 C 端接口）+ **Flutter App**（13 页，11 页完成） |
| 缺口在哪 | 需求文档的 8 大能力基本都没有，`/api/admin/**` **一个接口都没有** |
| 开发顺序 | 管理端地基 → 模型/API 配置 → 智能体工作台 → 调试面板 → MCP → 知识库/素材库 → 算力运营 → 对外网关 → App 收尾 |
| 两人怎么分 | 按「业务纵切」分两条线：**A = 能力接入线**，**B = 资源与运营线**；先花 3~4 天两人一起把管理端地基打完 |

---

## 1. 三块家底

### 1.1 `web/` —— 老师给的后台控制台原型（纯静态）

- 文件：`web/index.html`(415 行) + `web/css/admin.css`(23KB) + `web/js/admin.js`(28KB)
- 侧栏 7 个页面：数据概览 / 用户管理 / 账单管理 / 大模型配置 / 智能体 Skill 配置 / 算力使用 / 系统设置
- 交互最深的是「智能体 Skill 配置」，两层结构：
  智能体列表 → **Skill 编排详情**（基础信息 + System Prompt + 开场白 + Skill 列表开关排序
  + 调用计费/轮次/超时/配额 + 静态调用流程预览）
- **关键事实：`admin.js` 里没有一处 `fetch` / `XMLHttpRequest` / `axios`，`index.html` 里表格数据全是写死的。**
  所以它现在是一个「能点的高保真原型」，不是「能用的后台」。
- 登录页只要账号密码非空就放行（`web/js/admin.js` 第 29~36 行），**没有鉴权**。
- `web_old/` 是本次替换前 Flutter web 的产物（favicon / manifest / icons），与后台无关。

### 1.2 `server/` —— 已有的后端（Spring Boot 4.1.1 + Java 21 + JPA + H2/MySQL）

22 个接口，**全部是 C 端（App 用）的**：

| 分组 | 接口 |
|---|---|
| 认证 | `/api/auth` login / register / logout / profile |
| 线路 | `/api/skills` 列表 / 详情 |
| 创作 | `/api/creation` text-to-image / image-to-video |
| 任务 | `/api/tasks` 列表 / stats / 详情 / retry / cancel |
| 作品 | `/api/works` 列表 / 详情 / publish |
| 素材 | `/api/materials` upload / my / 删除 |
| 消息 | `/api/notifications` 列表 / unread |
| 健康 | `/api/health` |

已经比较扎实、**不要重写要复用**的部分：

- **Harness 运行时**：`HarnessScheduler`（3 秒轮询 + 超时清扫）+ 独立线程池
  + `TaskStateService` 状态机（claim / markSuccess / markFailed / updateProgress / resetStuck）
  + 重试与取消 → 需求文档 1.3 的「Harness」这一条 **已完成**。
- **AiProvider 抽象**：`AiProvider` 接口 + `AiProviderRouter` + `MockAiProvider` / `StableDiffusionProvider`
  + `AiTaskRequest` / `AiTaskResult` → 这是将来「配置化接入 API」的**挂载点**。
- **算力扣减**：建任务时按 `TaskType` 扣 `User.credits`（文生图 10 点、图生视频 15 点）→ 计量的**一半**。
- **7 张表**：`t_user` / `t_skill` / `t_ai_task` / `t_material` / `t_prompt` / `t_prompt_favorite` / `t_work`。
- `User.role` 已有 `USER/ADMIN`，`DataSeeder` 已建 `admin/admin123`，
  **但没有任何接口或拦截器用它** —— 管理端等于零。

### 1.3 `lib/` —— Flutter App（13 页）

- 11 页完整：登录注册、首页、文生图、图生视频、任务列表、任务详情、作品画廊、作品详情、个人中心、素材库、设置
- **2 页只有 30 行、是脚手架占位**：`lib/pages/knowledge/prompt_library_page.dart`、
  `lib/pages/skill/skill_market_page.dart`
  （后端接口也没做：`Prompt` 实体和 `PromptRepository` 建了，**但没有 `PromptController`**）
- 设置页有一块「待实现」清单：默认参数 / 缓存管理 / 通知设置 / 账号安全 / 关于
- ⚠️ 两个"后门开关"现在都开着，交付前必须关：
  `AppConfig.bypassLogin` = true（前端跳过登录）；`opc.security.dev-token-enabled` = true（后端放行固定令牌 mock-token-for-scaffold）。
  这两个开关**不能被管理端复用**（详见 §7 坑 2）。`AppConfig.useMockData` 当前默认已是 false，无需再动。

---

## 2. 需求文档 8 大诉求 → 逐条对照

| # | 需求文档要求 | 现状 | 缺口 |
|---|---|---|---|
| 1 | Harness 运行时框架 | ✅ 已有完整实现 | 无（可能要补"节点级"执行日志） |
| 2 | Skill 多线路 | ⚠️ 部分。`Skill` 是一张平铺参数模板表（provider / model / steps / cfg / 尺寸 / prompt 前后缀），一个 Skill 一条线路 | **无分支、无条件路由、无编排、无版本** |
| 3 | 素材库 | ⚠️ 部分。只有 C 端"上传 + 我的素材 + 删除"；实体里有 `groupName` / `tags` 字符串字段但没真正用起来 | 无分类体系、无多级标签、无版本管理、无批量上传下载、无后台管理接口 |
| 4 | 知识库 | ❌ 零。没有实体、没有接口、没有分段/向量化 | 全缺。**注意别混淆**：现有 `t_prompt` 是 C 端"提示词收藏"，不是需求文档 3.4.1 那种"可导入/可分段的向量知识库" |
| 5 | 智能体工作台（A2A 链编排） | ❌ 零 | 无节点模型、无编排、无条件路由、无版本回滚、无统一调试 |
| 6 | API 网关与 MCP 接入 | ❌ 零。代码注释里写了"MCP 思想"（服务商/参数解耦），但没有协议、没有 MCP Server 注册/发现/映射 | 全缺 |
| 7 | 算力计量 | ⚠️ 部分。有扣减，但 `AiTask` 没有算力字段，也没有流水表 | 无流水、无账单、无充值/退款、无"购买与出售" |
| 8 | 配置化后台（3.1 配置 API / 3.2 调试） | ❌ 零接口。老师原型的"大模型配置"只有 模型名/类型/渠道/价格 | 无 baseURL、无鉴权方式、无请求模板、无响应模板、无连通性测试；调试面板 6 项功能全无 |

需求文档 3.1 列的 5 步（新增 API → 配置鉴权 → 定义请求模板 → 定义响应模板 → 测试连通性），
现在 **0 步有代码**。

---

## 3. 老师原型 7 页 → 需要补的接口清单（≈33 个）

这张表就是"做完了没有"的验收标准。★ = 需求文档有、老师原型还没画页面的。

### 管理端通用
- `POST /api/admin/auth/login` —— 管理端登录（校验 `role = ADMIN`）
- `GET  /api/admin/auth/profile`

### ① 数据概览 `pg-dash`
- `GET /api/admin/dashboard/overview` —— 四张卡（用户数 / 任务数 / 算力消耗 / 收入）+ 环比
- `GET /api/admin/dashboard/trend?days=7`
- `GET /api/admin/dashboard/recent-orders?limit=5`

### ② 用户管理 `pg-users`
- `GET  /api/admin/users?page&size&keyword&status`
- `POST /api/admin/users` —— 新增用户
- `POST /api/admin/users/{id}/credits` —— 加算力
- `POST /api/admin/users/{id}/freeze` / `/unfreeze`
- `POST /api/admin/users/{id}/reset-password`
- `GET  /api/admin/users/export`（可降级为前端导 CSV）

### ③ 账单管理 `pg-bills`
- `GET /api/admin/bills?type=充值|消耗|退款&page`
- `GET /api/admin/bills/summary?date=today`
- `GET /api/admin/bills/export`

### ④ 大模型配置 `pg-models` —— 需求 3.1 的正式版，要做深
- `GET  /api/admin/providers?type&keyword`
- `POST /api/admin/providers` —— 新增（名称 / 厂商 / 类型 / baseUrl）
- `PUT  /api/admin/providers/{id}`
- `PUT  /api/admin/providers/{id}/auth` —— 鉴权配置（APIKey / OAuth / 自定义 Header）
- `PUT  /api/admin/providers/{id}/request-template` —— 请求模板（方法 / 路径 / 参数映射 / Body）
- `PUT  /api/admin/providers/{id}/response-template` —— 响应模板（字段提取规则）
- ★ `POST /api/admin/providers/{id}/test` —— 连通性测试
- `PUT  /api/admin/providers/{id}/online` / `/offline` —— 上架 / 下线
- `PUT  /api/admin/providers/{id}/pricing` —— 调价

### ⑤ 智能体 Skill 配置 `pg-agents` —— 需求 3.5 工作台
- `GET  /api/admin/agents?type&status&page`
- `POST /api/admin/agents` —— 新建（支持复制模板）
- `GET  /api/admin/agents/{id}` —— 详情（含编排）
- `PUT  /api/admin/agents/{id}` —— 保存编排（基础信息 + 节点顺序 + 每个节点启用/参数）
- ★ `PUT  /api/admin/agents/{id}/nodes/{nodeId}` —— 单节点配置
- `POST /api/admin/agents/{id}/publish` / `/offline`
- `POST /api/admin/agents/{id}/duplicate` —— 复制
- ★ `GET  /api/admin/agents/{id}/versions` + `POST .../rollback` —— 版本管理
- `GET  /api/admin/tools` —— 可用能力/工具库（编排时挑选）

### ⑥ 算力使用 `pg-usage`
- `GET /api/admin/credits/stats?range=today|month`
- `GET /api/admin/credits/by-model?range=today`
- `GET /api/admin/credits/top-users?limit=8`

### ⑦ 系统设置 `pg-settings`
- `GET` / `PUT /api/admin/settings` —— 平台参数（名称 / 赠送算力 / 赠送比例 / 单价）
- `POST /api/admin/announcements` —— 发布公告
- `PUT  /api/admin/switches` —— 注册开关 / 充值开关 / 维护模式

### ★ 需求文档有、原型里根本没画的 5 个模块（要新画页面 + 新接口 ≈25 个）

| 模块 | 接口 |
|---|---|
| **调试面板**（需求 3.2） | `POST /api/admin/debug/node`(单节点调试)、`POST /api/admin/debug/chain`(全链路)、`POST /api/admin/debug/chat`(对话式)、`GET /api/admin/debug/logs`(日志追踪)、`GET /api/admin/debug/compare`(版本对比)、`POST /api/admin/debug/regression`(回归测试) |
| **MCP 接入**（需求 3.3） | `GET`/`POST /api/admin/mcp/servers`、`POST /api/admin/mcp/servers/{id}/discover`、`PUT /api/admin/mcp/tools/{id}/enable`、`POST /api/admin/mcp/tools/{id}/invoke` |
| **知识库**（需求 3.4.1） | `GET`/`POST /api/admin/kbs`、`POST /api/admin/kbs/{id}/documents`(文本/文件/URL/API 同步)、`POST /api/admin/kbs/{id}/reindex`、`POST /api/admin/kbs/{id}/search`、`PUT /api/admin/kbs/{id}/bind-agents` |
| **素材库后台**（需求 3.4.2） | 批量上传、分类/多级标签 CRUD、多维检索、版本管理、批量下载 |
| **API 网关**（需求 1.3） | `GET /api/admin/gateway/endpoints` 对外接口定义 + 导出 OpenAPI |

→ 控制台要从 7 页扩到 **约 12 页**。

---

## 4. 开发顺序（AI 后台优先）

**依赖链一句话：**
> 管理端地基 → **模型/API 配置**（一切 AI 能力的地基）→ **智能体工作台**（编排出对象）
> → **调试面板**（调试的对象就是工作流）→ **MCP**（本质是往工作台里加"外部工具节点"）
> → **知识库 / 素材库**（给智能体挂资源）→ **算力与运营**（可独立并行）→ **对外网关** → App 端收尾

**为什么不能先做工作台和调试：**

1. 工作台每个节点都要"选一个已配置的模型"。模型配置没做完，节点只能写死 provider，后面全返工。
2. 调试面板调试的对象就是工作流 —— 工作流没有，调试面板无处可调试。
3. MCP 工具、内置 Skill 工具、配置出来的模型，**必须是同一套"能力/工具"抽象**，
   否则一个工作台要维护三套节点类型，越写越烂。

**阶段表：**

| 阶段 | 内容 | 产出 / 验收 | 预估 | 谁 |
|---|---|---|---|---|
| **P0 地基** | `/api/admin/**` 路由 + ADMIN 角色鉴权 + 管理端登录接口；控制台假登录改真登录 + 抽出 `web/js/api.js` 统一请求封装；MySQL 建库落地；把 dev-token 收窄到不放行 admin | `admin/admin123` 能登录后台；任一页能拿到真数据 | 3~4 天 | **两人结对** |
| **P1 模型 / API 配置** | `AiProviderConfig` 实体 + CRUD + 鉴权配置 + 请求模板 + 响应模板 + 连通性测试；把 `AiProviderRouter` 从"写死 provider 名"改成"读配置路由" | 后台配一个模型 → 页面点"测试"能看到真实返回；「大模型配置」页接真数据 | 4~5 天 | A |
| **P2 智能体与工作台** | `Agent` / `AgentNode` / `AgentVersion` 实体；节点 = 能力（工具/模型/知识库/审核）；编排保存、发布、复制、版本回滚、条件路由 | 「智能体 Skill 配置」页真数据；能编排一条"输入→检索→生成"的链并保存 | 5~6 天 | B |
| **P3 调试面板** | 调用日志表 + 单节点调试 + 全链路调试 + 对话式调试 + 版本对比 + 回归用例集 | 新页面「调试」；一键跑通链路，能看到每个节点的中间结果 / 耗时 / 算力 | 4~5 天 | A |
| **P4 MCP 接入** | `McpServer` / `McpTool` 实体；注册 / 发现(list tools) / 启用 / 映射为平台工具 / 试调用 | 新页面「MCP 接入」；注册一个 MCP Server 能拉到工具列表并调用成功 | 3~4 天 | A |
| **P5 知识库** | `KnowledgeBase` / `Document` / `Chunk` 实体；录入(文本/文件/URL/API 同步)、分段、检索、检索测试、绑定智能体 | 新页面「知识库」；传一份 PDF 能检索出片段 | 5~6 天 | B |
| **P6 素材库后台** | 批量上传、分类、多级标签、检索、版本、预览 / 批量下载 | 新页面「素材库」 | 3~4 天 | B |
| **P7 算力与运营** | `CreditTransaction` 流水表；充值 / 退款；账单页；算力统计；用户管理(冻结/加算力/改密)；系统设置；数据概览 | 「账单 / 算力使用 / 用户管理 / 系统设置 / 数据概览」5 页接真数据 | 4~5 天 | A+B 拆 |
| **P8 网关 + 收尾** | 对外接口定义 / OpenAPI 导出；Flutter 补 Prompt 知识库页 + Skill 市场页 + 设置页；端到端联调；APK 打包 | 全链路演示 + 打包产物 | 3~4 天 | 两人 |

**合计约 35~40 人天**（含联调）。两人并行 ≈ **4~5 周**
（按每周 4 天有效投入算；如果每天只能投 2 小时，按倍数放大）。

---

## 5. 两人分工

### 先说两种分法的取舍

- ❌ **按"前后端"分**（一人写 Spring、一人写 web JS）：控制台每一页都依赖后端接口，
  后端没写完前端只能干等；而且后端工作量大约是前端的 3 倍，严重失衡。
- ✅ **按"业务纵切"分**（推荐）：两人都是全栈（Java + HTML/JS），
  每人负责一条完整业务线（后端接口 + 数据库 + 控制台页面），互不阻塞。

### 分工表

| | **A · 能力接入线** | **B · 资源与运营线** |
|---|---|---|
| 主题 | "怎么把外部 AI 能力接进来、怎么调通" | "怎么把能力编排成智能体、怎么管资源与钱" |
| 负责阶段 | P1 模型/API 配置、P3 调试面板、P4 MCP、P8 网关 | P2 工作台编排、P5 知识库、P6 素材库后台 |
| 后端包 | `admin.provider`、`admin.debug`、`admin.mcp`、`admin.gateway`；改造 `ai/`（`AiProviderRouter` 配置驱动、新增 `HttpApiProvider`） | `admin.agent`、`admin.kb`、`admin.material`；新增实体与仓储 |
| 控制台文件 | `web/js/pages/models.js`、`debug.js`、`mcp.js` | `web/js/pages/agents.js`、`kb.js`、`materials.js` |
| 关键交付物 | 配置化 Provider（含请求/响应模板引擎）+ 调用日志表 + 调试 6 件套 | Agent/节点/版本模型 + 文档分段检索 + 素材标签体系 |
| 工作量 | P0 3.5 + P1 4.5 + P3 4.5 + P4 3.5 + P7(半) 2.5 + P8 1.5 ≈ **20 人天** | P0 3.5 + P2 5.5 + P5 5.5 + P6 3.5 + P7(半) 2.5 + P8 1.5 ≈ **22 人天** |

**P7 运营线再拆**：A 做 账单流水 + 算力统计 + 数据概览（偏聚合查询）；
B 做 用户管理 + 系统设置（偏 CRUD）。

### 协作约定（避免互相踩）

1. **P0 阶段两人一起把地基打完并冻结**（路由前缀、鉴权方式、统一返回体、`web/js/api.js`），
   之后才分头写。
2. **接口先冻结**：新建 `docs/api-admin.md`，把字段写死，两边照契约写，不等对方实现。
3. `web/index.html` 是共享文件：A 只加自己页面的 `<section>`，B 只加自己的，改动行区间不重叠；
   每次合并前先 pull。
4. 控制台 JS **按页面拆文件**，别都往 `admin.js` 里堆。
5. 共享文件（`WebConfig.java` 拦截器注册、`DataSeeder.java`、`application.yml`）改动前先在群里说一声。

---

## 6. 第一周该怎么开工（可直接照做）

**Day 1（两人一起）**
- 建分支 `codex/admin-backend`；跑起来 server（H2 开箱即跑），用 Live Server 打开 `web/index.html` 确认现状
- 建 `docs/api-admin.md`，先把最简单的两组接口字段定死：⑦ 系统设置、② 用户管理
- 数据库迁移方式定下来 —— 建议沿用 Hibernate `ddl-auto: update`，别引入 Flyway

**Day 2~3（A）**
- `AdminAuthController` + 改造 `AuthInterceptor`：`/api/admin/**` 必须 `role = ADMIN`
- 收窄 `dev-token-enabled`：只放行 C 端 `/api/**`，**不放行 `/api/admin/**`**

**Day 2~3（B）**
- 控制台登录页改成真调接口、存 token；抽出 `web/js/api.js`（统一 baseURL + Authorization + 错误 toast）
- 把 `admin.js` 按页面拆成 `web/js/pages/*.js`；`index.html` 侧栏预留 5 个新页入口（先空页）

**Day 4~5（各自动手）**
- A：`AiProviderConfig` 实体 + 列表/新增接口 + 「大模型配置」页接真数据
- B：`Agent` / `AgentNode` 实体 + 列表/详情接口 + 「智能体 Skill 配置」页接真数据

**第一周验收标准：后台能真登录，两页（大模型配置、智能体配置）看到数据库里的真数据并能保存。**

---

## 7. 坑（按踩到概率排序）

1. **别删 `MockAiProvider`**：没有商用 API key，答辩演示就靠它出图出视频。
   真实接入用"配置 + 连通性测试"来证明能力即可。
2. `dev-token-enabled: true` 是个后门，交付前必须关；**管理端更不能复用这个固定 token**。
3. 老师原型没有 MCP / 知识库 / 调试 / 素材后台 / 网关这 5 个页面 ——
   要提前定：**新画页面**（推荐，侧栏加 5 项，不破坏原型），不要硬塞进现有页。
4. **拖拽式编排别自研画布**。降级方案：列表排序 + 启用开关 + 上下移按钮
   （老师原型就是这个形态），条件路由用"当输入命中关键词 X → 走线路 Y"的表单；
   有余力再上 AntV X6 / Drawflow。
5. **向量检索别一上来就上向量库**。第一版用 MySQL 全文索引 / `LIKE` + 关键词打分，
   把"分段 → 检索 → 引用"链路跑通；有余力再接 Spring AI + 一个 embedding 服务。
6. 文件解析：TXT/MD 自己读，PDF 用 PDFBox，Word/Excel 用 Apache POI（纯 Java，不额外依赖服务）。
7. H2 / MySQL 双 profile 保持现状，**答辩用 H2 最稳**（不怕现场数据库没起）。
8. 别顺手重构 `lib/`：App 端 11 页已跑通，本轮只补 2 个占位页 + 设置页，改动越小越安全。
9. **算力单位先对齐**：现在扣的是 10 / 15「点」，老师原型里是「万/亿」量级。
   先在设置页把"算力单价 / 赠送"做成配置项，统计口径统一成「点」，展示时再换算，避免两套数。

---

## 8. 明确不在本轮范围（防止被拖死）

- 真接第三方商用大模型（没 key 没预算）→ 用配置页 + Mock 打通链路即可
- 真支付（微信 / 支付宝）→ 充值走"模拟充值流水"
- 多租户 / 完整 RBAC → 只区分 `USER` / `ADMIN`
- 向量数据库集群、MCP 全协议 → 只做 tools 的注册 / 发现 / 调用

---

## 9. 交付 / 答辩提示

演示脚本建议：

> 后台登录 → 数据概览 → 配一个模型并点「测试」→ 编排一条"检索 → 生成"链路 →
> 调试面板跑通全链路看日志 → 素材库 / 知识库 → 算力账单 →
> 切到 App 端文生图 / 图生视频 → 任务状态轮询 → 作品画廊

要留给老师的两份文档：

| 文档 | 内容 |
|---|---|
| `docs/api-admin.md` | 管理端接口契约（新建） |
| `docs/ADMIN_PLAN.md` | 本文：盘点 + 顺序 + 分工 |