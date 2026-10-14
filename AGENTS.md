# AGENTS.md · 给 AI 编码助手的项目说明

> 本文件供 Codex / Claude Code 等 AI 助手自动读取，人类协作者也可以按它索引文档。
> 最后更新：2026-10-14

---

## 一、这个项目是什么

OPC（一人公司）场景的 AI 内容生产平台，由三部分组成：

| 部分 | 目录 | 技术栈 | 状态 |
|---|---|---|---|
| 终端 App（前台） | `lib/` | Flutter 3（Web + Android 双端） | 13 页，11 页完成，2 页占位 |
| 后端 API（C 端） | `server/` | Spring Boot 4.1.1 + Java 21 + Spring Data JPA + H2/MySQL | 22 个接口，已跑通 |
| **后台控制台（管理端）** | `web/` | 原生 HTML + CSS + JS | ⚠️ 老师给的**静态原型**，**本轮要做的就是它** |

---

## 二、需求与设计文档（改代码前先读）

| 文件 | 内容 |
|---|---|
| `docs/requirements-opc-admin.pdf` | **老师给的需求文档**：《OPC 文生图/图生视频 App 后台需求文档》 |
| `_req_doc.txt` | 上面那份 PDF 的**全文文本提取版**（检索、引用用这个更方便） |
| `web/` | **老师给的高保真原型**（7 个页面）。管理端 UI 以它为准，**不要自己重新设计** |
| `docs/api-admin.md` | **管理端接口契约（已冻结）**：12 个页面的接口 / 字段 / 错误码 / 枚举 |
| `docs/admin-freeze.md` | **三项共用模型冻结** + 共享文件切分 + 开工检查清单 |
| `docs/ADMIN_PLAN.md` | 现状盘点、开发顺序、两人分工 |
| `docs/HANDOFF.md` | C 端（App + 后端）交接说明与已知问题 |
| `docs/ARCHITECTURE.md` | 后端架构、Flutter 目录结构、双端环境切换 |
| `docs/DATABASE.md` | 7 张表的 DDL 与设计 |
| `docs/api.md` | C 端 22 个接口的契约 |

---

## 三、当前任务

把 `web/` 的后台原型**变成能用的后台**：页面结构、字段、交互照原型，数据接真库。

开发顺序（详见 `docs/ADMIN_PLAN.md`）：
管理端地基 → 模型/API 配置 → 智能体工作台 → 调试面板 → MCP → 知识库/素材库 → 算力运营 → 对外网关 → App 收尾

分工（已定稿）：**一人 `server/` 主体**（模型配置/工作台/调试/MCP/知识库/概览·算力·账单/网关），**另一人 `web/` + `lib/` + 3 个纯 CRUD 后端模块**（素材库后台/用户管理/系统设置 + `PromptController`）。文件归属见 `docs/admin-freeze.md` §4.1。

---

## 四、🔴 红线（改坏了会连带 App 一起崩）

1. **不许删 `MockAiProvider`** —— 没有商用 API key，答辩出图 / 出视频全靠它
2. **不许改 `t_skill` 的语义** —— 它是 App 的「创作线路」（二次元插画/写实摄影…），和原型里的「Skill（智能体可调用的工具）」**不是一回事**
3. **不许改坏 `/api/**` 那 22 个 C 端接口**的 URL / 入参 / 返回字段 —— App 全靠它们
4. **不许改 `HarnessScheduler` / `TaskStateService` 的状态机逻辑**
5. **管理端不能用 dev-token 那个固定令牌** —— 必须在 `AuthInterceptor` 里对 `/api/admin/**` 判死

---

## 五、怎么跑

```bash
# 后端：H2 文件库，开箱即跑，不需要安装 MySQL
cd server
./mvnw spring-boot:run            # Windows: .\mvnw.cmd spring-boot:run
# → 健康检查 http://localhost:8080/api/health
# → 接口文档 http://localhost:8080/doc.html

# 控制台原型：直接用浏览器打开 web/index.html（或用 VS Code 的 Live Server）

# Flutter App
flutter pub get
flutter run -d chrome
```

首次启动会自动初始化：`demo / demo123`（普通用户）、`admin / admin123`（管理员）、6 条创作线路、5 条 Prompt。

环境要求：**JDK 21**、**Flutter SDK**（打包 Android 还需要 Android SDK）。

---

## 六、交付 / 答辩前必须处理

- `opc.security.dev-token-enabled` 改为 `false`（`server/src/main/resources/application.yml`）
- `AppConfig.bypassLogin` 改为 `false`（`lib/core/config/app_config.dart`）

---

## 七、协作纪律

- **不要在 github.com 网页上直接编辑本仓库的文件**（会和本地提交分叉，一推送就冲突）
- 改接口 → **先改 `docs/api-admin.md`** 并在「变更记录」加一行，再改代码，两人同步
- 提交前先 `git pull`
