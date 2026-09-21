# 交接说明 · 前后端进度与约定

> 面向接手前端剩余工作的同学。写于 2026-09-21，基于当时的真实代码状态。

---

## 一、一句话现状

**后端已经完整可用**（22 个接口全部实现并跑通），**前端 13 个页面里 11 个已完成**，
剩下 **Prompt 知识库**、**Skill 市场** 两个整页，以及**设置页的剩余部分**。

---

## 二、后端

### 2.1 技术栈

| 项 | 内容 |
|---|---|
| 框架 | Spring Boot **4.1.1** + Java 21 |
| 持久层 | **Spring Data JPA**（不是 MyBatis） |
| 数据库 | 默认 H2（文件模式，开箱即跑）；`--spring.profiles.active=mysql` 切 MySQL |
| 接口文档 | Knife4j（`/doc.html`），启动后可直接在页面上调试 |
| AI 服务商 | `MockAiProvider`（纯本地，**不调用任何外部 API**） |

### 2.2 已实现

- **认证**：登录 / 注册 / 登出 / 用户资料，PBKDF2 密码哈希，令牌鉴权
- **算力点**：新用户初始 **10000**；创建任务时扣减（文生图 10 点、图生视频 15 点），
  重试不再额外扣费。初始值有**三处**定义，改的时候要一起改（详见 [api.md](./api.md) 第 4.3 节）
- **Harness 任务调度**：`QUEUED → RUNNING → SUCCESS/FAILED` 全自动流转，
  支持失败重试、取消、超时清理、重启后重置卡住的任务
- **Mock 生成**：文生图出 PNG；图生视频**真编码出一段能播的 H.264 MP4**
- **作品**：任务成功时自动落作品记录，支持发布到公开画廊
- **素材**：上传 / 分页查询 / 逻辑删除
- **消息**：由最近任务动态派生
- **全局**：统一返回体、全局异常处理、CORS、开发令牌免登录

接口细节见 **[api.md](./api.md)**（22 个接口的 URL / 入参 / 返回 / 错误码都在里面）。

---

## 三、前端页面状态

13 个业务页面 + 1 个素材选择页：

| # | 页面 | 路由 | 状态 | 文件行数 |
|---|---|---|---|---|
| 1 | 登录 / 注册 | `/login` | ✅ 完成 | 455 |
| 2 | 首页 | `/home` | ✅ 完成 | 466 |
| 3 | 文生图创作 | `/create/text-to-image` | ✅ 完成 | 592 |
| 4 | 图生视频创作 | `/create/image-to-video` | ✅ 完成 | 1034 |
| 5 | 任务列表 | `/tasks` | ✅ 完成 | 692 |
| 6 | 作品画廊 | `/gallery` | ✅ 完成 | 620 |
| 7 | 素材库 | `/materials` | ✅ 完成 | 353 |
| 8 | **Prompt 知识库** | `/prompts` | ❌ **占位页** | 33 |
| 9 | **Skill 市场** | `/skills` | ❌ **占位页** | 32 |
| 10 | 作品详情 | `/gallery/:workId` | ✅ 完成 | 619 |
| 11 | 个人中心 | `/profile` | ✅ 完成 | 491 |
| 12 | **设置** | `/settings` | ⚠️ **部分** | 275 |
| 13 | 任务详情 | `/tasks/:taskId` | ✅ 完成 | 1100 |
| + | 素材选择（选择器模式） | `/select-material` | ✅ 完成 | 复用 7 |

「完成」= 有真实数据、真实交互、loading / 空 / 错误三态齐全。

---

## 四、剩下要做的

### 4.1 Prompt 知识库（页面 8）—— ⚠️ 需要先补后端

**这是唯一一个后端还没做的模块。** 现状：

- 表 `t_prompt`、`t_prompt_favorite` **已建好**，实体 `Prompt` / `PromptFavorite`
  和 `PromptRepository` / `PromptFavoriteRepository` **也已写好**
- **但没有 `PromptController`** —— `GET /api/prompts` 目前是 404

所以顺序是：**先在 `server/` 加一个 `PromptController`**（照 `SkillController` 抄，
查询接口返回 `List<PromptResponse>` 即可），再做前端页面。

前端已有现成的东西可以复用：`ApiEndpoints.prompts`、`ApiEndpoints.promptFavorite(id)`、
`SkillRepository` 的写法（Repository → Provider → 页面）。

### 4.2 Skill 市场（页面 9）—— 后端已就绪，可直接做

`GET /api/skills`（支持 `type` / `limit`）和 `GET /api/skills/{id}` **都能用**。

数据已经有了：6 条线路（`anime_v1`、`realistic_v1`、`ecommerce_v1`、`guofeng_v1`、`motion_v1`、`anime_motion_v1`）。

注意：`SkillProvider` 已经是全局的，首页横滑列表和创作页的下拉都在用它 ——
市场页**直接复用同一个 Provider**，不要另起一份数据。

### 4.3 设置页（页面 12）—— 补剩余区块

已实现：**外观（主题切换）**、**环境信息（调试用）**。

页面下半部分还有一个自己写的 **「待实现」区块**（5 条 TODO：默认生成参数、缓存管理、
通知设置、账号安全、关于）。这些都需要新后端支持，不在当前后端范围内 ——
**交接前建议把这个区块删掉**，或者明确保留为路线图。

> 顺带说明：`SettingsPage` 仍然用 `ScaffoldPage` 当外壳，但因为它传了 `body`，
> 外壳自带的 `plannedFeatures` 占位内容**不会被渲染**，屏幕上看到的是自定义内容。
> 如果之后想彻底脱离脚手架外壳，把 `ScaffoldPage` 换成普通 `Scaffold` + `AppBar` 即可。

---

## 五、交接须知：约定与踩过的坑

> 这一节是给你省时间的。下面每一条都是**实际踩过的**，不是理论。

### 5.1 网络层：一律复用 `ApiClient` / Repository，**不要自己 `new Dio()`**

项目里已经有一个全局 `ApiClient`（`lib/core/network/api_client.dart`），它负责：

- 拼 `baseUrl`（Web 用 `localhost`、Android 用局域网 IP，自动切换）
- **自动注入 `Authorization` 头**
- 把后端错误统一翻译成 `ApiException`（`message` 可以直接上屏）

自己 `Dio()` 会同时丢掉 baseUrl 和 token —— 表现是「请求发不出去 / 401，页面一片空白」。
素材库页早期就是这么写的，排查了很久。

**分层约定**：页面 → `XxxProvider` / `XxxRepository` → `ApiClient`。

### 5.2 图片地址：**显示要拼绝对路径，提交要保持相对路径**

后端返回的是 `/upload/xxx.png` 这种相对路径。

| 场景 | 做法 |
|---|---|
| 显示（`Image.network` / `AppNetworkImage`） | `AppConfig.resolveAssetUrl(url)` |
| 提交给后端（如 `refImageUrl`） | **原样传相对路径** |

如果把拼好的绝对地址存进数据库，会写进 `http://localhost:8080/...` 这种本机地址，换台机器就废了。

### 5.3 路由：`go` 和 `push` 用错会红屏

项目用 `StatefulShellRoute`（5 个底部 Tab，各自独立导航栈）：

| 场景 | 用哪个 |
|---|---|
| 切底部 Tab / **跨分支**跳转 | `context.go(...)` |
| 进**当前所在分支的子路由**（如画廊 → `/gallery/:id`） | **`context.push(...)`** |
| 顶层路由（`/prompts` `/skills` `/settings`） | `context.push(...)` |

**踩过的坑**：在画廊列表上 `go('/gallery/12')` 会触发
`Assertion failed: !keyReservation.contains(key)` → 红屏。
原因是对「当前分支路径的子路径」用 `go`，路由匹配表里会出现重复匹配项。

### 5.4 含图标的按钮**不要放进 `Row`**

`OutlinedButton.icon` / `TextButton.icon` 内部有一个带 `Flexible` 的 Row，
放进外层 `Row` 会拿到**无限宽约束**，直接崩：

```
BoxConstraints forces an infinite width
```

**用 `Wrap` 代替 `Row`**（顺手还能在窄屏自动折行）。
纯文字的 `TextButton`（不带 `.icon`）没有这个问题。

### 5.5 分页有两套结构，别照一个写

| 接口 | 取列表的字段 |
|---|---|
| `GET /api/tasks` | `data.**list**` |
| `GET /api/materials/my` | `data.**content**`（Spring Data Page 原样返回） |

另外 `/api/tasks` 的 `page` **从 1 开始**，`/api/materials/my` 的 `page` **从 0 开始**。

### 5.6 任务轮询：用后端给的 `finished`，别自己判断状态

`TaskResponse` 里有三个派生字段，是后端算好的，前端直接用：

- `finished` —— 决定要不要停轮询
- `canRetry` / `canCancel` —— 决定按钮能不能点
- `statusLabel` —— 状态中文名

自己在前端再实现一套状态机规则，迟早和后端不一致。

### 5.7 已知问题（未修，交接后按需处理）

| 问题 | 影响 | 备注 |
|---|---|---|
| `WorkResponse.width/height` 恒为 `null` | 瀑布流拿不到真实宽高比 | 画廊页已用「由 id 决定的稳定伪随机比例」兜底，但要按真实比例排版得后端补 |
| `WorkResponse.duration` 恒为 `null` | 视频卡片不显示时长角标 | 数据其实存在任务的 `resultJson` 里，没往作品表同步 |
| 创建任务接口曾偶发一次 500 | 未能复现 | 当时禁止连数据库，没继续查。如果复现，看后端日志的 `未预期的异常` 堆栈 |
| `lib/pages/material/material_library_page.dart` | **死代码** | 素材库路由已指向 `material_gallery_page.dart`，这个旧占位页没人引用了，可删 |
| `opc.security.dev-token-enabled: true` | **安全** | 交付前必须改成 `false`，否则任何人拿 `mock-token-for-scaffold` 就能以 demo 身份调所有接口 |

---

## 六、启动与联调

### 6.1 启动后端

```bash
cd server

# 方式一：H2 文件库，开箱即跑，不需要装数据库
./mvnw spring-boot:run

# 方式二：MySQL（需先建库建表：mysql> source server/docs/schema.sql）
./mvnw spring-boot:run -Dspring-boot.run.profiles=mysql
```

启动后：

- 接口文档 <http://localhost:8080/doc.html> （可以直接在页面上发请求）
- 健康检查 <http://localhost:8080/api/health>

首次启动会自动初始化：demo / admin 账号、6 条 Skill 线路、5 条 Prompt 数据。

### 6.2 启动前端

```bash
cd ..            # 回到项目根
flutter pub get
flutter run -d chrome
```

后端地址由 `lib/core/config/app_config.dart` 的 `AppConfig.env` 决定
（Web 默认 `localhost:8080`，Android 自动切局域网 IP）。

### 6.3 免登录联调

后端开发令牌默认开启，前端 `AppConfig.bypassLogin` 也为 `true` ——
**登录页点一下就能进，不需要真的调登录接口**，令牌是固定的
`mock-token-for-scaffold`，后端会把它映射成演示账号 demo。

这条链路能跑通，是因为两端配置对齐。**交付前后端要关掉 `dev-token-enabled`，
这条捷径就会失效（这是预期的）。**

### 6.4 Postman 测试顺序

按这个顺序打，前一个的产物给后一个用：

1. `GET  /api/health` —— 确认服务活着（不需要 token）
2. `POST /api/auth/login`，body `{"username":"demo","password":"demo123"}` —— 拿 `data.token`
3. 之后所有请求加头 `Authorization: Bearer <token>`；
   或者偷懒直接用 `Bearer mock-token-for-scaffold`
4. `GET  /api/skills?type=TEXT_TO_IMAGE` —— 看线路列表
5. `POST /api/creation/text-to-image`，body `{"skillId":1,"prompt":"雨夜霓虹街道"}`
   —— 拿到 `data.id`（这就是 taskId）
6. `GET  /api/tasks/{id}` —— 隔 3 秒刷一次，看状态
   `QUEUED → RUNNING → SUCCESS`，成功后 `resultUrl` 就是图片地址
7. `POST /api/materials/upload` —— form-data 里放 `file`，拿回 `data.url`
8. `POST /api/creation/image-to-video`，
   body `{"skillId":5,"prompt":"镜头缓慢推进","refImageUrl":"<上一步的 url>"}`
9. `GET  /api/tasks/{id}` —— 轮询，成功后 `resultUrl` 是 `.mp4`，丢浏览器能播
10. `GET  /api/tasks?page=1&pageSize=10` —— 任务列表
11. `GET  /api/tasks/stats` —— 各状态数量
12. `GET  /api/works` —— 作品列表（任务成功会自动落一条）
13. `POST /api/tasks/{id}/retry` —— 对失败任务重试
14. `POST /api/tasks/{id}/cancel` —— 对排队中任务取消

**演示失败重试**：提示词里带上 `#fail`，任务首次必失败、重试必成功。

---

## 七、两个文档的分工

| 文档 | 内容 |
|---|---|
| **[api.md](./api.md)** | 22 个接口的完整契约：URL、方法、入参、返回 JSON、错误码、枚举字典 |
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | 后端整体架构设计（Harness 调度、AiProvider 抽象等） |
| **[DATABASE.md](./DATABASE.md)** | 7 张表的字段设计 |
| **本文** | 进度盘点 + 交接须知 + 启动/测试步骤 |
