# CLAUDE.md

> 本仓库的项目说明统一维护在 [`AGENTS.md`](./AGENTS.md)，**请先读它**。
> 这里只重复最关键的几条：

## 红线
1. 不许删 `MockAiProvider`
2. 不许改 `t_skill` 的语义（它是 App 的创作线路，不是原型里的「Skill 工具」）
3. 不许改坏 `/api/**` 那 22 个 C 端接口
4. 管理端 UI 以老师给的 `web/` 原型为准，不要自己重新设计
5. 管理端接口契约见 `docs/api-admin.md`（已冻结），**要改先改契约**

## 关键文档
- 需求文档：`docs/requirements-opc-admin.pdf`（全文文本版：`_req_doc.txt`）
- 管理端契约：`docs/api-admin.md`
- 三项冻结 + 文件归属：`docs/admin-freeze.md`
- 开发顺序 + 分工：`docs/ADMIN_PLAN.md`
- C 端交接说明：`docs/HANDOFF.md`

## 当前任务
把 `web/` 的后台原型改成能用的后台（页面照原型，数据接真库）。分工为**前后端**：一人 `server/`，一人 `web/` + `lib/`。
