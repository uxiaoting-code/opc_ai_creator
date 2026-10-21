# OPC AI 后台 · 开发排期（5 周主线 + 3 天缓冲）

> 定稿日期：2026-10-17
> 分工：**后端线** = `server/` 主体；**前端线** = `admin-web/` + `lib/` + 3 个纯 CRUD 后端模块
> 口径：每周 5 个工作日、每天 6~8 小时有效投入。
> ⚠️ 如果实际是课余时间（每天 2~3 小时），整体时间 **×2~2.5**（约 10~12 周）。
>
> 配套文档：`docs/api-admin.md`（接口契约）、`docs/admin-freeze.md`（三项冻结 + 文件归属）、`docs/ADMIN_PLAN.md`（背景）

---

## 0. 分工速查

| | 后端线（你） | 前端线（搭档） |
|---|---|---|
| 主目录 | `server/` 主体 | `admin-web/` + `lib/` |
| 外加 | — | `server/.../admin/{material,user,setting}` + `PromptController` |
| 负责模块 | 模型配置 / 工作台 / 调试 / MCP / 知识库 / 概览·算力·账单 / 网关 | 控制台 12 页 / App 收尾 / 素材库后台 / 用户管理 / 系统设置 |
| 错误码段 | 6000-6499、6700-6799 | 6500-6599 |
| 人天 | ≈ 21 | ≈ 19 |

---

## 1. 依赖链（记住这一条就够）

```
后端线：P0 → P1 模型配置 → P2 工作台 → P3 调试 → P4 MCP → P5 知识库 → 运营 → 网关
前端线：Flutter组件 → Web P0 → Prompt/用户/设置/素材库 → 逐页切真数据 → App收尾 → 打包
                              ↑
                    每切一页，才需要那一页的接口（异步，不用同时在线）
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
- [ ] Day 3~5：**P1 模型/API 配置**（开始）
  - [ ] `AiProviderConfig` 实体 + Repository
  - [ ] 列表 / 新增 / 详情 / 修改
  - [ ] 鉴权配置、请求模板、响应模板
  - [ ] 连通性测试 `POST /api/admin/providers/{id}/test`
  - [ ] `AiProviderRouter.routeByConfig()` + 新增 `HttpApiProvider`

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

- [ ] **Day 2 末**：P0 联合验收（前端真登录）
- [ ] **Day 5 末**：mock 层验收（12 页能点通）

---

## 4. Week 2（Day 6~10）· 模型配置 + 前端闭环模块

### 后端线（你）

- [ ] P1 收尾（连通性测试 + 路由改造 + `HttpApiProvider`）
- [ ] **【交付】** 模型配置全套接口 → push + 群里说一声
- [ ] P2 智能体工作台（开始）
  - [ ] `Agent` / `AgentNode` / `AgentVersion` 实体
  - [ ] 列表 / 新建 / 详情 / 保存编排
  - [ ] `GET /api/admin/tools`（统一工具库）

### 前端线（搭档）

- [ ] `PromptController` + App 的 Prompt 知识库页
- [ ] 用户管理后端 + 页面（列表 / 加算力 / 冻结 / 重置密码）
- [ ] 系统设置后端 + 页面（平台参数 / 公告 / 3 个开关）

---

## 5. Week 3（Day 11~15）· 工作台 + 调试

### 后端线（你）

- [ ] P2 收尾（发布 / 复制 / 版本回滚 / 条件路由 / 预览）
- [ ] **【交付】** 工作台接口
- [ ] P3 调试面板（开始）
  - [ ] `CallLog` 表
  - [ ] 单节点调试 / 全链路调试 / 对话式 / 版本对比 / 回归用例

### 前端线（搭档）

- [ ] 素材库后台（后端 + 页面：分类 / 多级标签 / 检索 / 版本）
- [ ] 切「大模型配置」页（`USE_MOCK = false`）
- [ ] 切「智能体配置」页（两层结构）

---

## 6. Week 4（Day 16~20）· 调试 + MCP

### 后端线（你）

- [ ] P3 收尾 + **【交付】** 调试接口
- [ ] P4 MCP 接入
  - [ ] `McpServer` / `McpTool` 实体
  - [ ] 注册 / 发现 / 启用 / 映射 / 试调用

### 前端线（搭档）

- [ ] 切「调试」页（执行轨迹渲染）
- [ ] 切「MCP」页（Server 列表 + 工具开关 + 试调用）
- [ ] App 收尾开始（Skill 市场页）

---

## 7. Week 5（Day 21~25）· 知识库 + 运营 + 网关

### 后端线（你）

- [ ] P5 知识库
  - [ ] `KnowledgeBase` / `Document` / `Chunk`
  - [ ] 文本 / 文件（PDFBox / POI）/ URL / API 同步
  - [ ] 分段 + 检索 + 检索测试 + 绑定智能体
- [ ] **【交付】** 知识库接口
- [ ] 概览 / 算力 / 账单（`CreditTransaction` 流水 + 3 个聚合接口）

### 前端线（搭档）

- [ ] 切「知识库」页
- [ ] 切「数据概览」「账单」「算力使用」三页
- [ ] App 收尾（设置页）

---

## 8. 缓冲（Day 26~28，约 3 天）

### 一起

- [ ] 后端线：**API 网关**（对外接口定义 + OpenAPI 导出）→ **【交付】**
- [ ] 前端线：切「网关」页 + 打包 APK
- [ ] 端到端联调（App → 后台 → Curl 全链路）
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
| 3 | 每次交付接口 | 后端 push + 群里说一句，前端异步切页 | 2 分钟 |
| 4 | 每周五 | 15 分钟进度同步（改了哪些接口/字段） | 15 分钟 |
| 5 | Day 28 | 端到端联调 + 演示脚本 | 1 天 |

**除此之外全部各做各的。**

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
