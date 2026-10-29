# OPC AI 后台 · 开发排期（5 周主线 + 3 天缓冲）

> 定稿日期：2026-10-17
> 分工：**后端线** = `server/` 主体；**前端线** = `lib/`（用户 App）+ `admin-web/`（后台控制台）+ 3 个纯 CRUD 后端模块
> 口径：每周 5 个工作日、每天 6~8 小时有效投入。
> ⚠️ 如果实际是课余时间（每天 2~3 小时），整体时间 **×2~2.5**（约 10~12 周）。
>
> 配套文档：`docs/api-admin.md`（接口契约）、`docs/admin-freeze.md`（三项冻结 + 文件归属）、`docs/ADMIN_PLAN.md`（背景）
>
> **交付定义**：交付 = 更新 `docs/api-admin.md` 的「变更记录」+ `git commit` + `git push`。
> 群消息只是可选提醒，**以文档为准**；搭档开工前必须 `git pull` 并读变更记录。
>
> **完成标准（不是勾全本表就算完）**：
> 1. Flutter 用户 App 按老师最终确认范围完成 `docs/prototype-user/` 原型复刻并可运行
> 2. **后台控制台 12 页可运行（admin-web，接真接口）**
> 3. 管理端 P0~P8 接口可用
> 4. `docs/api-admin.md` 与代码一致
> 5. `docs/COMPONENTS.md` 完整
> 6. 演示脚本可端到端跑通

---

## 0. 分工速查

| | 后端线（你） | 前端线（搭档） |
|---|---|---|
| 主目录 | `server/` 主体 | `lib/`（用户 App）+ `admin-web/`（后台控制台） |
| 外加 | — | `server/.../admin/{material,user,setting}` + `PromptController` |
| 负责模块 | 模型配置 / 工作台 / 调试 / MCP / 知识库 / 概览·算力·账单 / 网关 | **admin-web 12 页接真接口** / Flutter 用户 App 收尾 / 素材库后台 / 用户管理 / 系统设置 |
| 错误码段 | 6000-6499、6700-6799 | 6500-6599 |
| 人天 | ≈ 21 | ≈ 19 |

---

## 1. 依赖链（记住这一条就够）

```
后端线：P0 → P1 模型配置 → P2 工作台 → P3 调试 → P4 MCP → P5 知识库 → 运营 → 网关
用户 App：Flutter 组件/页面 → C 端接口联调 → 收尾 → APK
运营后台：admin-web 12 页 → 逐页接 /api/admin/** 真接口
                              ↑
                    每接一页，才需要那一页的管理端接口（异步，不用同时在线）
```

**后端线是串行的，前端线可并行。你的进度 = 全项目进度。**

---

## 2. Week 0 · Day 1 上午（一起，30 分钟）

- [ ] 一起过 `docs/api-admin.md` §0（返回体 / 分页 / 错误码分段 / 枚举字典）
- [ ] 一起过 `docs/admin-freeze.md` §4.1（文件归属）
- [ ] 确认 3 个共写文件的规矩：
  - `schema.sql`：后端线先改先推，前端线后改
  - `ErrorCode.java`：各用各的码段
  - `DataSeeder.java`：各建新类（`CoreSeeder` / `CrudSeeder`），不动老文件

---

## 3. Week 1（Day 1~5）· 地基 + 组件

### 后端线（你）

- [x] **P0-1** `common/ErrorCode.java` 追加 9001~9005
- [x] **P0-2** `entity/User.java` 增加 `last_active_at`
- [x] **P0-3** `security/AuthInterceptor.java`：`/api/admin/**` 要求 ADMIN；dev-token 隔离；最近活跃节流
- [x] **P0-4** `service/AuthService.java`：`loginAdmin()`（非 ADMIN → 403）
- [x] **P0-5** `controller/admin/AdminAuthController.java`：`POST /api/admin/auth/login` + `GET /api/admin/auth/profile`
- [x] **P0-6** `config/WebConfig.java`：放行 `/api/admin/auth/login`
- [x] **P0-7** `server/docs/schema.sql`：追加 5 张新表 + `last_active_at`
- [x] **P0 自测**（2026-10-17 已跑通）：
  - [x] `admin/admin123` → HTTP 200 / role=ADMIN
  - [x] `admin` 令牌调 `/profile` → 200
  - [x] `demo/demo123` 登后台 → HTTP 403 / code=9002
  - [x] `demo` 令牌调管理接口 → HTTP 403 / code=9002
  - [x] `mock-token-for-scaffold` 调管理接口 → HTTP 403
  - [x] 无 token → HTTP 401
  - [x] C 端回归：`/api/skills` 200、`/api/auth/profile` 200、`/api/health` 200
- [x] Day 3~5：**P1 模型/API 配置**（2026-10-22 完成并验收）
  - [x] `AiProviderConfig` 实体 + Repository
  - [x] 列表 / 新增 / 详情 / 修改
  - [x] 鉴权配置、请求模板、响应模板
  - [x] 连通性测试 `POST /api/admin/providers/{id}/test`
  - [x] `AiProviderRouter.routeByConfig()` + 新增 `HttpApiProvider`

### 前端线（搭档）

- [x] Day 1~2：**Flutter 组件第一批**（老师明确要求优先）
  - [x] 组件预览页 `lib/pages/dev/component_gallery_page.dart`
  - [x] `PromptInputCard` / `SkillSelector` / `SizePicker` / `ParamSliderRow`
  - [x] `GenerateBar` / `ResultPreviewCard` / `TaskStatusCard` / `CreditChip`
  - [x] 组件只依赖 `data/models`，**不 import** `api_client` / `repository` / `provider`
  - [x] 列出 `docs/COMPONENTS.md` 组件清单
- [x] Day 3~5：**Web P0**
  - [x] `admin-web/js/api.js`（baseURL + Authorization + 统一错误 + `USE_MOCK` 开关）
  - [x] `admin-web/js/util.js`（`formatCredits()` 等）
  - [x] 拆 `admin.js` → `admin-web/js/pages/*.js`
  - [x] 登录页走 `api.js`（mock 模式可假登录）
  - [x] `admin-web/mock/*.json`（字段照 `api-admin.md`）
  - [x] `index.html` 侧栏追加 5 个新页入口

### 同步点

- [x] **Day 2 末**：P0 联合验收（前端真登录）—— 2026-10-22 通过（login/profile 200；数据接口待 P1+ 逐页接入）
- [x] **Day 5 末**：mock 层验收（12 页能点通）—— 2026-10-22 通过

---

## 4. Week 2（Day 6~10）· 模型配置 + 前端闭环模块

### 后端线（你）

- [x] P1 收尾（连通性测试 + 路由改造 + `HttpApiProvider`）—— 已随 2026-10-22 一并完成
- [x] **【交付】** 模型配置全套接口（2026-10-22 已推送）
  - [x] 更新 `docs/api-admin.md` 变更记录
  - [x] `git commit` + `git push`
  - [x] 搭档开工前 `git pull` 并读变更记录
- [x] P2 智能体工作台（2026-10-22 完成并验收）
  - [x] `Agent` / `AgentNode` / `AgentVersion` 实体
  - [x] 列表 / 新建 / 详情 / 保存编排
  - [x] `GET /api/admin/tools`（统一工具库）

### 前端线（搭档）

- [x] `PromptController` + App 的 Prompt 知识库页（2026-10-28 搭档完成并推送）
- [x] 用户管理后端 + 页面（列表 / 加算力 / 冻结 / 重置密码）（2026-10-28 搭档完成并推送）
- [x] 系统设置后端 + 页面（平台参数 / 公告 / 3 个开关）（2026-10-28 搭档完成并推送）

---

## 5. Week 3（Day 11~15）· 工作台 + 调试

### 后端线（你）

- [x] P2 收尾（发布 / 复制 / 版本回滚 / 条件路由 / 预览）—— 已随 2026-10-22 一并完成
- [x] **【交付】** 工作台接口（2026-10-22 已推送）
  - [x] 更新 `docs/api-admin.md` 变更记录
  - [x] `git commit` + `git push`
  - [x] 搭档开工前 `git pull` 并读变更记录
- [x] P3 调试面板（2026-10-28 完成并验收）
  - [x] `CallLog` 表
  - [x] 单节点调试 / 全链路调试 / 对话式 / 版本对比 / 回归用例

### 前端线（搭档）

- [x] 素材库后台（后端 + 页面：分类 / 多级标签 / 检索 / 版本）（2026-10-28 搭档完成并推送）
- [x] 切「大模型配置」页（`USE_MOCK = false`）（2026-10-28 搭档完成并推送）
- [x] 切「智能体配置」页（两层结构）（2026-10-28 搭档完成并推送）

---

## 6. Week 4（Day 16~20）· 调试 + MCP

### 后端线（你）

- [x] P3 收尾（2026-10-28 完成并验收）
- [x] **【交付】** 调试接口（代码已完成，待推送）
  - [x] 更新 `docs/api-admin.md` 变更记录
  - [x] `git commit` + `git push`
  - [ ] 搭档开工前 pull
- [x] P4 MCP 接入（2026-10-28 完成并验收）
  - [x] `McpServer` / `McpTool` 实体
  - [x] 注册 / 发现 / 启用 / 映射 / 试调用
- [x] **【交付】** MCP 接口（代码已完成，待推送）
  - [x] 更新 `docs/api-admin.md` 变更记录
  - [x] `git commit` + `git push`
  - [ ] 搭档开工前 pull

### 前端线（搭档）

- [ ] 切「调试」页（`admin-web`，接 `/api/admin/debug/**` 真接口）
- [ ] 切「MCP」页（`admin-web`，接 `/api/admin/mcp/**` 真接口）
- [ ] Flutter 用户 App 收尾：Skill 市场页（替换当前占位页）

---

## 6.5 技术边界（老师 2026-10-29 澄清）

> **Flutter 复刻的是用户 App 页面，不是后台控制台。参考代码在 `docs/prototype-user/`。**
> 原型 28 页与当前 Flutter 的逐页对照见 `docs/USER_PROTOTYPE_GAP.md`。
> 后台控制台继续使用老师提供的 `admin-web/`（HTML/CSS/JS），不要创建 `lib/admin/`。

完整链路：

```text
Flutter 用户 App ── HTTP 请求 /api/** ─────▶ Spring Boot server ──▶ Harness ──▶ AI Provider
admin-web 控制台 ── HTTP 请求 /api/admin/** ─▶ Spring Boot server（保存 API / Skill / Harness 配置）
```

- Flutter 发起文生图 / 图生视频指令，后端鉴权、扣算力、建任务并调用 Harness / AI Provider。
- 后端立即返回任务 ID 和状态；App 通过任务详情 / 列表接口获取进度、结果 URL 和错误信息。
- `admin-web` 负责配置模型 API、创建 Skill、搭建 Harness、调试、知识库、素材、账单和网关。
- 接口由后端暴露给前端调用；“前端暴露接口”应理解为**前端按契约调用后端接口**。
- 用户端主流程以原型 4 个一级 Tab 为准：课程 / 创作 / 接单 / 我的。
- 当前 Flutter 是 5 Tab（首页/任务/画廊/素材/我的），因此首页壳和页面归属需要重构，不能只补两个占位页。
- 详细逐页差异与开发顺序见 `docs/USER_PROTOTYPE_GAP.md`。

---
## 7. Week 5（Day 21~25）· 知识库 + 运营 + 网关

### 后端线（你）

- [x] P5 知识库（2026-10-28 完成并验收）
  - [x] `KnowledgeBase` / `Document` / `Chunk`
  - [x] 文本 / 文件 / URL / API 同步（当前支持 TXT/MD/CSV/JSON/HTML；PDF/Word/Excel 待装 PDFBox/POI）
  - [x] 分段 + 检索 + 检索测试 + 绑定智能体
- [x] **【交付】** 知识库接口（2026-10-29 已推送）
  - [x] 更新 `docs/api-admin.md` 变更记录
  - [x] `git commit` + `git push`
  - [ ] 搭档开工前 pull
- [x] 概览 / 算力 / 账单（`CreditTransaction` 流水 + 3 个聚合接口）（2026-10-28 完成并验收）
- [x] **【交付】** 运营接口（2026-10-29 已推送）
  - [x] 更新 `docs/api-admin.md` 变更记录
  - [x] `git commit` + `git push`
  - [ ] 搭档开工前 pull

### 前端线（搭档）

- [ ] 切「知识库」页（`admin-web`，接 `/api/admin/kb/**` 真接口）
- [ ] 切「数据概览」「账单」「算力使用」三页（`admin-web`，接运营接口）
- [ ] Flutter 用户 App 收尾：设置页（处理「待实现」区块）

---

## 8. 缓冲（Day 26~28，约 3 天）

### 一起

- [x] 后端线：**API 网关**（对外接口定义 + OpenAPI 导出）（2026-10-28 完成并验收）
  - [x] **【交付】** 网关接口（2026-10-29 已推送）
    - [x] 更新 `docs/api-admin.md` 变更记录
    - [x] `git commit` + `git push`
    - [ ] 搭档开工前 pull
- [ ] 后台前端：切「网关」页（`admin-web`，接 `/api/admin/gateway/**`）
- [ ] 端到端联调（App → 后台 → Curl 全链路）
- [ ] Flutter 用户 App 按老师提供的用户端原型逐页对照（13 页 + 公共组件）
- [ ] 演示脚本 + 录屏
- [ ] `docs/COMPONENTS.md` 定稿
- [ ] 关后门：`opc.security.dev-token-enabled = false`、`AppConfig.bypassLogin = false`
- [ ] （如老师要求容器化）`Dockerfile` + `docker-compose.yml` + `docs/DEPLOY.md`

---

## 9. 同步点总表

| # | 时间 | 做什么 | 时长 |
|---|---|---|---|
| 1 | Day 1 上午 | 对齐契约 / 归属 / 共写文件规矩 | 30 分钟 |
| 2 | Day 2 末 | P0 联合验收（真登录） | 30 分钟 |
| 3 | 每次交付接口 | 后端更新 `api-admin.md` 变更记录 + push；前端开工前 pull | 2 分钟 |
| 4 | 每周五 | 15 分钟进度同步（改了哪些接口/字段） | 15 分钟 |
| 5 | Day 28 | 端到端联调 + 演示脚本 | 1 天 |

**除此之外全部各做各的。**

---

## 最终验收清单（交付前逐项确认）

- [ ] Flutter 用户 App 按老师确认范围完成 28 页原型的视觉/交互复刻，至少包含 4 个一级 Tab 与创作主流程
- [ ] **后台控制台 `admin-web` 12 个页面可运行并接真接口**
- [ ] 管理端 P0~P8 接口全部可用
- [ ] 统一工具库包含：内置 + 模型 + MCP + 知识库
- [ ] `docs/api-admin.md` 变更记录与代码一致
- [ ] `docs/COMPONENTS.md` 包含 Flutter 用户 App 组件清单
- [ ] 演示脚本端到端跑通
- [ ] 关闭 `dev-token-enabled` 与 `bypassLogin`

---
## 10. 进度落后时的取舍顺序

| 优先级 | 内容 |
|---|---|
| **必保（答辩核心）** | P1 模型配置、P2 工作台、P3 调试、账单/算力 |
| **尽量保** | 知识库、用户管理、系统设置 |
| **可以砍** | MCP 试调用细节、素材库版本管理、向量化、网关 OpenAPI 导出、Docker |

> 从下往上砍。**P1/P2/P3 是「AI 后台」的门面，不能砍。**

---

## 11. 每周五填写

| 周次 | 后端线完成 | 前端线完成 | 阻塞项 | 下周调整 |
|---|---|---|---|---|
| W1 | | | | |
| W2 | | | | |
| W3 | | | | |
| W4 | | | | |
| W5 | | | | |
