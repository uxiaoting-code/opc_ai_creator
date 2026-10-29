# Flutter 组件清单

> 预览方式：登录 App 后进入「设置 → 打开组件预览（开发用）」，或直接打开 `/dev/components`。
> 预览页：`lib/pages/dev/component_gallery_page.dart`

## 规则

1. 组件只依赖 `lib/data/models/` 和主题/间距，**不 import**
   `api_client` / `repository` / `provider`。
2. 组件不发网络请求，数据由页面传进来，点击通过回调交回页面。
3. 组件不写死业务文案，能配置的都用参数暴露。
4. 新增组件放在 `lib/widgets/creation/`，并在预览页加一块示例。

---

## 1. PromptInputCard

**文件**：`lib/widgets/creation/prompt_input_card.dart`

**作用**：提示词输入卡。玻璃底、无边框输入、标题行。

| 参数 | 说明 |
|---|---|
| `controller` | `TextEditingController`，必填 |
| `title` | 标题，默认「描述画面」 |
| `hintText` | 占位文案 |
| `maxLength` | 最大长度，默认 2000 |
| `minLines` / `maxLines` | 输入框行数 |
| `enabled` | 是否可输入 |
| `onChanged` | 文本变化回调 |
| `trailing` | 标题右侧自定义控件 |

---

## 2. SkillSelector

**文件**：`lib/widgets/creation/skill_selector.dart`

**作用**：横向创作线路胶囊，支持「自动线路」。

| 参数 | 说明 |
|---|---|
| `skills` | `List<SkillModel>` |
| `selectedId` | 当前线路 ID，null 表示自动 |
| `onChanged` | 选择回调，传回 `int?` |
| `title` / `subtitle` | 标题与说明 |
| `allowAuto` | 是否显示「自动线路」 |

---

## 3. SizePicker

**文件**：`lib/widgets/creation/size_picker.dart`

**作用**：比例 / 尺寸胶囊选择。

| 参数 | 说明 |
|---|---|
| `sizes` | 可选尺寸，如 `['1:1','3:4']` |
| `selected` | 当前选中值 |
| `onChanged` | 选择回调 |
| `label` | 标题，默认「比例」 |

---

## 4. ParamSliderRow

**文件**：`lib/widgets/creation/param_slider_row.dart`

**作用**：一行「标题 + 滑杆 + 数值」参数。

| 参数 | 说明 |
|---|---|
| `label` | 参数名 |
| `value` / `min` / `max` | 当前值与范围 |
| `divisions` | 分段数 |
| `onChanged` | 拖动回调 |
| `valueLabel` | 自定义数值文案 |

---

## 5. GenerateBar

**文件**：`lib/widgets/creation/generate_bar.dart`

**作用**：底部固定生成栏，显示算力消耗和渐变主按钮。

| 参数 | 说明 |
|---|---|
| `creditCost` | 预计消耗算力 |
| `credits` | 当前余额，null 表示未知 |
| `submitting` | 是否提交中 |
| `label` | 按钮文案，默认「开始生成」 |
| `onGenerate` | 点击回调 |
| `hint` | 按钮下方提示 |
| `leading` | 左侧自定义控件（如线路选择） |

---

## 6. ResultPreviewCard

**文件**：`lib/widgets/creation/result_preview_card.dart`

**作用**：结果预览卡，支持图片、视频和渐变占位。

| 参数 | 说明 |
|---|---|
| `title` / `subtitle` | 标题与说明 |
| `imageUrl` | 图片地址 |
| `videoUrl` | 视频地址（优先于图片） |
| `onTap` | 点击回调 |
| `aspectRatio` | 预览比例，默认 4:3 |

---

## 7. TaskStatusCard

**文件**：`lib/widgets/creation/task_status_card.dart`

**作用**：任务状态卡，展示状态、进度、耗时、重试/取消。

| 参数 | 说明 |
|---|---|
| `task` | `TaskModel?`，null 显示空状态 |
| `onTap` | 打开任务详情 |
| `onRetry` / `onCancel` | 重试 / 取消回调 |

> 是否显示重试/取消由后端返回的 `task.canRetry` / `task.canCancel` 决定，
> 组件不自己判断状态机。

---

## 8. CreditChip

**文件**：`lib/widgets/creation/credit_chip.dart`

**作用**：算力余额胶囊，大数字自动显示「万 / 亿」。

| 参数 | 说明 |
|---|---|
| `credits` | 算力点数，null 显示「—」 |
| `onTap` | 点击回调 |

---

## 预览页

`lib/pages/dev/component_gallery_page.dart`

- 路由：`/dev/components`
- 不在 `RouteNames.allBusinessPaths` 里，所以不会影响「13 个业务页面」的测试。
- 页面上每个组件都有名称、说明和可点击示例。

---

## 管理端组件（待做，见 `docs/SCHEDULE.md` §6.5）

> 目标：把 `admin-web/` 的原生 HTML/CSS 组件用 Flutter 复刻到 `lib/admin/widgets/`。
> 完成后在本文件补充每个组件的参数/回调表。

| 组件 | 作用 |
|---|---|
| `AdminShell` | 深色侧栏 + 顶栏 + 内容区 |
| `AdminTable<T>` | 通用表格：columns + rows + cellBuilder |
| `PaginationBar` | 分页条 |
| `AdminToolbar` | 搜索 + 筛选 + 主按钮 |
| `StatCard` | 指标卡（大数字 + 环比） |
| `PanelCard` | 面板容器（标题 + 右侧说明 + 内容） |
| `StatusBadge` | 状态徽章（正常/冻结、已发布/草稿…） |
| `AdminToggle` | 上架/启用开关 |
| `AdminModal` | 弹窗（新建/加算力/接入模型/添加 Skill） |
| `AdminEmptyState` | 空状态 |

**组件规则**：数据进、事件出；回调可空；状态由外部传入；不 import `api_client` / `repository` / `provider`；不导航、不弹窗、不写死业务文案。
