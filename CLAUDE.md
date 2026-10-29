# CLAUDE.md

> 本仓库的项目说明统一维护在 [`AGENTS.md`](./AGENTS.md)，**请先读它**。
> 这里只重复当前任务和最关键的红线。

## 当前任务（最高优先级）

**用 Flutter 复刻 `admin-web/` 的后台原型，交付 `lib/admin/`。**

- `admin-web/` 是**视觉参考**，不是最终交付物
- 先做组件（`AdminShell` / `AdminTable` / `AdminToolbar` / `StatCard` / `PanelCard` / `StatusBadge` / `AdminToggle` / `AdminModal` / `PaginationBar`）
- 再做 12 个页面（登录、概览、用户、账单、模型、智能体、算力、设置、调试、MCP、知识库、素材库、网关）
- 运行：`flutter run -d chrome -t lib/admin/main_admin.dart`
- 详细任务：`docs/SCHEDULE.md` §6.5

## 红线

1. 不许删 `MockAiProvider`
2. 不许改 `t_skill` 的语义（它是 App 的创作线路，不是原型里的「Skill 工具」）
3. 不许改坏 `/api/**` 那 22 个 C 端接口
4. 管理端 UI 以 `admin-web/` 原型为准，Flutter 版 1:1 复刻
5. 管理端接口契约见 `docs/api-admin.md`（已冻结），**要改先改契约**

## 关键文档

- 需求文档：`docs/requirements-opc-admin.pdf`（全文文本版：`_req_doc.txt`）
- 管理端契约：`docs/api-admin.md`
- 进度与分工：`docs/SCHEDULE.md`
- 三项冻结 + 文件归属：`docs/admin-freeze.md`
- 组件清单：`docs/COMPONENTS.md`
- C 端交接说明：`docs/HANDOFF.md`
