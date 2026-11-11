# CLAUDE.md

> 项目说明统一维护在 [`AGENTS.md`](./AGENTS.md)，**请先读它**。

## 架构（务必理解）

- **Flutter = 用户 App**（`lib/`，四 Tab 接单创作闭环已接真实接口；按 `docs/prototype-user/` 继续精修）
- **后台控制台 = HTML/CSS/JS**（`admin-web/`，12 页）
- **后端 = Spring Boot**（`server/`，`/api/**` + `/api/admin/**`）
- **不要创建 `lib/admin/`**，后台控制台不是 Flutter

## 当前任务

### A. 用户 App（Flutter）

- [ ] 按 `docs/SCHEDULE.md` 完成 F8 钱包/个人中心统一，再做原型视觉对照和小屏验收
- [ ] 完成 F8 后执行最终端到端联调和 Web/APK 构建
- [ ] 保持旧页面兼容，不删除 `web_old/` 和旧 Flutter 页面
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
