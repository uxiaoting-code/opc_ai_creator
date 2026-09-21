# OPC AI 多模态创作平台

> 移动应用开发课程设计 · Flutter + SpringBoot 单人全栈
> 一套代码同时兼容 **Web（Chrome 调试）** 与 **Android（最终交付 APK）**

## 项目简介

一个 AI 多模态创作平台，核心链路是 **文生图 / 图生视频**，
围绕它实现了任务调度（Harness）、多线路参数模板（Skill）、素材库、Prompt 知识库，
共 **13 个业务页面**。

| 模块 | 说明 |
|------|------|
| **OPC 链路** | 文生图、图生视频 AI 生成 |
| **Harness** | 任务调度：排队 → 生成中 → 成功/失败，支持失败重试 |
| **Skill** | 多套生成参数模板，可切换创作线路（二次元 / 写实 / 电商海报…） |
| **素材库** | 用户上传、管理参考素材图片 |
| **知识库** | Prompt 提示词库，支持检索、收藏 |

## 技术栈

**前端**：Flutter 3.47 · Provider（状态管理）· go_router（路由 + 登录守卫）· Dio（网络）

**后端**：SpringBoot · MySQL 8.0 · MyBatis-Plus / JPA

## 文档

| 文档 | 内容 |
|------|------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 目录结构、13 个页面路由表、环境切换、双端兼容约束对照 |
| [docs/DATABASE.md](docs/DATABASE.md) | 7 张表的 DDL、Harness 状态机、AI 服务商解耦设计 |
|
| [docs/api.md](docs/api.md) | 项目接口文档，包含文生图、图生视频、创作历史查询接口 |

## 快速开始

```bash
flutter pub get

# Web 调试（开发主循环，热重载最快）
flutter run -d chrome

# Android 真机 —— 后端地址要改成电脑的局域网 IP
flutter run -d <device-id> --dart-define=LAN_HOST=192.168.1.20
```

### 后端地址切换

集中在 `lib/core/config/app_config.dart`：

| 场景 | 地址 | 识别方式 |
|------|------|---------|
| Chrome 调试 | `http://localhost:8080` | 自动 |
| Android 真机 | `http://<局域网IP>:8080` | 自动 + `--dart-define=LAN_HOST=` |
| 生产 | 线上域名 | `--dart-define=APP_ENV=production` |

跑起来后进「设置页」可以看到当前实际连接的后端地址，不用猜。

## 当前进度

- [x] 目录结构 + 路由框架 + 13 个页面脚手架
- [x] 登录/注册页（可用）
- [x] **首页 Skill 选择页（完整实现）**：顶部栏（算力/消息/搜索）、Skill 线路横滑、
      文生图 / 图生视频创作入口、Prompt知识库 / Skill市场入口、最近作品横滑
- [x] 数据层：Provider → Repository →（Mock | 真实接口）双分支，一个常量切换
- [x] 网络层统一响应体 + 全局异常捕获 + 401 自动踢回登录页
- [x] 设置页环境面板、个人中心退出登录
- [ ] 文生图创作页 → 图生视频创作页
- [ ] 任务列表 / 任务详情（Harness 状态轮询）
- [ ] 后端 SpringBoot 工程

> ⚠️ `AppConfig.bypassLogin` 与 `AppConfig.useMockData` 当前都是 `true`
> （登录不调后端、业务数据走本地 Mock）。**后端联调时两个一起改成 `false`。**
> 登录页有橙色横幅提示，启动日志也会打印当前模式。

## 质量检查

```bash
flutter analyze   # ✅ No issues found
flutter test      # ✅ 8 passed
flutter build web # ✅ 构建成功
```

测试覆盖：路由表 13 页校验、登录守卫重定向、首页各区块渲染、
Skill 卡片带参跳转、消息弹层，以及 **360×800 小屏无布局溢出**。

## 打包 APK 前必须处理

1. **安装 Android SDK**（装 Android Studio，或 `flutter config --android-sdk <路径>`）
2. **开启 Windows 开发者模式**：`start ms-settings:developers`
   （Flutter 构建含插件的项目需要符号链接支持）
3. 补 `AndroidManifest.xml` 权限声明
   （清单已注释在 `lib/core/utils/permission_utils.dart` 末尾）
4. `<application>` 上加 `android:usesCleartextTraffic="true"`
   （Android 9+ 默认禁止明文 HTTP，不加连不上局域网后端）
