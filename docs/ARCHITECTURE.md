# OPC AI 多模态创作平台 · 架构说明

> 移动应用开发课程设计 · Flutter + SpringBoot 单人全栈
> 一套代码同时兼容 **Web（Chrome 调试）** 与 **Android（最终交付 APK）**

---

## 一、目录结构

```
opc_ai_creator/
├── lib/
│   ├── main.dart                      # 入口：解开循环依赖、恢复本地状态、runApp
│   ├── app.dart                       # 根组件：MultiProvider + MaterialApp.router
│   │
│   ├── core/                          # ── 基础设施层（与业务无关，全项目复用）──
│   │   ├── config/
│   │   │   └── app_config.dart        # ★ 环境区分：Web=localhost / Android=局域网IP
│   │   │                              #   同时存放 ApiEndpoints 全部接口路径常量
│   │   ├── router/
│   │   │   ├── route_names.dart       # ★ 13 个页面的路由名 / 路径常量 + 对照表
│   │   │   └── app_router.dart        # ★ go_router 路由表 + 登录守卫
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # 品牌色 + Harness 任务状态语义色
│   │   │   ├── app_spacing.dart       # 间距/圆角/尺寸令牌（手指友好尺寸）
│   │   │   └── app_theme.dart         # 浅色/深色主题
│   │   ├── network/
│   │   │   ├── api_client.dart        # Dio 封装：统一请求、上传、日志、鉴权
│   │   │   ├── api_response.dart      # 统一响应体 ApiResponse<T> + PageResult<T>
│   │   │   └── api_exception.dart     # 统一异常，把底层错误翻译成中文提示
│   │   └── utils/
│   │       ├── platform_utils.dart    # 平台判断（禁止业务代码直接用 dart:io）
│   │       ├── permission_utils.dart  # ★ Android 相册/存储/相机权限（Web 自动跳过）
│   │       └── media_utils.dart       # ★ 选图/选视频/字节流读取（双端统一）
│   │
│   ├── data/                          # ── 数据层 ──
│   │   ├── models/
│   │   │   ├── user_model.dart        # 用户（t_user）
│   │   │   ├── skill_model.dart       # Skill 线路（t_skill）+ SkillType 枚举
│   │   │   ├── work_model.dart        # 作品（t_work）+ WorkType 枚举
│   │   │   └── notification_model.dart# 消息通知
│   │   ├── datasources/
│   │   │   └── mock_data.dart         # ★ 本地假数据源（后端未就绪时用）
│   │   └── repositories/
│   │       ├── skill_repository.dart  # ★ Mock / 真实接口 双分支
│   │       ├── work_repository.dart
│   │       └── notification_repository.dart
│   │       # 后续迭代补充：ai_task_model / material_model / prompt_model
│   │       #                  及对应的 repository
│   │
│   ├── providers/                     # ── 状态管理层（Provider）──
│   │   ├── auth_provider.dart         # 登录态（被路由守卫用作 refreshListenable）
│   │   ├── theme_provider.dart        # 主题模式（持久化）
│   │   ├── skill_provider.dart        # Skill 线路（首页 + Skill 市场共用）
│   │   ├── work_provider.dart         # 作品（首页最近作品 + 画廊共用）
│   │   └── notification_provider.dart # 消息未读数与列表
│   │       # 后续迭代补充：task_provider / material_provider / prompt_provider
│   │
│   ├── widgets/                       # ── 通用组件层 ──
│   │   ├── mobile_viewport.dart       # ★ 宽屏时把页面收窄成手机比例
│   │   ├── scaffold_page.dart         # ★ 脚手架页面的统一外壳
│   │   ├── route_check_panel.dart     # 路由自检面板（开发调试用，可删）
│   │   ├── state_views.dart           # 加载/空/错误/状态标签
│   │   ├── section_header.dart        # 区块标题（首页 4 个区块共用）
│   │   ├── cover_image.dart           # ★ 封面图：无 URL 时渲染确定性渐变色块
│   │   └── media/
│   │       └── media_viewers.dart     # ★ 图片预览（缩放）+ 视频播放 + 网络图片
│   │
│   └── pages/                         # ── 页面层（13 个业务页面）──
│       ├── shell/
│       │   └── main_shell.dart        # 底部导航外壳（5 个 Tab）
│       ├── auth/
│       │   └── login_register_page.dart      # 页面 1  ✅ 已实现
│       ├── home/
│       │   ├── home_page.dart                # 页面 2  ✅ 已实现
│       │   └── widgets/                      # 首页专用组件
│       │       ├── home_top_bar.dart         #   顶部栏（算力/消息/搜索）
│       │       ├── skill_card.dart           #   Skill 线路卡片
│       │       ├── creation_entry_card.dart  #   文生图 / 图生视频入口
│       │       ├── feature_entry_card.dart   #   Prompt知识库 / Skill市场入口
│       │       ├── recent_work_card.dart     #   最近作品缩略图
│       │       └── notification_sheet.dart   #   消息弹层
│       ├── creation/
│       │   ├── text_to_image_page.dart       # 页面 3
│       │   └── image_to_video_page.dart      # 页面 4
│       ├── task/
│       │   ├── task_list_page.dart           # 页面 5
│       │   └── task_detail_page.dart         # 页面 13
│       ├── gallery/
│       │   ├── gallery_page.dart             # 页面 6
│       │   └── work_detail_page.dart         # 页面 10
│       ├── material/
│       │   └── material_library_page.dart    # 页面 7
│       ├── knowledge/
│       │   └── prompt_library_page.dart      # 页面 8
│       ├── skill/
│       │   └── skill_market_page.dart        # 页面 9
│       ├── profile/
│       │   └── profile_page.dart             # 页面 11（部分实现）
│       └── settings/
│           └── settings_page.dart            # 页面 12（部分实现）
│
├── docs/
│   ├── ARCHITECTURE.md                # 本文件
│   └── DATABASE.md                    # 数据库表设计 + 实体类映射
│
├── test/
│   └── widget_test.dart               # 脚手架冒烟测试（路由表 + 登录守卫）
│
└── android/  web/  ...                # 平台工程目录
```

### 分层依赖方向

```
pages/  ──依赖──▶  providers/  ──依赖──▶  data/models
   │                    │                      │
   └────────▶ widgets/ ─┴──▶ core/network ◀────┘
                                 │
                             core/config
```

**约束：`core/` 不允许 import `pages/` 或 `providers/`**，保证基础设施层可复用。
(唯一例外是 `core/router/app_router.dart` 需要 import 页面来建路由表，
这是 go_router 的固有写法，也是路由层存在的意义。)

---

## 二、13 个页面路由对照表

| # | 页面 | 路由路径 | 注册位置 | 状态 |
|---|------|---------|---------|------|
| 1 | 登录/注册页 | `/login` | 顶层路由 | ✅ 已实现 |
| 2 | 首页（Skill选择入口） | `/home` | 底部 Tab 1 | ✅ 已实现 |
| 3 | 文生图创作页 | `/create/text-to-image` | 顶层（可带 `?skillId=`） | 脚手架 |
| 4 | 图生视频创作页 | `/create/image-to-video` | 顶层（可带 `?skillId=`） | 脚手架 |
| 5 | 我的任务列表页 | `/tasks` | 底部 Tab 2 | 脚手架 |
| 6 | 作品画廊 | `/gallery` | 底部 Tab 3 | 脚手架 |
| 7 | 素材库页 | `/materials` | 底部 Tab 4 | 脚手架 |
| 8 | Prompt知识库广场 | `/prompts` | 顶层路由 | 脚手架 |
| 9 | Skill市场页 | `/skills` | 顶层路由 | 脚手架 |
| 10 | 作品详情页 | `/gallery/:workId` | Tab3 分支内 push | 脚手架 |
| 11 | 个人中心 | `/profile` | 底部 Tab 5 | 部分实现 |
| 12 | 设置页 | `/settings` | 顶层路由 | 部分实现 |
| 13 | 任务详情页 | `/tasks/:taskId` | Tab2 分支内 push | 脚手架 |

### 为什么用 go_router 而不是 Navigator 命名路由

Chrome 调试时地址栏会真实显示 `/tasks/12`，**刷新页面不丢路由**，浏览器前进/后退可用。
Navigator 命名路由在 Web 上所有地址都塌缩成 `/`，刷新即回首页，调试体验很差。
Android 上二者都是原生页面栈，行为一致 —— 所以选 go_router 是双端都受益。

### 底部导航（StatefulShellRoute）

5 个 Tab：**首页 / 任务 / 画廊 / 素材 / 我的**。
每个 Tab 维护**独立的导航栈**：在「任务」里点进任务详情后切到「画廊」，
再切回来仍停留在详情页 —— 这是手机 App 的标准交互。
详情页作为分支子路由，push 进去后底部导航栏依然在。

### 登录守卫

`AppRouter.redirect` 统一拦截：

```
未登录 + 访问非 /login  → 重定向到 /login?redirect=<原地址>
已登录 + 访问 /login    → 重定向到 /home
```

守卫挂在 `refreshListenable: authProvider` 上，所以**退出登录后会自动弹回登录页**，
不需要任何手动 `Navigator.push`。登录成功后读取 `redirect` 参数回到原本想去的页面。

---

## 三、环境切换（需求 #3）

全部集中在 `lib/core/config/app_config.dart`，业务代码只读 `AppConfig.baseUrl`：

| 场景 | 后端地址 | 触发条件 |
|------|---------|---------|
| Chrome Web 调试 | `http://localhost:8080` | `kIsWeb` 自动识别 |
| Android 真机 | `http://<局域网IP>:8080` | `defaultTargetPlatform == android` 自动识别 |
| 生产 | `https://api.opc-ai-creator.com` | `--dart-define=APP_ENV=production` |

三种切换方式：

```bash
# 1) 改代码常量（最直接）
#    app_config.dart 里的 AppConfig.lanHost

# 2) 运行时指定，不改代码（推荐）
flutter run -d chrome --dart-define=APP_ENV=webDev
flutter build apk --dart-define=APP_ENV=androidDevice --dart-define=LAN_HOST=192.168.1.20

# 3) 只临时改 IP
flutter run --dart-define=LAN_HOST=192.168.1.20
```

> **Android 连不上后端的排查顺序**（这个坑必踩）：
> 1. `ipconfig` 拿到电脑局域网 IPv4，填进 `lanHost`；
> 2. 手机与电脑连**同一个 WiFi**（不能一个 WiFi 一个热点）；
> 3. SpringBoot 必须监听 `0.0.0.0`（`server.address=0.0.0.0`），不能是 127.0.0.1；
> 4. **Windows 防火墙放行 8080 端口**（最常见的失败原因）；
> 5. Android 9+ 默认禁止明文 HTTP，`AndroidManifest.xml` 的 `<application>` 要加
>    `android:usesCleartextTraffic="true"`。

「设置页」已实现**环境信息面板**，联调时可一眼确认当前连的是哪个后端 —— 不用再猜。

---

## 四、双端兼容约束对照（需求 #2 / #4 / #5）

| 约束 | 实现方式 | 位置 |
|------|---------|------|
| 所有三方包支持 Android + Web | 见下方依赖清单，**已验证 `flutter build web` 通过** | `pubspec.yaml` |
| 禁止仅 Web 可用的库 | 平台判断统一走 `PlatformUtils`，**全项目不 import `dart:io`**（`dart:io` 在 Web 不存在，一引就编译失败） | `core/utils/platform_utils.dart` |
| 图片上传 | `image_picker` + **字节流上传**（Web 上 `XFile.path` 是 blob URL，后端拿不到，必须 `readAsBytes()`） | `core/utils/media_utils.dart` |
| 图片预览 | Flutter 内置 `InteractiveViewer`，支持双指缩放/双击放大，零依赖 | `widgets/media/media_viewers.dart` |
| 视频播放 | `video_player`（Android 用 ExoPlayer / Web 用 HTML5 video）+ `chewie` 控件 | `widgets/media/media_viewers.dart` |
| 文件下载 | ⚠️ **占位未实现**，两端差异大（Web 用 Blob 触发下载；Android 需 `path_provider`，而它**不支持 Web**，必须用条件导入拆文件） | `media_utils.saveToLocal()` |
| Android 权限预留 | `permission_utils.dart` 已写好完整申请逻辑，Web 端直接返回 `notRequired`；AndroidManifest 待补声明已注释在文件末尾 | `core/utils/permission_utils.dart` |
| 手机竖屏布局 | 全局 `MobileViewport`：宽度 > 480 时居中收窄成手机比例；点击热区 ≥ 48dp | `widgets/mobile_viewport.dart` |

### 依赖清单（均已验证支持 Android + Web）

| 包 | 版本 | 用途 |
|----|------|------|
| `provider` | ^6.1.5 | 状态管理（需求指定） |
| `go_router` | ^18.0.1 | 路由 + 登录守卫 + Web URL |
| `dio` | ^5.11.1 | HTTP 客户端 + multipart 上传 |
| `shared_preferences` | ^2.5.5 | 本地持久化（token、主题） |
| `image_picker` | ^1.2.3 | 选图 / 拍照 |
| `video_player` + `chewie` | ^2.14.0 / ^1.17.1 | 视频播放 |
| `permission_handler` | ^13.0.2 | Android 权限（Web 端有实现，已做平台判断） |
| `intl` | ^0.20.3 | 日期格式化 |
| `flutter_localizations` | SDK | 中文本地化（否则 Material 控件显示英文） |

> 依赖刻意保持精简：**每个插件都会往 Android Gradle 里加一份原生依赖，
> 都是 APK 打包时的潜在报错点。** 目前只保留当前真正在用的包。
> `file_picker`（文件下载迭代）等后续需要时再 `flutter pub add`，
> 加完**立刻跑一次 `flutter build web` + `flutter build apk`** 验证两端都没崩。

> ### ⚠️ 已排除的包：`cached_network_image`
>
> 它曾经被加进来，但**必须移除**：它会带进
> `flutter_cache_manager → path_provider → path_provider_foundation → objective_c`
> 一长串传递依赖，其中 `objective_c` 的 native assets 构建钩子在本机 Dart SDK 上
> 直接编译失败（`Member not found: 'arm64e'`），导致 `flutter test / run / build`
> **全线报错** —— 不只是 iOS，Android 和 Web 一起挂。
>
> 移除后少了 27 个传递依赖。网络图片改用 Flutter 内置的 `Image.network`
> + `loadingBuilder` / `errorBuilder`，功能完全够用（内存缓存由 `ImageCache` 负责，
> Web 上磁盘缓存由浏览器 HTTP 缓存负责）。
>
> **教训：加三方包后一定要立刻跑一次 `flutter build web`，别等到打包 APK 才发现。**

---

## 五、统一响应体与全局异常

后端返回：

```json
{ "code": 200, "message": "success", "data": {...}, "timestamp": 1737000000000 }
```

前端对应 `ApiResponse<T>`；`PageResult<T>` 用于分页。

异常处理是**单向漏斗**，UI 层只需要 catch 一种异常：

```
DioException / HTTP 4xx / HTTP 5xx / 业务码 != 200
        │
        ▼
  ApiException.fromDio()          ← 翻译成中文提示
        │
        ▼
  throw ApiException(message: '网络连接失败，请检查手机与电脑是否在同一 WiFi...')
        │
        ▼
  页面 catch (e) → SnackBar(e.message)
```

401 会被 `AuthInterceptor` 单独拦截 → 回调 `AuthProvider.handleUnauthorized()`
→ `notifyListeners()` → 路由守卫自动把人送回登录页。**跳转逻辑只有一份。**

---

## 六、数据层：Mock 与真实接口一键切换

后端 SpringBoot 还没起，但前端页面要能完整开发、演示、跑测试。
所以数据层做成 **Provider → Repository → (Mock 数据源 | 真实接口)** 两条分支，
由 `AppConfig.useMockData` 一个常量切换：

```
页面  ──▶  Provider  ──▶  Repository  ──┬── useMockData=true  ──▶  MockData（本地假数据）
                                        └── useMockData=false ──▶  ApiClient ──▶ SpringBoot
```

关键点：**切换数据源不需要改任何页面代码**。因为 Repository 的方法签名
（`Future<List<SkillModel>> fetchSkills()`）在两条分支下完全一致，
Provider 和页面只依赖这个签名。

`MockData` 里的字段结构与 `docs/DATABASE.md` 的表设计**严格对齐**，
所以后端一落地，把 `fromJson` 接上即可，模型层不用返工。

### 两个开关是一对

| 开关 | 作用 | 联调时 |
|------|------|--------|
| `AppConfig.bypassLogin` | 登录是否走真实接口 | 改 `false` |
| `AppConfig.useMockData` | 业务数据是否走 Mock | 改 `false` |

```bash
flutter run --dart-define=BYPASS_LOGIN=false --dart-define=USE_MOCK_DATA=false
```

### 封面图的处理

后端没返回 `coverUrl` 时，`CoverImage` 会渲染一个**由种子决定的渐变色块**
（种子一般是 `skill.code` 或 `'work_${work.id}'`），而不是灰底或破图。
哈希是自己实现的稳定版本，不用 `String.hashCode` ——
Dart 没有承诺它跨版本稳定，万一变了封面颜色会集体乱掉。

这样开发阶段和答辩演示时页面都是好看的，不会因为没接后端显得潦草。

---

## 七、运行方式

```bash
# Web 调试（开发主循环，热重载最快）
flutter run -d chrome

# 列出可用设备
flutter devices

# Android 真机（需先装 Android SDK）
flutter run -d <device-id>

# 打包 APK
flutter build apk --release --dart-define=APP_ENV=androidDevice --dart-define=LAN_HOST=192.168.1.20

# 质量检查
flutter analyze
flutter test
```

### 当前环境状态（已实测）

| 项 | 状态 |
|----|------|
| `flutter analyze` | ✅ No issues found |
| `flutter test` | ✅ 3 个测试全部通过 |
| `flutter build web` | ✅ 构建成功 |
| `flutter build apk` | ❌ **未验证** —— 本机未安装 Android SDK |
| Windows 开发者模式 | ⚠️ **未开启**，构建含插件的 Android 包需要符号链接支持 |

**打包 APK 前必须先处理这两项**（详见下节）。

---

## 八、待办与阻塞项

### 🔴 阻塞 APK 打包（需先解决）

1. **安装 Android SDK**
   装 Android Studio，或 `flutter config --android-sdk <路径>` 指向已有 SDK。
2. **开启 Windows 开发者模式**
   `start ms-settings:developers`。
   Flutter 构建含插件的项目需要创建符号链接，未开启会报
   `Building with plugins requires symlink support`。

### 🟡 后续迭代（按课程设计顺序）

1. 后端 SpringBoot 工程骨架（实体类 + Mapper + Service + Controller）
2. 登录注册对接真实接口（`bypassLogin` 与 `useMockData` 一起改成 `false`）
3. ✅ 首页 Skill 选择（已完成）
4. 文生图创作页 → 图生视频创作页
5. 任务列表 / 任务详情（Harness 状态轮询）
6. 素材库（上传 + 权限申请落地）
7. Prompt 知识库 / Skill 市场 / 作品画廊 / 作品详情
8. 个人中心 / 设置页补全
9. 文件下载功能（Web Blob + Android 条件导入两套实现）
10. **打包 APK 并补 AndroidManifest 权限声明**

### ⚪ 脚手架模式开关

`AppConfig.bypassLogin` 当前为 **`true`**：登录页不调后端，点登录直接建立本地模拟会话，
方便后端没写好时先把 13 个页面点一遍。

**后端联调开始时，务必改成 `false`**（或运行时 `--dart-define=BYPASS_LOGIN=false`）。
登录页顶部有醒目的橙色横幅提示当前处于该模式，不会忘记。

### 🧹 脚手架清理清单

页面全部实现后删掉：
- `lib/widgets/route_check_panel.dart`（整个文件）
- `lib/pages/settings/settings_page.dart` 里的 `const RouteCheckPanel(),` 一行

> 路由自检面板原本挂在首页底部，首页做成正式页面后已挪到设置页 ——
> 设置页本来就是「调试信息」的归属地，不会影响正式 UI。
