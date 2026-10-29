# AGENTS.md · 给 AI 编码助手的项目说明

> 本文件供 Codex / Claude Code 等 AI 助手自动读取，人类协作者也可以按它索引文档。
> 最后更新：2026-10-29

---

## 一、这个项目是什么

OPC（一人公司）场景的 AI 内容生产平台，由四部分组成：

| 部分 | 目录 | 技术栈 | 状态 |
|---|---|---|---|
| 终端 App（前台） | `lib/` | Flutter 3（Web + Android 双端） | 13 页中 12 页完成，**Skill 市场页仍是占位** |
| 后端 API（C 端） | `server/` | Spring Boot 4.1.1 + Java 21 + Spring Data JPA + H2/MySQL | 22 个 C 端接口，已跑通 |
| **后台控制台（最终交付）** | **`lib/admin/`** | **Flutter（复刻 `admin-web/` 原型）** | ⚠️ **尚未开始，当前最高优先级** |
| 后台原型（视觉参考） | `admin-web/` | 原生 HTML + CSS + JS | ✅ 已完成，**只作视觉/字段参考** |

> 目录提醒：`web/` 是 Flutter Web 的启动壳，**不是后台控制台**。
> 后台的**视觉参考**在 `admin-web/`，**最终交付**是 `lib/admin/` 的 Flutter 版本。
> 运行 App：`flutter run -d chrome`；运行 Flutter 管理端：`flutter run -d chrome -t lib/admin/main_admin.dart`。

---

## 二、需求与设计文档（改代码前先读）

| 文件 | 内容 |
|---|---|
| `docs/requirements-opc-admin.pdf` | **老师给的需求文档**：《OPC 文生图/图生视频 App 后台需求文档》 |
| `_req_doc.txt` | PDF 的全文文本提取版（检索用这个更方便） |
| `admin-web/` | **老师给的高保真原型**（7 个页面）+ 已完成的原生 JS 实现，作为 Flutter 复刻的视觉基准 |
| `docs/api-admin.md` | **管理端接口契约（已冻结）**：12 个页面的接口 / 字段 / 错误码 / 枚举 |
| `docs/admin-freeze.md` | 三项共用模型冻结 + 共享文件切分 |
| `docs/SCHEDULE.md` | **当前任务的唯一进度表**：谁做什么、做到哪、验收标准 |
| `docs/COMPONENTS.md` | Flutter 组件清单（C 端 + 管理端） |
| `docs/ADMIN_PLAN.md` | 背景、现状盘点、历史分工（纵切版，已作废，仅背景参考） |
| `docs/HANDOFF.md` | C 端（App + 后端）交接说明与已知问题 |
| `docs/ARCHITECTURE.md` | 后端架构、Flutter 目录结构、双端环境切换 |
| `docs/DATABASE.md` | 7 张 C 端表的 DDL 与设计 |
| `docs/api.md` | C 端 22 个接口的契约 |

---

## 三、当前任务（最高优先级）

**用 Flutter 复刻 `admin-web/` 的后台原型，交付 `lib/admin/`。**

顺序：
1. 先做**组件层**（`AdminShell` / `AdminTable` / `AdminToolbar` / `StatCard` / `PanelCard` / `StatusBadge` / `AdminToggle` / `AdminModal` / `PaginationBar`）
2. 再做 12 个页面（登录、概览、用户、账单、模型、智能体、算力、设置、调试、MCP、知识库、素材库、网关）
3. 最后接 `/api/admin/**` 真接口

> 详细任务与勾选框见 `docs/SCHEDULE.md` §6.5。
> `admin-web/` 的 HTML/CSS/JS **不是最终交付物**，不要继续在它上面加新功能。

后端 P0~P8 已完成：模型配置、工作台、调试、MCP、知识库、运营账单、API 网关。

---

## 四、🔴 红线（改坏了会连带 App 一起崩）

1. **不许删 `MockAiProvider`** —— 没有商用 API key，答辩出图/出视频全靠它
2. **不许改 `t_skill` 的语义** —— 它是 App 的「创作线路」，和原型里的「Skill（智能体可调用的工具）」不是一回事
3. **不许改坏 `/api/**` 那 22 个 C 端接口**的 URL / 入参 / 返回字段 —— App 全靠它们
4. **不许改 `HarnessScheduler` / `TaskStateService` 的状态机逻辑**
5. **管理端不能用 dev-token 固定令牌** —— 必须在 `AuthInterceptor` 里对 `/api/admin/**` 判死

---

## 五、怎么跑

```bash
# 后端：H2 文件库，开箱即跑，不需要安装 MySQL
cd server
./mvnw spring-boot:run            # Windows: .\mvnw.cmd spring-boot:run
# → 健康检查 http://localhost:8080/api/health
# → 接口文档 http://localhost:8080/doc.html
# 若 mvnw 报错，用 IntelliJ 运行 OpcServerApplication，或直接 java -jar target\opc-server-0.0.1-SNAPSHOT.jar

# Flutter App
flutter pub get
flutter run -d chrome

# 后台原型（视觉参考，需要 HTTP 服务，不能直接双击）
# 用 VS Code Live Server 打开 admin-web/index.html

# Flutter 管理端（组件/页面做出来后）
flutter run -d chrome -t lib/admin/main_admin.dart
```

首次启动会自动初始化：`demo / demo123`（普通用户）、`admin / admin123`（管理员）、6 条创作线路、5 条 Prompt、6 条模型配置、2 个智能体、知识库、MCP 演示数据、算力流水、网关接口。

环境要求：**JDK 21**、**Flutter SDK**（打包 Android 还需要 Android SDK）。

---

## 六、交付 / 答辩前必须处理

- `opc.security.dev-token-enabled` 改为 `false`（`server/src/main/resources/application.yml`）
- `AppConfig.bypassLogin` 改为 `false`（`lib/core/config/app_config.dart`）
- App 的 `Skill 市场页`（`lib/pages/skill/skill_market_page.dart`）仍是占位，需要完成
- 设置页的「待实现」区块需要实现或删除
- Flutter 管理端 12 页 + `docs/COMPONENTS.md` 管理端清单

---

## 七、协作纪律

- **不要在 github.com 网页上直接编辑本仓库的文件**（会和本地提交分叉，一推送就冲突）
- 改接口 → **先改 `docs/api-admin.md`** 并在「变更记录」加一行，再改代码
- **每次开工前 `git pull`**，每完成一组任务就 commit，每周至少 push 一次
- `docs/SCHEDULE.md` 是进度真相源；完成一项就勾一项
