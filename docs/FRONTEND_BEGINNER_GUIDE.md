# 前端线小白上手指南

> 写给你：第一次接触这个项目、看到一堆文档就头大的人。
> 看完这份，你不需要记住所有细节，只要知道三件事：
> 1. 这个项目是什么；
> 2. 你负责哪几块；
> 3. 今天先做什么。

## 怎么用这份文档

- **如果你只有 10 天**：先看 [前端线 10 天全量冲刺计划](FRONTEND_10DAY_PLAN.md)，再回来查这份的细节。
- **第一次看**：只看第 0、2、5、10 节，先建立整体印象。
- **做到哪一步**：再翻对应章节，不用从头背。
- **名词看不懂**：查第 3 节。
- **不敢下手**：看第 7 节“绝对不能碰”。
- **不知道看哪份原文档**：查第 8 节的对照表。

---

## 0. 先用三句话看懂这个项目

把整个项目想成一家店：

| 店里的角色 | 项目里的东西 | 大白话 |
|---|---|---|
| 顾客用的点单界面 | `lib/`（Flutter App） | 用户手机上看到的 App |
| 后厨 | `server/`（Spring Boot 后端） | 真正做图、做视频、扣算力、存数据的地方 |
| 店长后台 | `admin-web/`（HTML + CSS + JS） | 管理员配置模型、管用户、看账单的网页 |

App 和后厨已经能跑；店长后台现在是个“样板间”——看起来能点，但数据是假的、登录也是假的。

**你的任务：把样板间接上真水电，再补几个新房间。**

---

## 1. 你现在面对的“半成品”到底是什么

### 1.1 `admin-web/` 是样板间，不是真后台

- 页面能点、弹窗能开，但表格里的数字全是写死的。
- 登录框输入什么都能进，因为它根本没有调后端。
- 整个 `admin-web/js/admin.js` 里没有一次网络请求。

所以它不是“坏了”，而是老师给的高保真原型。

你要做的是：**保留长相，换掉里面的假数据。**

### 1.2 后端的“门卫”已经装好了

- 管理端登录接口已经做好：`POST /api/admin/auth/login`
- 管理员账号：`admin / admin123`
- 普通用户 `demo / demo123` 登后台会被拒绝（403）
- 固定开发令牌 `mock-token-for-scaffold` 也不能进管理端

也就是说：**真登录这件事，后端已经准备好了，只差你页面上接一下。**

### 1.3 App 已经完成了大半

- 13 个页面里 11 个能用。
- 剩下两个是空壳：Prompt 知识库、Skill 市场。
- 设置页还有一块“待实现”。

### 1.4 你还要写一点后端

因为分工是“前端线 + 3 个纯 CRUD 后端模块”，所以你不只是写页面，还要写：

- 用户管理后端
- 系统设置后端
- 素材库后台后端
- 一个 `PromptController`

别怕，这四个都是“照着契约填表格”的活，不是让你从零设计架构。

---

## 2. 你这条线要交的 5 样东西

| # | 交付物 | 大白话 | 大概工作量 |
|---|---|---|---|
| 1 | Web 控制台 12 页 | 把样板间变成真后台 | 最大头 |
| 2 | Flutter 组件 + App 收尾 | 把重复 UI 做成积木，再补 2 个空壳页 | 中等 |
| 3 | 用户管理后端 | 用户列表、加算力、冻结、重置密码 | 小 |
| 4 | 系统设置后端 | 平台参数、公告、3 个开关 | 小 |
| 5 | 素材库后台 + PromptController | 素材分类/标签/检索 + App 的 Prompt 数据 | 中等 |

你不需要负责：模型配置、智能体工作台、调试面板、MCP、知识库、账单/算力统计、API 网关的**后端**。

这些页面的**前端**仍然由你画，但数据接口由搭档提供。

---

## 3. 先认识 15 个词，够用了

| 名词 | 人话解释 |
|---|---|
| 前端 | 用户看得到、点得到的部分 |
| 后端 | 用户看不到、真正干活的部分 |
| 接口 / API | 前端和后端约好的“窗口”：你递一张纸条，它回一张纸条 |
| 请求 / 响应 | 递纸条 / 回纸条 |
| JSON | 一种像快递清单一样的数据格式，长这样：`{ "name": "张三" }` |
| Token | 登录后拿到的“临时通行证”，之后每次请求都要带上 |
| 鉴权 | 检查你有没有通行证、是不是管理员 |
| CRUD | 增、删、改、查四个动作 |
| 分页 | 数据太多，一次只给一页 |
| Mock | 假数据。后端没好时，先用它把页面跑起来 |
| Flutter | 写 App 的工具 |
| HTML / CSS / JS | 写网页的三件套：骨架 / 皮肤 / 动作 |
| 数据库 / 表 | 存数据的仓库 / 仓库里的一张张表格 |
| Repository | 专门负责“拿数据”的类 |
| Provider | 专门负责“把数据分发给页面”的类 |

还有一个词你会经常看到：**枚举**。

枚举就是“一组固定选项”。比如智能体状态只有：

```
DRAFT（草稿） / PUBLISHED（已发布） / OFFLINE（已下线）
```

接口会同时给你 `status` 和 `statusLabel`，页面直接显示 `statusLabel`，你不需要自己翻译。

---

## 4. 现在仓库里有什么、没有什么

### 4.1 已经有的

- `server/`：22 个 App 接口 + 管理端登录/鉴权（P0）。
- `admin-web/`：老师给的 7 页原型。
- `lib/`：App 的 11 个可用页面。
- `docs/`：需求、接口契约、排期、交接说明。

### 4.2 还没有的（都是你要建的）

- `admin-web/js/api.js`：统一发请求的地方。
- `admin-web/js/util.js`：格式化算力、日期、Toast 等小工具。
- `admin-web/js/pages/*.js`：一页一个 JS 文件。
- `admin-web/mock/*.json`：假数据。
- 5 个新后台页面：调试、MCP、知识库、素材库、网关。
- `server/.../admin/user/`：用户管理后端。
- `server/.../admin/setting/`：系统设置后端。
- `server/.../admin/material/`：素材库后台后端。
- `server/.../controller/PromptController.java`：Prompt 接口。
- `lib/pages/dev/component_gallery_page.dart`：组件预览页。
- `docs/COMPONENTS.md`：组件清单。

### 4.3 环境情况

- Java 21：已就绪。
- `server/mvnw.cmd`：已就绪。
- Flutter：当前这台机器的命令行里**找不到** `flutter`，需要先装好或加入 PATH。

---

## 5. 你的任务顺序：照着做，不要跳

### 第 0 步：先把项目跑起来，别急着写代码

**启动后端：**

```powershell
cd server
.\mvnw.cmd spring-boot:run
```

看到启动成功后，浏览器打开：

```
http://localhost:8080/api/health
```

返回 `code: 200` 就说明后厨活着。

**打开后台原型：**

直接用浏览器打开 `admin-web/index.html`，或者用 VS Code 的 Live Server。

现在你看到的登录页是假的，输入什么都进。这是正常的，下一步才改成真登录。

**启动 App：**

先确认 Flutter 可用：

```powershell
flutter doctor
flutter run -d chrome
```

如果 `flutter` 命令找不到，先装 Flutter SDK，或者把它的 `bin` 目录加到 PATH。**这一步不解决，App 相关任务没法做。**

> 如果你运行 `flutter run -d chrome` 看到的是“星枢 AI 聚合平台 · 服务端后台”，
> 说明 Flutter 的 Web 壳又被后台页面覆盖了。后台在 `admin-web/`，
> Flutter 的 `web/index.html` 里必须有 `<script src="flutter_bootstrap.js">`。

---

### 第 1 步（约 2 天）：做 Flutter 积木

老师明确要求先做组件。组件就是“可以重复用的 UI 积木”。

你要做 8 个：

| 组件 | 干什么用的 |
|---|---|
| `PromptInputCard` | 输入提示词、负面提示词，带字数统计 |
| `SkillSelector` | 选择创作线路（二次元 / 写实 / 电商…） |
| `SizePicker` | 选图片尺寸 |
| `ParamSliderRow` | 一行“标题 + 滑杆 + 数值” |
| `GenerateBar` | 底部“消耗多少算力 + 开始生成”按钮 |
| `ResultPreviewCard` | 展示生成结果，带下载/重试等按钮 |
| `TaskStatusCard` | 展示任务状态、进度、重试/取消 |
| `CreditChip` | 展示算力余额 |

再加一个组件预览页：

```
lib/pages/dev/component_gallery_page.dart
```

规则只有一条，但很重要：

> **组件只依赖 `lib/data/models/`，不要在组件里发网络请求。**

不要 `import` 这些东西：

- `api_client`
- `repository`
- `provider`

组件只负责“长什么样”和“点了以后回调什么”，数据从外面传进来。

最后写一份 `docs/COMPONENTS.md`，列出每个组件的名字、用途、参数。以后别人接手能看懂。

---

### 第 2 步（约 3 天）：Web 地基

这一步是把样板间接上真水电。

#### 2.1 新建 `admin-web/js/api.js`

它只干一件事：**所有网络请求都从这里走。**

它要负责：

- 拼后端地址（比如 `http://localhost:8080/api/admin`）
- 自动带上 `Authorization: Bearer <token>`
- 统一处理错误
- 401 时把用户踢回登录页
- 有一个 `USE_MOCK` 开关：后端没好的页面先用假数据

以后每个页面都不要自己写 `fetch`，统一调 `api.js`。

#### 2.2 新建 `admin-web/js/util.js`

放小工具：

- `formatCredits()`：把 `9260000` 显示成 `926 万`
- 日期格式化
- Toast 提示
- `$` / `$$` 选择器

算力只在这里做显示转换，**不要改数据库里的数**。

#### 2.3 拆 `admin-web/js/admin.js`

现在 541 行全挤在一个文件里。拆成：

```
admin-web/js/app.js          登录、侧栏、页面切换、弹窗
admin-web/js/pages/dash.js
admin-web/js/pages/users.js
admin-web/js/pages/bills.js
admin-web/js/pages/models.js
admin-web/js/pages/agents.js
admin-web/js/pages/usage.js
admin-web/js/pages/settings.js
admin-web/js/pages/debug.js
admin-web/js/pages/mcp.js
admin-web/js/pages/kb.js
admin-web/js/pages/materials.js
admin-web/js/pages/gateway.js
```

一页一个文件，谁也不用在一个 500 多行的文件里找代码。

#### 2.4 登录改成真的

现在 `admin.js` 里是假登录。改成：

1. 调 `POST /api/admin/auth/login`
2. 拿到 `data.token`
3. 存到 `localStorage`
4. 后面请求都带上
5. 退出时清掉 token

测试账号：

```
admin / admin123
```

原型上写的 `admin@2026` 是假密码，别被骗。

#### 2.5 建 mock 数据

在 `admin-web/mock/` 下按页面放 JSON，字段照 `docs/api-admin.md` 抄。

这样后端还没交付的页面，你也能先把 12 页点通。

#### 2.6 侧栏加 5 个新入口

现在侧栏只有 7 项。要加：

- 调试
- MCP
- 知识库
- 素材库
- 网关

在 `index.html` 里追加 5 个 `<section>`，样式照原型，不要重新设计。

**这一步的验收：** 12 个页面都能点开，控制台不报错，登录是真的。

---

### 第 3 步（第 2 周）：Prompt + 用户 + 设置

#### 3.1 先写 `PromptController`

这是最简单的后端活，而且能同时解锁 App 的 Prompt 页。

但注意：**这个接口的契约目前是空白**。

`docs/api.md` 和 `docs/api-admin.md` 都没有 `/api/prompts` 的字段定义。动手前先和搭档确认一版最小契约，比如：

- `GET /api/prompts`：列表
- `GET /api/prompts/{id}`：详情
- `POST /api/prompts/{id}/favorite`：收藏/取消收藏

字段从 `Prompt` 实体来：`id`、`title`、`content`、`category`、`tags`、`coverUrl`、`favoriteCount` 等。

写完后更新文档，再写 App 页面。

#### 3.2 用户管理

后端接口：

- 列表：`GET /api/admin/users?page&pageSize&keyword&status`
- 新增：`POST /api/admin/users`
- 加算力：`POST /api/admin/users/{id}/credits`
- 冻结/解冻：`POST /api/admin/users/{id}/freeze` / `/unfreeze`
- 重置密码：`POST /api/admin/users/{id}/reset-password`
- 详情：`GET /api/admin/users/{id}`

页面就是原型里的“用户管理”：搜索、状态筛选、表格、加算力弹窗。

注意两件事：

- 手机号脱敏（`186****3000`）由**后端**做。
- 加算力必须同时写一条 `ADMIN_ADJUST` 流水，不能只改余额。

#### 3.3 系统设置

后端接口：

- `GET /api/admin/settings`
- `PUT /api/admin/settings`
- `PUT /api/admin/settings/switches`
- `POST /api/admin/announcements`

页面就是原型里的“系统设置”：平台名称、赠送算力、充值赠送比例、算力单价、公告、3 个开关。

这里有一个跨模块的事：`signupBonusCredits` 要接管现在硬编码在 3 个地方的“新用户送 10000 点”。那 3 个地方在搭档负责的 `User.java`、`AuthService`、`DataSeeder` 里，**需要他接线**，你负责把设置存起来、读出来。

---

### 第 4 步（第 3 周）：素材库 + 切真数据

#### 4.1 素材库后台

后端：

- 批量上传：`POST /api/admin/materials/batch-upload`
- 分类：`GET/POST/PUT/DELETE /api/admin/material-groups`
- 标签：`GET/POST/PUT/DELETE /api/admin/material-tags`
- 检索：`GET /api/admin/materials?page&pageSize&keyword&groupId&tag&type&startDate&endDate`
- 版本：`GET /api/admin/materials/{id}/versions`
- 批量下载：`POST /api/admin/materials/batch-download`

第一版可以先用 `t_material` 已有的 `group_name` 和 `tags` 字段，不要一上来就把标签树做得很复杂。

#### 4.2 切“大模型配置”和“智能体配置”页

这两页的接口由搭档提供。你把 `USE_MOCK` 关掉，换成真接口。

智能体页是两层：

1. 智能体列表；
2. 点“配置”进入编排详情（基础信息 + Skill 列表 + 计费 + 预览）。

这里的“Skill”是**智能体可调用的工具节点**，不是 App 的 `t_skill` 创作线路。两个东西名字像，含义完全不同，别混。

---

### 第 5 步（第 4~5 周）：调试 / MCP / 知识库 / 运营页 + App 收尾

这些页面的后端主要由搭档提供，你负责：

- 调试页：把执行轨迹渲染出来（每个节点的输入、输出、耗时、算力）
- MCP 页：Server 列表、工具开关、试调用
- 知识库页：文档录入、检索测试
- 数据概览 / 账单 / 算力使用：接聚合接口
- App：Skill 市场页、设置页收尾

调试页有一句要写在页面上：**“调试消耗不扣费”**。

---

### 第 6 步（最后 3 天）：网关 + 打包 + 联调

- 画“网关”页，接对外接口定义。
- 打包 APK。
- App → 后台 → 接口 全链路走一遍。
- 关后门：
  - `opc.security.dev-token-enabled = false`
  - `AppConfig.bypassLogin = false`
- 录演示视频。

---

## 6. 每天怎么干活（小白版流程）

每天照这个顺序，不容易乱：

1. `git pull`：先拿别人的最新代码。
2. 启动后端：`cd server`，`.\mvnw.cmd spring-boot:run`。
3. 打开 `admin-web/index.html`，确认页面没坏。
4. 从今天的任务里挑**一个小点**（比如“只做用户列表接口”）。
5. 改完刷新页面，点一遍，确认没报错。
6. `git status` 看自己改了哪些文件。
7. `git add` + `git commit`，写清楚做了什么。
8. `git push`，在群里说一声。

不要一天改 20 个文件再一起提交，出了问题很难找。

---

## 7. 哪些东西绝对不能碰

这些是“碰了会连累 App”的红线：

1. **不要删 `MockAiProvider`**：答辩出图/出视频靠它。
2. **不要改 `t_skill` 的含义**：它是 App 的创作线路，不是智能体里的 Skill 工具。
3. **不要改坏 `/api/**` 那 22 个 App 接口**：URL、入参、返回字段都不能动。
4. **不要改 `HarnessScheduler` / `TaskStateService`**：任务状态机是好的。
5. **管理端不要用 `mock-token-for-scaffold`**：后台必须用管理员账号真登录。
6. **不要重新设计 `admin-web/` 的 UI**：老师给的原型就是标准，照它做。
7. **不要把“926 万”存进数据库**：数据库存 `9260000`，只在页面上格式化。
8. **不要改别人负责的 `server/` 文件**：你只动 `admin/{user,setting,material}` 和 `PromptController`。

---

## 8. 遇到问题先看哪份文档

| 你想知道 | 打开 |
|---|---|
| 这个接口的字段叫什么 | `docs/api-admin.md` |
| 这个文件归谁改 | `docs/admin-freeze.md` 的 §4.1 |
| 这周该做什么 | `docs/SCHEDULE.md` |
| App 怎么跑、有什么坑 | `docs/HANDOFF.md` |
| Flutter 目录和路由 | `docs/ARCHITECTURE.md` |
| 数据库表长什么样 | `docs/DATABASE.md` + `server/docs/schema.sql` |
| 老师到底要什么 | `_req_doc.txt` |
| 页面长什么样 | `admin-web/index.html` + `admin-web/css/admin.css` |

---

## 9. 你和搭档怎么配合

### 9.1 分工一句话

- **他**：`server/` 主体，负责模型配置、智能体、调试、MCP、知识库、概览/账单/算力、网关。
- **你**：`admin-web/` + `lib/`，外加用户管理、系统设置、素材库后台、`PromptController`。

### 9.2 共写文件怎么处理

| 文件 | 规矩 |
|---|---|
| `server/docs/schema.sql` | 各自只**追加**自己的表，不要改别人的 |
| `common/ErrorCode.java` | 你只用 `6500-6599`（素材）和 `6600-6699`（用户/设置） |
| `docs/api-admin.md` | 改接口先改它，并在“变更记录”加一行 |
| `init/DataSeeder.java` | 拆成 `CoreSeeder`（他）/ `CrudSeeder`（你），别两个人同时改一个文件 |

### 9.3 可以直接发给他的对齐消息

下面这段可以复制到群里：

```text
兄弟，我按 SCHEDULE 走前端线。开工前我们对一下 6 件事：

1. 错误码：素材 6500-6599，用户/设置 6600-6699，按 api-admin 来，对吧？
2. DataSeeder：你改名为 CoreSeeder，我新建 CrudSeeder，避免同时改一个文件。
3. api-admin §⑭ 第 1 步写成了 /api/auth/login，实际是 /api/admin/auth/login，我按后者。
4. 后台登录页原型写 admin@2026，真实是 admin123，我们统一用真密码。
5. /api/prompts 契约还没写，我先提一版列表/详情/收藏，你确认。
6. 组件预览页 /dev/components 不算 13 个业务页面，我不加进 allBusinessPaths。

另外两件依赖你：
- 用户管理加算力要写 t_credit_transaction，我需要一个 CreditTransaction 实体/Repository。
- 设置里的 signupBonusCredits 要接管三处硬编码，那三处在你那边，麻烦你接线。
```

---

## 10. 第一周检查清单

做完一项打个勾：

- [ ] 后端能启动，`/api/health` 返回 200
- [ ] `admin / admin123` 能登录管理端
- [ ] `admin-web/index.html` 能打开
- [ ] Flutter 命令可用，`flutter doctor` 没有大问题
- [ ] 建好自己的分支（比如 `codex/admin-web`）
- [ ] 8 个 Flutter 组件 + 预览页
- [ ] `docs/COMPONENTS.md`
- [ ] `admin-web/js/api.js`
- [ ] `admin-web/js/util.js`
- [ ] 拆完 `admin-web/js/pages/*.js`
- [ ] 真登录 + token + 401 踢回登录页
- [ ] `admin-web/mock/*.json`
- [ ] 侧栏 5 个新入口
- [ ] 12 页能用 mock 点通

---

## 11. 第一周可以先不管的东西

下面这些名词你现在不用啃，等做到对应页面再看：

- `AiProviderConfig` 的字段细节
- `ToolRef` / `ToolSource` / `ToolKind` 的完整设计
- MCP 协议底层
- 向量数据库、embedding
- Spring 事务、JPA 实体关系
- Flutter 路由守卫的内部实现

你只需要知道：**接口返回什么字段，页面怎么显示，按钮点了调哪个接口。**

---

## 12. 一句话总结

> 先把样板间接上真登录，再把 12 个房间点亮；
> App 的积木先做，最后补两个空壳页并打包。

不用一次记住所有东西。照着第 5 节的顺序，一次只做一小步。
