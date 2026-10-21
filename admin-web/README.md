# 管理端 Web P0 说明

## 怎么打开

用 VS Code 的 **Live Server** 打开 `admin-web/index.html`。

不要直接双击 `index.html`，因为 `mock/*.json` 需要 HTTP 服务才能被 `fetch` 读取。

## 登录

- **Mock 模式（默认）**：任意账号密码都能进，页面用 `mock/*.json` 的数据。
- **真登录**：地址后面加 `?mock=0`，例如
  `http://127.0.0.1:5500/index.html?mock=0`
  这时会调 `POST /api/admin/auth/login`，账号 `admin / admin123`。

Mock 开关在 `js/api.js` 里：

```js
const USE_MOCK = ... // 默认 true
```

## 文件结构

```text
admin-web/
├── index.html              # 页面结构（12 页）
├── css/admin.css           # 原型样式
├── js/
│   ├── util.js             # $ / $$ / toast / formatCredits / 日期 / 转义
│   ├── api.js              # baseURL / token / 统一错误 / mock
│   ├── app.js              # 登录、导航、弹窗、页面模块调度
│   └── pages/
│       ├── dash.js
│       ├── users.js
│       ├── bills.js
│       ├── models.js
│       ├── agents.js
│       ├── usage.js
│       ├── settings.js
│       ├── debug.js
│       ├── mcp.js
│       ├── kb.js
│       ├── materials.js
│       └── gateway.js
└── mock/                   # 字段照 docs/api-admin.md
```

> 旧的 `js/admin.js` 已不再被 `index.html` 加载，保留作对照；
> 新逻辑在 `js/app.js` + `js/pages/*.js` 里。确认稳定后可以删掉旧文件。

## 加一个新页面

1. 在 `index.html` 侧栏加一个 `<button class="anv" data-pg="xxx">`。
2. 在 `.adm-main` 里加一个 `<section class="page hidden" id="pg-xxx">`。
3. 在 `js/pages/xxx.js` 里注册：

```js
global.AdminPages.xxx = {
  init() { /* 只绑定一次事件 */ },
  load() { /* 每次进入页面时拉数据/渲染 */ },
};
```

4. 在 `index.html` 底部加 `<script src="js/pages/xxx.js"></script>`。

## 约定

- 不要直接写 `fetch`，统一走 `AdminApi`。
- 数字显示统一走 `AdminUtil.formatCredits`。
- 接口字段以 `docs/api-admin.md` 为准。
- 401 由 `api.js` 统一清 token 并广播 `admin:unauthorized`。
