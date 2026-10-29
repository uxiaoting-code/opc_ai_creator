# OPC AI 创作平台 · 后端接口文档

> 本文档由**现有后端代码反向整理**（对照 9 个 Controller、9 个 DTO 与真实运行时的 OpenAPI 输出），
> 字段名、入参、返回结构均与实际接口一致，可直接照此对接。
>
> **用户端 v2 新增的订单、提交、审核、钱包、充值、提现和音频生成接口见
> [`docs/api-user.md`](api-user.md)。** 本文继续维护原有认证、Skill、任务、作品、素材等接口。

---

## 一、通用约定

### 1.1 基础地址

| 运行环境 | Base URL |
|---|---|
| Web / 桌面（后端跑在本机） | `http://localhost:8080` |
| Android 真机 / 模拟器 | `http://<电脑局域网IP>:8080` |
| 线上 | 见 `AppConfig.productionBaseUrl` |

所有业务接口都在 **`/api`** 前缀下。
静态资源（生成的图片 / 视频）在 **`/upload/**`**，不在 `/api` 下。

> 前端拿到的资源地址是**相对路径**（形如 `/upload/task_xxx.png`），
> 显示前必须拼上 host，即 `AppConfig.resolveAssetUrl()`。
> 但**提交给后端的 `refImageUrl` 要保持相对路径**，不要存绝对地址。

### 1.2 统一返回体

**除 401 外，HTTP 状态码一律是 200**，业务成败看 body 里的 `code`。

```json
{
  "code": 200,
  "message": "success",
  "data": { },
  "timestamp": 1789800000000
}
```

| 字段 | 说明 |
|---|---|
| `code` | 业务码。**200 表示成功**，其余见第五节错误码表 |
| `message` | 提示信息，失败时**可直接展示给用户**（后端已写好中文） |
| `data` | 业务数据，可能为 `null`（如删除接口） |
| `timestamp` | 服务端时间戳（毫秒） |

> ⚠️ **唯一的例外是 401**：登录态失效时 HTTP 状态码真的是 401，
> 前端 `AuthInterceptor` 靠它触发「踢回登录页」。其余情况都是 HTTP 200 + 业务码。

### 1.3 鉴权

除以下三个接口外，**都需要带请求头**：

```
Authorization: Bearer <token>
```

不需要登录的接口：`/api/auth/login`、`/api/auth/register`、`/api/health`

**开发期免登录令牌**（由后端 `opc.security.dev-token-enabled` 控制，默认开启）：

```
Authorization: Bearer mock-token-for-scaffold
```

拿它能以演示账号 `demo` 的身份调用全部接口，方便前端在后端还没接通登录时联调。
**交付/上线前后端必须把这个开关关掉。**

### 1.4 分页

**注意：项目里有两套分页结构，不一样！**

| 接口 | 分页结构 | 取列表的字段 |
|---|---|---|
| `GET /api/tasks` | 项目自定义 `PageResult` | **`data.list`** |
| `GET /api/materials/my` | Spring Data `Page` 原样返回 | **`data.content`** |

```json
// GET /api/tasks 的 data
{ "list": [ ... ], "page": 1, "pageSize": 10, "total": 42 }

// GET /api/materials/my 的 data
{ "content": [ ... ], "totalElements": 42, "number": 0, "size": 10 }
```

这是实现时留下的不一致，前端解析时**必须按上表区分**，别照一个写。

---

## 二、认证 `/api/auth`

### 2.1 登录

```
POST /api/auth/login        无需鉴权
```

**请求体**

```json
{ "username": "demo", "password": "demo123" }
```

| 字段 | 类型 | 必填 | 校验 |
|---|---|---|---|
| `username` | string | ✅ | 4–20 位 |
| `password` | string | ✅ | 至少 6 位 |

**返回 `data`（AuthResponse）**

```json
{
  "token": "3f2a...e91",
  "user": {
    "id": 1,
    "username": "demo",
    "nickname": "课设演示账号",
    "avatar": null,
    "email": null,
    "phone": null,
    "role": "USER",
    "credits": 10000,
    "createdAt": "2026-01-01T00:00:00"
  }
}
```

**常见失败**：`1003` 账号或密码错误、`1004` 账号已被禁用。

### 2.2 注册

```
POST /api/auth/register     无需鉴权
```

**请求体**

```json
{ "username": "newuser", "password": "123456", "nickname": "昵称", "email": "a@b.com" }
```

`nickname`、`email` 可省略。注册成功后**直接返回 token**，前端不需要再调一次登录。

> **新用户初始算力点：10000**（见第 4.3 节）。给得宽裕是故意的 ——
> 文生图一次 10 点、图生视频一次 15 点，演示环境初始值太小会跑到一半
> 卡在「算力点不足」，反而看不到完整链路。

**常见失败**：`1001` 该账号已被注册。

### 2.3 退出登录

```
POST /api/auth/logout
```

无请求体。返回 `data: null`。

### 2.4 当前用户资料

```
GET /api/auth/profile
```

**返回 `data`**：同上的 `user` 对象（含**真实算力点** `credits`）。

> 首页右上角的算力点、个人中心的数据都走这个接口。

---

## 三、Skill 创作线路 `/api/skills`

### 3.1 线路列表

```
GET /api/skills
```

**Query**

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `type` | string | ❌ | `TEXT_TO_IMAGE` / `IMAGE_TO_VIDEO`，不传=全部 |
| `limit` | int | ❌ | 首页只要前几条；市场页不传=全部 |

**返回 `data`**：数组（**不是分页结构**）

```json
[
  {
    "id": 1,
    "code": "anime_v1",
    "name": "二次元插画",
    "type": "TEXT_TO_IMAGE",
    "typeLabel": "文生图",
    "coverUrl": null,
    "description": "日系赛璐璐画风，线条干净、色彩通透…",
    "scene": "头像 / 立绘 / 同人",
    "provider": "mock",
    "modelName": "sd-xl-anime",
    "sampler": "DPM++ 2M Karras",
    "steps": 28,
    "cfgScale": 7.5,
    "width": 1024,
    "height": 1024,
    "promptPrefix": "masterpiece, best quality, anime style, cel shading",
    "promptSuffix": null,
    "negativePrompt": "lowres, bad anatomy, extra fingers, watermark",
    "usageCount": 12842,
    "favoriteCount": 326,
    "status": 1
  }
]
```

> 数据来自 `t_skill`，初始化时写入 6 条：`anime_v1`、`realistic_v1`、`ecommerce_v1`、`guofeng_v1`（文生图）、`motion_v1`、`anime_motion_v1`（图生视频）。

### 3.2 线路详情

```
GET /api/skills/{id}
```

返回单个 `SkillResponse`。**失败**：`2001` 创作线路不存在。

---

## 四、创作 `/api/creation`

两个接口的**入参结构完全一样**，只是任务类型不同（由路径决定，body 里**没有 type 字段**）。

> **重要**：接口**立即返回一个「排队中」的任务**，不会阻塞等生成完成。
> 前端拿到 `task.id` 后跳任务详情页轮询进度。

### 4.1 文生图

```
POST /api/creation/text-to-image
```

### 4.2 图生视频

```
POST /api/creation/image-to-video
```

**请求体（两者相同）**

```json
{
  "skillId": 1,
  "prompt": "雨夜霓虹街道，赛博朋克风格",
  "negativePrompt": "低分辨率、水印",
  "refImageUrl": null
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `skillId` | long | ❌ | 线路 ID，不传用默认参数 |
| `prompt` | string | 文生图必填 | ≤ 2000 字 |
| `negativePrompt` | string | ❌ | ≤ 1000 字 |
| `refImageUrl` | string | **图生视频必填** | 首帧图地址，用素材上传接口拿到的相对路径 |

**返回 `data`**：`TaskResponse`（见 5.3）

```json
{
  "id": 12,
  "taskNo": "5a05202a284444ff9afb328db216c0f3",
  "type": "TEXT_TO_IMAGE",
  "typeLabel": "文生图",
  "status": "QUEUED",
  "statusLabel": "排队中",
  "progress": 0,
  "finished": false,
  "canRetry": false,
  "canCancel": true,
  "queueAt": "2026-09-21T10:00:00",
  "createdAt": "2026-09-21T10:00:00"
}
```

**常见失败**

| code | 场景 |
|---|---|
| `400` | 提示词为空 / 图生视频没传 `refImageUrl` |
| `400` | **算力点不足**：`本次生成需要 15 点，当前剩余 0 点` |
| `2001` / `2002` | 线路不存在 / 已下线 |
| `400` | 线路类型与任务不匹配（拿图生视频线路做文生图） |

### 4.3 算力点

| 项 | 值 |
|---|---|
| **新用户初始算力点** | **10000** |
| 文生图每次消耗 | **10 点** |
| 图生视频每次消耗 | **15 点** |
| 扣减时机 | **创建任务时立即扣**，不是等生成完成 |

算力点不足时创建任务返回业务码 `400`，`message` 形如
`算力点不足，本次生成需要 15 点，当前剩余 0 点`，可直接展示给用户。

生成失败会退还吗？**不会** —— 当前实现扣了就是扣了。
失败的任务可以走 `POST /api/tasks/{id}/retry` 重试，**重试不再额外扣费**。

> 对应的后端配置：单价看 `opc.harness.credits-per-task` /
> `credits-per-video-task`（`application.yml`）；
> 初始值看 `AuthService.INITIAL_CREDITS`。
>
> **注意有三处定义初始值，改动时要一起改，否则走不同路径创建的用户初始算力点会不一致：**
> `AuthService.INITIAL_CREDITS`（注册流程实际用的）、
> `User` 实体的字段默认值（构造时兜底）、
> `docs/schema.sql` 里 `t_user.credits` 的建表默认值（直接 INSERT 时兜底）。

---

## 五、任务 `/api/tasks`

### 5.1 任务列表

```
GET /api/tasks
```

**Query**

| 参数 | 默认 | 说明 |
|---|---|---|
| `status` | 不传=全部 | `QUEUED` / `RUNNING` / `SUCCESS` / `FAILED` / `CANCELED` |
| `page` | 1 | **从 1 开始** |
| `pageSize` | 10 | |

**返回 `data`**：`PageResult`（注意是 **`list`**）

```json
{
  "list": [ { "id": 12, "taskNo": "...", "status": "SUCCESS", "resultUrl": "/upload/task_xxx.png", "...": "" } ],
  "page": 1,
  "pageSize": 10,
  "total": 42
}
```

### 5.2 各状态任务数量

```
GET /api/tasks/stats
```

**返回 `data`**：`Map<状态名, 数量>`。**数量为 0 的状态不会出现在 map 里**，取值一律 `?? 0`。

```json
{ "SUCCESS": 12, "FAILED": 2, "QUEUED": 1 }
```

> 个人中心的「数据统计」用它。

### 5.3 任务详情（轮询用）

```
GET /api/tasks/{id}
```

**返回 `data`**：`TaskResponse`

```json
{
  "id": 12,
  "taskNo": "5a05202a...",
  "type": "IMAGE_TO_VIDEO",
  "typeLabel": "图生视频",
  "skillId": 5,
  "skillName": "短视频运镜",
  "skillCode": "motion_v1",

  "prompt": "镜头缓慢推进…",
  "negativePrompt": "画面抖动",
  "refImageUrl": "/upload/material_xxx.png",

  "status": "SUCCESS",
  "statusLabel": "成功",
  "progress": 100,

  "resultUrl": "/upload/task_xxx.mp4",
  "resultThumb": "/upload/cover_xxx.png",
  "errorMsg": null,

  "provider": "mock",
  "providerTaskId": null,

  "retryCount": 0,
  "maxRetry": 3,
  "canRetry": false,
  "canCancel": false,
  "finished": true,

  "queueAt": "2026-09-21T10:00:00",
  "startAt": "2026-09-21T10:00:03",
  "finishAt": "2026-09-21T10:00:09",
  "durationMs": 6000,
  "createdAt": "2026-09-21T10:00:00"
}
```

**给前端的三个要点**

1. **`finished` 决定要不要继续轮询** —— 别自己判断状态，用后端给的。
2. **`canRetry` / `canCancel` 决定按钮能不能点** —— 状态机规则只有后端一份。
3. **`resultUrl` 是相对路径**，展示前要拼 host；
   图生视频返回的是 **`.mp4`**，要用视频播放器渲染，不能当图片加载。

**失败**：`3001` 任务不存在（或不属于当前用户）。

### 5.4 失败重试

```
POST /api/tasks/{id}/retry
```

无请求体。返回更新后的 `TaskResponse`（状态回到 `QUEUED`）。

**失败**：`3002` 当前状态不允许该操作（只有 FAILED 能重试）、`3003` 重试次数已用尽。

### 5.5 取消任务

```
POST /api/tasks/{id}/cancel
```

无请求体。**只有 `QUEUED` 可以取消**，否则 `3002`。

---

## 六、作品 `/api/works`

> 作品由后端在**任务成功时自动创建**一条，没有「创建作品」接口。

### 6.1 作品列表

```
GET /api/works
```

**Query**

| 参数 | 默认 | 说明 |
|---|---|---|
| `page` | 1 | |
| `pageSize` | 20 | |
| `limit` | ❌ | 首页只要最近几条时用它，优先于 pageSize |
| `scope` | ❌ | 传 `public` 返回**公开画廊**（所有人可见的作品） |

**返回 `data`**：数组（**不是分页结构**）

```json
[
  {
    "id": 3,
    "userId": 1,
    "taskId": 12,
    "title": "雨夜霓虹街道",
    "type": "VIDEO",
    "coverUrl": "/upload/cover_xxx.png",
    "resourceUrl": "/upload/task_xxx.mp4",
    "prompt": "雨夜霓虹街道，赛博朋克风格",
    "negativePrompt": "低分辨率",
    "skillId": 1,
    "skillName": "二次元插画",
    "width": null,
    "height": null,
    "duration": null,
    "isPublic": false,
    "likeCount": 0,
    "viewCount": 0,
    "createdAt": "2026-09-21T10:00:09"
  }
]
```

**给前端的要点**

- `type` 为 `IMAGE` / `VIDEO`，**决定用图片还是视频播放器渲染**。
- `coverUrl` 可能为 `null`（视频有封面，图片一般没有）→ 回退用 `resourceUrl`。
- `resourceUrl` 是**相对路径**，展示前拼 host。
- **`width` / `height` 目前后端没有回填，恒为 `null`** —— 瀑布流如果依赖真实宽高比，
  需要在前端用一个由 id 决定的稳定伪随机比例兜底（否则每次刷新高度会乱跳）。

### 6.2 作品详情

```
GET /api/works/{id}
```

返回单个 `WorkResponse`。**失败**：`5001` 作品不存在。

### 6.3 发布 / 取消发布

```
POST /api/works/{id}/publish?isPublic=true
```

Query 参数 `isPublic`，默认 `true`。返回更新后的 `WorkResponse`。

---

## 七、素材 `/api/materials`

### 7.1 上传素材

```
POST /api/materials/upload      Content-Type: multipart/form-data
```

| 表单字段 | 说明 |
|---|---|
| `file` | 图片文件。**只接受 `image/*`**，≤ 10MB |

**返回 `data`（MaterialResponse）**

```json
{
  "id": 7,
  "name": "ref.jpg",
  "url": "/upload/material_1758_ab12cd34.jpg",
  "thumbUrl": null,
  "fileSize": 182734,
  "mimeType": "image/jpeg",
  "width": null,
  "height": null,
  "source": "UPLOAD",
  "createdAt": "2026-09-21T10:00:00"
}
```

> 拿到 `url` 后**原样**填进创作接口的 `refImageUrl`，**不要**拼成绝对地址。

**失败**：`4001` 文件为空、`4002` 不是图片、`4003` 超过 10MB。

**Web 端注意**：Flutter Web 上 `XFile.path` 是 `blob:` 开头的临时地址，后端拿不到。
必须用 `await file.readAsBytes()` 拿字节流走 multipart（项目的 `ApiClient.uploadBytes` 已经这么做了）。

### 7.2 我的素材（分页）

```
GET /api/materials/my
```

**Query**：`page`（**从 0 开始**）、`size`（默认 10）

> ⚠️ 这里的 `page` **从 0 开始**，和 `/api/tasks` 的从 1 开始不一样。

**返回 `data`**：**Spring Data Page 原样结构**（取 `content`，不是 `list`）

```json
{ "content": [ { "id": 7, "url": "/upload/material_xxx.jpg", "...": "" } ],
  "totalElements": 3, "number": 0, "size": 10 }
```

### 7.3 删除素材

```
DELETE /api/materials/{id}
```

逻辑删除。返回 `data: null`。**失败**：`404` 素材不存在或无权限。

---

## 八、消息 `/api/notifications`

> 消息由最近的任务**动态派生**，不是独立的表。

### 8.1 消息列表

```
GET /api/notifications?limit=20
```

**返回 `data`**：数组

```json
[
  {
    "id": 12,
    "title": "生成成功",
    "content": "你的作品《雨夜霓虹街道》已生成完成",
    "type": "TASK",
    "isRead": false,
    "createdAt": "2026-09-21T10:00:09"
  }
]
```

### 8.2 未读数

```
GET /api/notifications/unread
```

**返回 `data`**：一个整数，如 `3`。首页红点用它。

---

## 九、Prompt 知识库 `/api/prompts`

所有 Prompt 接口都需要登录。

### 9.1 Prompt 列表

```
GET /api/prompts?category=电商&keyword=主图&page=1&pageSize=12
```

| 参数 | 必填 | 说明 |
|---|---|---|
| `category` | 否 | 分类精确匹配；为空表示全部 |
| `keyword` | 否 | 同时匹配标题、正文和标签 |
| `page` | 否 | 从 1 开始，默认 1 |
| `pageSize` | 否 | 默认 12，最大 50 |

**返回 `data`**：统一分页结构，元素字段如下：

```json
{
  "list": [
    {
      "id": 1,
      "userId": null,
      "title": "极简商品主图",
      "content": "product photography, single object, pastel background",
      "negativeContent": "cluttered, text, watermark",
      "category": "电商",
      "tags": "电商,产品,极简",
      "coverUrl": null,
      "favoriteCount": 94,
      "useCount": 312,
      "isPublic": true,
      "favorited": false,
      "createdAt": "2026-10-19T10:12:00"
    }
  ],
  "page": 1,
  "pageSize": 12,
  "total": 1
}
```

### 9.2 保存自定义 Prompt

```
POST /api/prompts
```

```json
{
  "title": "我的商品主图",
  "content": "白色背景，柔和棚拍光，商品居中",
  "negativeContent": "文字，水印，低清晰度",
  "category": "电商",
  "tags": "商品,主图,极简",
  "coverUrl": null
}
```

标题和正文必填；标题最多 100 字，正文最多 4000 字，反向提示词最多 2000 字。

### 9.3 收藏 / 取消收藏

```
POST /api/prompts/{id}/favorite
```

同一接口切换收藏状态。**返回 `data`**

```json
{
  "promptId": 1,
  "favorited": true,
  "favoriteCount": 95
}
```

---

## 十、健康检查 `/api/health`

```
GET /api/health      无需鉴权
```

**返回 `data`**

```json
{
  "status": "UP",
  "service": "opc-server",
  "providers": ["mock"],
  "pollIntervalMs": 3000,
  "batchSize": 5,
  "maxConcurrentTasks": 4,
  "creditsPerTask": 10,
  "timestamp": 1789800000000
}
```

> 手机连不上后端时，先在浏览器打开 `http://<局域网IP>:8080/api/health` ——
> 这一条能立刻区分「网络/防火墙问题」和「登录/业务问题」。

---

## 十一、枚举字典

| 枚举 | 取值 | 中文 |
|---|---|---|
| **TaskStatus** | `QUEUED` | 排队中 |
| | `RUNNING` | 生成中 |
| | `SUCCESS` | 成功 |
| | `FAILED` | 失败 |
| | `CANCELED` | 已取消 |
| **TaskType** | `TEXT_TO_IMAGE` | 文生图 |
| | `IMAGE_TO_VIDEO` | 图生视频 |
| **WorkType** | `IMAGE` | 图片 |
| | `VIDEO` | 视频 |
| **SkillType** | `TEXT_TO_IMAGE` / `IMAGE_TO_VIDEO` | 同上 |

> 终态 = `SUCCESS` / `FAILED` / `CANCELED`。后端在 `TaskResponse.finished` 里已经算好。

---

## 十二、错误码表

| code | message | 说明 |
|---|---|---|
| 200 | success | 成功 |
| 400 | 请求参数有误 | 参数校验失败，message 里有具体原因 |
| 401 | 登录已过期，请重新登录 | **HTTP 状态码也是 401** |
| 403 | 没有权限执行该操作 | |
| 404 | 请求的资源不存在 | |
| 500 | 服务器开小差了，请稍后重试 | 未预期异常，需要看后端日志 |
| 1001 | 该账号已被注册 | |
| 1002 | 用户不存在 | |
| 1003 | 账号或密码错误 | |
| 1004 | 账号已被禁用 | |
| 2001 | 创作线路不存在 | |
| 2002 | 该创作线路已下线 | |
| 3001 | 任务不存在 | |
| 3002 | 当前任务状态下不允许该操作 | |
| 3003 | 重试次数已用尽 | |
| 3004 | 没有可用的 AI 服务商 | |
| 4001 | 上传文件为空 | |
| 4002 | 不支持的文件类型 | |
| 4003 | 文件体积超出限制 | |
| 4004 | 文件保存失败 | |
| 5001 | 作品不存在 | |
| 6501 | Prompt 不存在 | |
| 6502 | Prompt 标题不合法 | |
| 6503 | Prompt 内容不合法 | |
| 6504 | Prompt 参数不合法 | |

---

## 十三、快速自测（curl）

```bash
# 1. 健康检查（不需要 token）
curl http://localhost:8080/api/health

# 2. 登录拿 token
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"demo123"}'

# 3. 或者直接用开发令牌，跳过登录
T="mock-token-for-scaffold"

# 4. 线路列表
curl -H "Authorization: Bearer $T" "http://localhost:8080/api/skills?type=TEXT_TO_IMAGE"

# 5. 建一个文生图任务
curl -X POST http://localhost:8080/api/creation/text-to-image \
  -H "Authorization: Bearer $T" -H "Content-Type: application/json" \
  -d '{"skillId":1,"prompt":"雨夜霓虹街道，赛博朋克风格"}'

# 6. 轮询任务（等 3~10 秒，状态会 QUEUED → RUNNING → SUCCESS）
curl -H "Authorization: Bearer $T" http://localhost:8080/api/tasks/1

# 7. 任务列表
curl -H "Authorization: Bearer $T" "http://localhost:8080/api/tasks?page=1&pageSize=10"

# 8. 作品列表
curl -H "Authorization: Bearer $T" "http://localhost:8080/api/works"

# 9. Prompt 列表
curl -H "Authorization: Bearer $T" "http://localhost:8080/api/prompts?page=1&pageSize=12"

# 10. 保存自定义 Prompt
curl -X POST http://localhost:8080/api/prompts \
  -H "Authorization: Bearer $T" -H "Content-Type: application/json" \
  -d '{"title":"我的商品主图","content":"白色背景，柔和棚拍光，商品居中","category":"电商","tags":"商品,主图"}'

# 11. 切换收藏状态
curl -X POST http://localhost:8080/api/prompts/1/favorite \
  -H "Authorization: Bearer $T"
```

---

## 十四、关于 Mock

后端**不调用任何真实 AI 服务**，`MockAiProvider` 是纯本地实现：

- **文生图**：用 Java2D 画一张带提示词的渐变图（配色由提示词哈希决定，同一提示词结果稳定），
  存成 PNG。画面上会带 `MOCK 模拟生成 · 非真实模型输出` 水印。
- **图生视频**：逐帧画动画，用 JCodec 编码成**真的能播的 H.264 MP4**（640×360、15fps、3 秒），
  第一帧另存为 PNG 当封面。

**可复现的失败**：提示词里带 `#fail` 时，任务**首次必失败、重试必成功** ——
用来演示 Harness 的失败重试闭环。

生成耗时被刻意拉长到 2~6 秒，好让「排队 → 生成中 → 成功」的状态流转肉眼可见。
这两项分别由 `opc.mock.min-delay-ms` / `max-delay-ms` 和 `opc.harness.poll-interval-ms` 控制。

---

## 十五、变更记录

- 2026-10-26：新增 Prompt 列表、自定义保存、收藏切换接口（6500-6599 错误码段）。
