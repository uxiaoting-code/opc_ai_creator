# CLAUDE.md

> 项目说明统一维护在 [`AGENTS.md`](./AGENTS.md)，**请先读它**。

## 架构（务必理解）

- **Flutter = 用户 App**（`lib/`，已有 13 页基础实现；需按 `docs/prototype-user/` 的 28 页原型对齐）
- **后台控制台 = HTML/CSS/JS**（`admin-web/`，12 页）
- **后端 = Spring Boot**（`server/`，`/api/**` + `/api/admin/**`）
- **不要创建 `lib/admin/`**，后台控制台不是 Flutter

## 当前任务

### A. 用户 App（Flutter）

- [ ] 按 `docs/prototype-user/` 的老师用户端原型逐页对照 Flutter 页面与公共组件
- [ ] Skill 市场页（替换 `lib/pages/skill/skill_market_page.dart` 占位）
- [ ] 设置页（处理 `lib/pages/settings/settings_page.dart` 的「待实现」区块）
### B. 后台控制台（admin-web）

- [ ] 12 页接 `/api/admin/**` 真接口（`?mock=0`）
- [ ] 覆盖 API 配置、Skill 新建、Harness 编排、智能体/调试/MCP/知识库/素材库/账单/网关

详细任务见 `docs/SCHEDULE.md`。
## 红线

1. 不许删 `MockAiProvider`
2. 不许改 `t_skill` 的语义
3. 不许改坏 `/api/**` 那 22 个 C 端接口
4. 后台控制台 UI 以 `admin-web/` 原型为准
5. 管理端接口契约见 `docs/api-admin.md`，要改先改契约
