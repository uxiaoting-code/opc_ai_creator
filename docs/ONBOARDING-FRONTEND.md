# 前端线 · 上手与开工指南

> 面向对象：**前端线搭档**
> 最后更新：2026-10-17
> 对应代码版本：`9d82740`（P0 后端已完成并推送）
> 配套文档：`AGENTS.md`、`docs/SCHEDULE.md`、`docs/api-admin.md`、`docs/admin-freeze.md`
> Git 基础：`docs/GIT-BASICS.md`（clone / pull / commit / push 是什么意思）

---

## 0. 先明确你的范围

| 你负责 | 你不碰 |
|---|---|
| `web/`（老师给的后台原型） | `server/` 主体（模型配置/工作台/调试/MCP/知识库/概览·算力·账单/网关） |
| `lib/`（Flutter App） | `server/.../admin/{material,user,setting}` 和 `PromptController` **除外**——这 4 个后端模块归你 |
| `docs/COMPONENTS.md`（组件清单，后期建） | — |

完整归属表见 `docs/admin-freeze.md` §4.1。

**当前进度**：P0 后端已完成（管理员登录 + ADMIN 鉴权 + dev-token 隔离 + 5 张新表），你不用等后端。

---

## 1. 先装好这 4 个东西

| 工具 | 用途 | 验证命令 |
|---|---|---|
| **Git** | 拉代码 / 提交 | `git --version` |
| **JDK 21** | 跑后端 | `java -version`（要看到 `21.x`） |
| **Flutter SDK** | 跑 App | `flutter --version` |
| **VS Code**（或 IntelliJ IDEA） | 写代码 | — |

> 打包 APK 时才需要 Android SDK，现在不用装。

---

## 2. 把代码拉下来

### 第一次（还没 clone 过）

```powershell
# 连不上 GitHub 再执行这两行（端口按你自己代理软件的来）
git config --global http.proxy  http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

git clone https://github.com/uxiaoting-code/opc_ai_creator.git
cd opc_ai_creator
```

### 已经 clone 过

```powershell
cd opc_ai_creator
git pull
```

### 拉完先确认版本

```powershell
git log --oneline -1
```

**应该看到**：

```
9d82740 feat(admin): P0 地基——ADMIN 鉴权、管理员登录、dev-token 隔离、5 张新表
```

看不到这一条 = 拉到的是旧代码，先别开工。

---

## 3. 确认环境

```powershell
java -version
flutter doctor
```

`flutter doctor` 有红叉先别慌：**只要 Flutter 和 Chrome 那两项是绿的就能开始**，Android SDK 报红不影响现在。

国内如果 `flutter pub get` 卡住，先执行：

```powershell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
```

---

## 4. 把后端跑起来

```powershell
cd server
.\mvnw.cmd spring-boot:run
```

**成功标志**：日志最后出现 `Started OpcServerApplication`，然后浏览器访问：

- <http://localhost:8080/api/health> —— 应返回成功
- <http://localhost:8080/doc.html> —— 应能打开接口文档

> **如果 `.\mvnw.cmd` 报 `Cannot start maven from wrapper`：**
> 用 IntelliJ IDEA 打开 `server` 目录（会识别成 Maven 项目），
> 找到 `OpcServerApplication.java` 点绿色三角运行；
> 或在右侧 Maven 面板双击 `spring-boot:run`。

第一次启动会自动建 H2 数据库并初始化演示数据：

| 账号 | 密码 | 角色 |
|---|---|---|
| `admin` | `admin123` | 管理员 |
| `demo` | `demo123` | 普通用户 |

不需要手动装数据库。

---

## 5. 打开后台原型

用浏览器直接打开：

```
<项目根目录>\web\index.html
```

应该能看到老师的 7 页后台原型，侧栏可以切换。

**这就是你要照它改的 UI**——布局、字段、按钮、文案都别自己重新设计。

---

## 6. 把 Flutter App 跑起来

**另开一个 PowerShell 窗口**（后端那个别关）：

```powershell
cd <项目根目录>
flutter pub get
flutter run -d chrome
```

能看到 App 首页就说明环境 OK。

---

## 7. 基线验收（4 项全过，再开始写代码）

- [ ] `http://localhost:8080/api/health` 通
- [ ] `http://localhost:8080/doc.html` 能打开
- [ ] `web\index.html` 打开后 7 个页面能切换
- [ ] `flutter run -d chrome` 能进 App 首页

**四项里有一项挂了，先在群里说，别硬写。**

---

## 8. 开始干活

完整排期见 `docs/SCHEDULE.md` 的 **Week 1 前端线**。这里只说第一步。

### 第一步：Flutter 组件（约 2 天，老师要求优先）

**目录**：

```
lib/
├── widgets/common/                       # 通用组件
│   ├── app_button.dart
│   ├── app_dialog.dart
│   ├── app_chip.dart
│   └── credit_chip.dart
├── pages/
│   ├── creation/widgets/                 # 创作链路组件
│   │   ├── prompt_input_card.dart
│   │   ├── skill_selector.dart
│   │   ├── size_picker.dart
│   │   ├── param_slider_row.dart
│   │   ├── generate_bar.dart
│   │   ├── result_preview_card.dart
│   │   └── task_status_card.dart
│   └── dev/
│       └── component_gallery_page.dart   # 组件预览页
```

**必须遵守的 4 条组件规则（老师会查）**：

1. **数据进、事件出**：组件只接收要显示的数据；用户操作只通过回调抛出去。
2. **回调一律可空**：`VoidCallback? onOptimize`；为 `null` 时按钮自动置灰/隐藏——这就是"功能待实现"的标准写法。
3. **状态由外部传入**：`loading` / `enabled` / `errorMessage` 都做成参数，组件不自己管业务状态。
4. **只依赖纯数据**：可以 import `data/models/*`，**绝不能** import `repositories` / `providers` / `api_client`。

**额外两条**：

- ❌ 组件里不要 `Navigator.push` / `showDialog` / `showSnackBar`
- ❌ 组件里不要写死文案、颜色、尺寸（走参数或 `AppColors` / `AppSpacing`）

**可以这样自检**：

```powershell
Select-String -Path lib\widgets\**\*.dart,lib\pages\*\widgets\*.dart -Pattern 'api_client|repository|provider'
# 应该一行都搜不到
```

**交付物**：

- 组件预览页 `lib/pages/dev/component_gallery_page.dart`（一页看全，假数据驱动）
- `docs/COMPONENTS.md`（组件名 / 文件 / 入参 / 回调 / 被谁复用）

### 第二步：Web P0（约 3 天）

1. `web/js/api.js`
   - `baseURL` 默认 `http://localhost:8080`
   - `USE_MOCK` 开关（默认 `true`；为 true 时直接读本地 JSON，不发请求）
   - 统一带 `Authorization: Bearer <token>`（token 存 `localStorage`）
   - 统一解析 `{ code, message, data, timestamp }`，`code !== 200` 视为失败
   - 统一错误 toast；HTTP 401 清 token 回登录页
2. `web/js/util.js`：`formatCredits()`（`≥1e8 → 亿`、`≥1e4 → 万`、否则千分位）、日期格式化
3. 拆 `web/js/admin.js`（541 行）→ `web/js/pages/{dash,users,bills,models,agents,usage,settings}.js`
4. 登录页走 `api.js`（`USE_MOCK = true` 时本地假登录）
5. `web/mock/*.json`——**字段名必须严格照 `docs/api-admin.md` 抄**
6. `index.html` 侧栏追加 5 个新页入口：调试 / MCP / 知识库 / 素材库 / 网关（先空 `<section>`）

---

## 9. 让 AI 助手帮你写

在项目根目录打开 Codex / Claude Code，直接把这段发给它：

> 先读 `AGENTS.md`，再读 `docs/SCHEDULE.md` 的 Week 1 前端线。
> 本轮只做两件事：
> ① Flutter 组件第一批（含组件预览页 `lib/pages/dev/component_gallery_page.dart`）；
> ② Web P0（`api.js` / `util.js` / 拆 `admin.js` / 登录 / `mock/*.json` / 侧栏 5 个入口）。
> 不许改 `server/` 和 `lib/` 里已完成的 11 个页面。
> 组件必须受控：数据进、事件出，回调可空，不许 import `api_client` / `repository` / `provider`。
> UI 必须照 `web/` 原型，不许重新设计。

---

## 10. 每天的工作流

```powershell
git pull                                   # 开工前先拉
# ……写代码……
git add .
git commit -m "feat: 完成 PromptInputCard 等 5 个组件"
git push                                   # 收工前推上去
```

**三条纪律**：

1. **别在 github.com 网页上直接改文件**（会和本地提交分叉，一推送就冲突）
2. 改接口 → **先改 `docs/api-admin.md`**，再改代码
3. 每天至少 push 一次，别攒一周

---

## 11. 常见问题

### ① 8080 被占用

```powershell
netstat -ano | findstr :8080
```

找到 PID 后在任务管理器结束它；或先确认是不是自己已经开了一个后端。

### ② 连不上 GitHub

配代理（见第 2 节），或换个网络。

### ③ 后端启动报数据库错误

删掉 `server\data\opc_db.mv.db` 再启动（会自动重建并重新初始化演示数据）。
⚠️ 会清空本地演示数据，但不影响代码。

### ④ Flutter 报 `Building with plugins requires symlink support`

Windows 设置 → 开发者选项 → 打开"开发者模式"。

### ⑤ 页面打开是空白

按 F12 看 Console 的红色报错，把报错发群里。

### ⑥ `.\mvnw.cmd` 报 `Cannot start maven from wrapper`

用 IntelliJ IDEA 运行 `OpcServerApplication`，或用系统已安装的 Maven 执行 `mvn spring-boot:run`。

---

## 12. 红线（违反会连带 App 一起崩）

1. **不许删 `MockAiProvider`**——答辩出图 / 出视频全靠它
2. **不许改 `t_skill` 的语义**——它是 App 的「创作线路」，和原型里的「Skill（工具）」不是一回事
3. **不许改坏 `/api/**` 那 22 个 C 端接口**——App 全靠它们
4. **管理端不能使用 dev-token 固定令牌**
5. **管理端 UI 照 `web/` 原型**，不要自己重新设计

---

## 13. 第一周验收标准

- [ ] `flutter run -d chrome` 能打开组件预览页，8 个组件全部可见
- [ ] 组件里搜不到 `api_client` / `repository` / `provider`
- [ ] `docs/COMPONENTS.md` 有完整清单
- [ ] `web/index.html` 打开后，12 个页面入口可点（7 原有 + 5 新增）
- [ ] `USE_MOCK = true` 时 12 个页面都能点通、Console 无报错
- [ ] 登录页在 mock 模式下能假登录；改成 `USE_MOCK = false` 后能用 `admin/admin123` 真登录
