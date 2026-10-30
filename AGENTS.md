# AGENTS.md · 给 AI 编码助手的项目说明

> 本文件供 Codex / Claude Code 等 AI 助手自动读取，人类协作者也可以按它索引文档。
> 最后更新：2026-10-30
>
> 🔴 **开始写代码前必须先读 `docs/SCHEDULE.md` §0～§3。**
> 当前冲刺优先级：**用户 App v2 UI 稳定 → 用户端订单/提交/审核/钱包后端 → 真实接口联调**。
> 如果当前执行者是前端搭档：先做 `lib/creator_flow/` 的乱码、字体、小屏和组件精修；后端接口未 push 前不要自行发明接口，也不要先做 `admin-web`。
> 如果当前执行者是后端：M0～M3 已完成，下一步实现 M4 文生图/图生视频 Harness 与音频 TTS。

---

## 一、这个项目是什么

OPC（一人公司）场景的 AI 内容生产平台，由三部分组成：

| 部分 | 目录 | 技术栈 | 状态 |
|---|---|---|---|
| **用户 App（前台）** | `lib/` | **Flutter 3（Web + Android）** | v2 已实现 16 页接单创作闭环；当前为演示数据，待接后端 |
| 后端 API | `server/` | Spring Boot 4.1.1 + Java 21 + Spring Data JPA + H2/MySQL | C 端 22 个接口 + 管理端 P0~P8 已完成 |
| **后台控制台（运营配置）** | **`admin-web/`** | **原生 HTML + CSS + JS** | 老师给的原型 + 已实现 12 页；需接真接口 |

### 架构（务必理解）

```text
用户 App（Flutter, lib/） ── /api/** ─────▶ server/ ──▶ Harness ──▶ AI Provider
运营后台（admin-web, HTML/JS） ── /api/admin/** ─▶ server/（配置 API / Skill / Harness / AI）
```

- **Flutter 只用于用户 App**（`lib/`）
- **后台控制台不是 Flutter**，就是 `admin-web/` 的 HTML/CSS/JS
- **不要创建 `lib/admin/`**，也不要再把后台控制台改成 Flutter
- 文生图 / 图生视频由 Flutter 调用 `/api/**` 发起；后端鉴权、扣算力、建任务，返回任务 ID，并通过任务查询接口回传状态和结果 URL。
- 后台通过 `/api/admin/**` 配置模型 API、Skill、Harness、知识库等；直接调用大模型的是后端，不是 App 或浏览器。
- “前端暴露接口”在实现中应理解为：**后端暴露 HTTP 接口，前端按契约调用并提交指令**。

---

## 二、需求与设计文档（改代码前先读）

| 文件 | 内容 |
|---|---|
| `docs/requirements-opc-admin.pdf` | **老师给的需求文档**：《OPC 文生图/图生视频 App 后台需求文档》 |
| `_req_doc.txt` | PDF 的全文文本提取版 |
| `docs/prototype-user/` | **老师提供的用户端移动 App HTML/CSS/JS 原型（28 个页面）**；Flutter 用户 App 的视觉和交互以此为准 |
| `docs/USER_PROTOTYPE_GAP.md` | **28 页原型与旧 Flutter 的对照、缺口和视觉参考** |
| `docs/USER_APP_V2.md` | **当前 16 页 Flutter 接单创作闭环、路由、演示状态和待接后端接口** |
| `docs/api-user.md` | 用户端订单/提交/审核/钱包契约；M0 冻结、M1/M2/M3 已实现 |
| `admin-web/` | **老师给的高保真原型** + 后台控制台实现（12 页） |
| `docs/api-admin.md` | **管理端接口契约（已冻结）** |
| `docs/api.md` | C 端 22 个接口契约 |
| `docs/SCHEDULE.md` | **当前任务的唯一进度表** |
| `docs/admin-freeze.md` | 三项共用模型冻结 + 文件归属 |
| `docs/COMPONENTS.md` | Flutter 组件清单（C 端） |
| `docs/HANDOFF.md` | C 端交接说明与已知问题 |
| `docs/ARCHITECTURE.md` | 后端架构、Flutter 目录、双端环境切换 |
| `docs/DATABASE.md` | C 端表结构与 Harness 设计 |

---

## 三、当前任务

### A. 用户 App（Flutter，`lib/`）

- [x] 新用户端 v2：登录/注册、接单大厅、订单详情、工作台、文生图、图生视频/生音频、提交、审核、作品详情、我的、充值/渠道、提现/渠道，共 16 页（2026-10-29）
- [ ] 前端搭档先修 16 页乱码、UTF-8、字体、特殊符号、小屏溢出和组件一致性
- [ ] 前端搭档完成 UI 检查表后，运行 `flutter analyze`、`flutter test`、`flutter build web --release`
- [x] 后端线完成 `docs/api-user.md`：订单、工作台、提交、审核、钱包、充值、提现（M0，2026-10-29）
- [x] 后端线 M1 订单/接单/工作台接口已实现（2026-10-29）
- [x] 后端线 M2 作品提交、审核状态和后台审核接口已实现（2026-10-30）
- [x] 后端线 M3 钱包、充值、提现、渠道与审核入账已实现（2026-10-30）
- [ ] 后端线新增音频 TTS 接口
- [ ] 后端线先按 M0～M4 完成契约、订单、提交审核、钱包和 AI 生成
- [ ] 前后端联调后，删除“模拟审核”按钮，所有状态改由后端返回

### B. 后台控制台（`admin-web/`，HTML/CSS/JS）

把后台控制台的 12 页接到真接口（`/api/admin/**`），覆盖：

1. 数据概览 / 用户管理 / 账单管理
2. 大模型配置（配置 API）
3. 智能体 Skill 配置（新建 Skill、搭建 Harness、编排节点）
4. 算力使用 / 系统设置
5. 调试 / MCP / 知识库 / 素材库 / 网关

- 使用 `AdminApi`，不要直接写 `fetch`
- 真接口模式：`http://127.0.0.1:5500/index.html?mock=0`
- mock 只用于视觉参考与离线演示

### C. 后端（`server/`）

P0~P8 已完成：模型配置、工作台、调试、MCP、知识库、运营账单、API 网关。
按需配合前端联调，不要改坏 C 端接口。

---

## 四、🔴 红线

1. **不许删 `MockAiProvider`** —— 没有商用 API key，答辩出图/出视频全靠它
2. **不许改 `t_skill` 的语义** —— 它是 App 的「创作线路」
3. **不许改坏 `/api/**` 那 22 个 C 端接口**
4. **不许改 `HarnessScheduler` / `TaskStateService` 的状态机逻辑**
5. **管理端不能用 dev-token 固定令牌**

---

## 五、怎么跑

```bash
# 后端
cd server
./mvnw spring-boot:run            # Windows: .\mvnw.cmd spring-boot:run
# → http://localhost:8080/api/health  /  http://localhost:8080/doc.html

# 用户 App（Flutter）
flutter pub get
flutter run -d chrome

# 后台控制台（HTML/JS，用 Live Server 打开）
# 视觉/mock：http://127.0.0.1:5500/index.html
# 真接口：  http://127.0.0.1:5500/index.html?mock=0
```

演示账号：`admin/admin123`（管理员）、`demo/demo123`（普通用户）。

---

## 六、交付前必须处理

- 用户 App v2 的 16 页无乱码、无小屏溢出
- 接单、提交、审核、钱包、充值、提现全部接真实后端
- 文生图、图生视频、音频 TTS 端到端可用
- `admin-web` 剩余页面接真接口
- 删除所有模拟审核入口
- `opc.security.dev-token-enabled` 改为 `false`
- `AppConfig.bypassLogin` 改为 `false`
- Web 构建、Flutter 测试、后端测试通过
- 端到端联调 + APK

---

## 七、协作纪律

- 不要在 github.com 网页上直接编辑文件
- C 端接口 → 先改 `docs/api-user.md`；管理端接口 → 先改 `docs/api-admin.md`，并记变更
- 开工前 `git pull`；完成一组任务就 commit；每周至少 push 一次
- `docs/SCHEDULE.md` 是进度真相源
