# OPC AI 多模态创作平台

> 移动应用开发课程设计 · **Flutter + Spring Boot**
> Flutter 用户 App + Spring Boot AI 能力后台 + Web 运营管理控制台

---

## 一、项目简介

OPC（一人公司）场景的 AI 内容生产平台，核心链路是 **文生图 / 图生视频**。
用户通过统一入口选择智能体或创作线路，完成电商组图、短视频素材、营销图片等内容生产；
运营人员通过后台配置模型、编排智能体、管理知识与素材、查看算力账单。

项目由三部分组成：

| 部分 | 目录 | 技术栈 | 状态 |
|---|---|---|---|
| **用户 App（前台）** | `lib/` | Flutter 3（Web + Android） | 已有 13 页基础实现；需按老师 28 页 HTML 原型重构/补齐 |
| **后端 API** | `server/` | Spring Boot 4.1.1 + Java 21 + JPA + H2/MySQL | C 端 22 个接口 + 管理端 P0~P8 已跑通 |
| **后台控制台（运营配置）** | `admin-web/` | 原生 HTML + CSS + JS | 老师原型 + 12 页实现；待逐页接真接口 |

> `web/` 是 Flutter Web 的启动壳，不是后台控制台。
> **Flutter 复刻的是用户 App（`lib/`）页面；运营后台继续使用 `admin-web/`，不要创建 `lib/admin/`。**

### 系统链路

```text
Flutter 用户 App ── HTTP 请求 /api/** ─────▶ Spring Boot server ──▶ Harness ──▶ AI Provider
admin-web 控制台 ── HTTP 请求 /api/admin/** ─▶ Spring Boot server（保存 API / Skill / Harness 配置）
```

用户 App 的页面、视觉和交互以 `docs/prototype-user/` 中老师提供的移动端 HTML 原型为准，但最终交付必须用 Flutter 实现。

用户 App 发起文生图 / 图生视频指令，后端鉴权、扣算力、创建任务并交给 Harness 调度；
App 再通过任务接口获取状态、结果 URL 与错误信息。后台控制台负责准备模型 API、Skill、
Harness 编排、知识库和运营配置。

---

## 二、核心能力

### App 端

- 文生图 / 图生视频创作
- Harness 任务调度：排队 → 生成中 → 成功/失败，支持重试与取消
- Skill 创作线路：二次元 / 写实摄影 / 电商海报 / 国风水墨 / 动效
- 任务列表、任务详情、作品画廊、作品详情
- 素材库（上传 / 检索 / 删除）
- Prompt 知识库（检索 / 收藏 / 一键创作）
- 个人中心、设置、主题切换

### 后台端

- **模型 / API 配置**：鉴权、请求模板、响应模板、连通性测试、上架/调价
- **智能体工作台**：节点编排、发布/下线、复制、版本快照与回滚、编排预览
- **调试面板**：单节点 / 全链路 / 对话式 / 日志追踪 / 版本对比 / 回归用例
- **MCP 接入**：注册 Server、发现工具、启用、映射到工具库、试调用
- **知识库**：文本 / 文件 / URL / API 同步、分段、检索测试、绑定智能体
- **素材库后台**：分类、多级标签、检索、版本
- **算力与运营**：算力流水、账单、充值/退款、数据概览、算力统计、TOP 用户
- **API 网关**：对外接口定义、OpenAPI 3.0 导出

### 运行时底座

- **Harness**：状态机 + 轮询调度 + 独立线程池 + 超时清扫 + 重试/取消
- **AiProvider**：Mock / Stable Diffusion / 配置驱动 HTTP Provider
- **算力计量**：建任务扣费 + 流水表 + 账单/统计统一口径

---

## 三、技术栈

| 层 | 技术 |
|---|---|
| App | Flutter 3.47 · Provider · go_router · Dio · video_player / chewie |
| 后端 | Spring Boot 4.1.1 · Java 21 · Spring Data JPA · H2（默认）/ MySQL 8 |
| 管理端 | 原生 HTML + CSS + JS（`admin-web/`） |
| 接口文档 | Knife4j（`/doc.html`）+ `docs/api.md` / `docs/api-admin.md` |

---

## 四、目录结构

```text
opc_ai_creator/
├── lib/                      Flutter 用户 App
│   ├── core/                 配置 / 路由 / 网络 / 主题 / 工具
│   ├── data/                 models / repositories / mock
│   ├── pages/                13 个业务页面
│   ├── providers/            状态管理
│   └── widgets/              通用组件 + 业务组件
├── server/                   Spring Boot 后端
│   ├── src/main/java/...     controller / service / entity / harness / ai / admin
│   ├── src/main/resources/   application.yml / application-mysql.yml
│   └── docs/schema.sql       MySQL 建表脚本（24 张表）
├── admin-web/                老师给的 HTML 原型 + 后台控制台实现（12 页）
├── web/                      Flutter Web 启动壳
├── docs/                     需求、契约、架构、排期等文档
└── test/                     Flutter / 后端测试
```

---

## 五、快速开始

### 1. 启动后端

```bash
cd server
./mvnw spring-boot:run            # Windows: .\mvnw.cmd spring-boot:run
```

- 健康检查：<http://localhost:8080/api/health>
- 接口文档：<http://localhost:8080/doc.html>

默认使用 H2 文件库，开箱即跑；切 MySQL：

```bash
# 先执行 server/docs/schema.sql 建库建表
./mvnw spring-boot:run -Dspring-boot.run.profiles=mysql
```

> 如果 `mvnw` 在当前 PowerShell 报错，用 IntelliJ 运行 `OpcServerApplication`，
> 或先 `mvn package` 再 `java -jar target/opc-server-0.0.1-SNAPSHOT.jar`。

### 2. 启动 Flutter App

```bash
flutter pub get
flutter run -d chrome
```

Android 真机：

```bash
flutter run -d <device-id> --dart-define=LAN_HOST=192.168.1.20
```

### 3. 启动后台控制台（`admin-web/`）

用 VS Code 的 **Live Server** 打开 `admin-web/index.html`：

- mock 模式：`http://127.0.0.1:5500/index.html`
- 真接口模式：`http://127.0.0.1:5500/index.html?mock=0`（后端需运行在 8080）

后台是 HTML/CSS/JS，不是 Flutter 页面，不要创建 `lib/admin/`。

---

## 六、演示账号

| 账号 | 密码 | 角色 |
|---|---|---|
| `admin` | `admin123` | 管理员 |
| `demo` | `demo123` | 普通用户 |

首次启动会自动初始化：6 条创作线路、5 条 Prompt、6 条模型配置、
2 个智能体、知识库、MCP 演示数据、算力流水、网关接口。

---

## 七、文档

| 文档 | 内容 |
|---|---|
| [docs/requirements-opc-admin.pdf](docs/requirements-opc-admin.pdf) | 老师给的后台需求文档 |
| [docs/prototype-user/](docs/prototype-user/) | **老师提供的用户端移动 App HTML/CSS/JS 原型与页面清单** |
| [docs/USER_PROTOTYPE_GAP.md](docs/USER_PROTOTYPE_GAP.md) | **原型 28 页与当前 Flutter 的差异、缺口和开发顺序** |
| [docs/api-admin.md](docs/api-admin.md) | **管理端接口契约**（12 页 / 错误码 / 枚举 / 变更记录） |
| [docs/SCHEDULE.md](docs/SCHEDULE.md) | **开发排期、分工、当前进度、最终验收清单** |
| [docs/admin-freeze.md](docs/admin-freeze.md) | 三项共用模型冻结 + 文件归属 |
| [docs/COMPONENTS.md](docs/COMPONENTS.md) | Flutter 组件清单 |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 后端架构、Flutter 目录、双端环境切换 |
| [docs/DATABASE.md](docs/DATABASE.md) | C 端表结构与 Harness 设计 |
| [docs/api.md](docs/api.md) | C 端 22 个接口契约 |
| [docs/HANDOFF.md](docs/HANDOFF.md) | C 端交接说明与已知问题 |
| [docs/ADMIN_PLAN.md](docs/ADMIN_PLAN.md) | 背景与历史分工（纵切版，仅背景参考） |

---

## 八、当前进度

### 已完成

- [x] 后端 P0~P8：鉴权、模型配置、工作台、调试、MCP、知识库、运营账单、API 网关
- [x] Harness 任务调度 + Mock 出图/出视频
- [x] Flutter 用户 App 已有 13 页基础实现（不等于已完成老师新原型的复刻）
- [x] Prompt 知识库页
- [x] 素材库 / 用户管理 / 系统设置（C 端与后台接口）
- [x] `admin-web/` 原型、12 页界面与 mock 数据

### 待完成

- [ ] **Flutter 用户 App 按 `docs/prototype-user/` 逐页复刻老师原型，先组件、再 4 个一级 Tab 和创作主流程**
- [ ] **`admin-web/` 12 页逐页接 `/api/admin/**` 真接口**
- [ ] 端到端联调：Flutter 指令 → 后端 → Harness → AI → 结果回传
- [ ] 演示脚本 + 打包 APK
- [ ] 关闭 `dev-token-enabled` 与 `bypassLogin`

> 详细的逐项任务和勾选框见 `docs/SCHEDULE.md`。

---

## 九、交付前检查

- [ ] Flutter 用户 App 13 个页面可运行
- [ ] 后台控制台 `admin-web` 12 个页面可运行并接真接口
- [ ] 管理端 P0~P8 接口全部可用
- [ ] 统一工具库包含：内置 + 模型 + MCP + 知识库
- [ ] `docs/api-admin.md` 与代码一致
- [ ] `docs/COMPONENTS.md` 包含 Flutter 用户 App 组件清单
- [ ] 演示脚本端到端跑通
- [ ] `dev-token-enabled = false`
- [ ] `AppConfig.bypassLogin = false`

---

## 十、质量检查

```bash
# Flutter
flutter analyze
flutter test

# 后端
cd server
./mvnw test
```

---

## 十一、说明

- `admin-web/` 是老师给的 HTML 后台原型和实际运营控制台；Flutter 只用于 `lib/` 中的用户 App。
- `MockAiProvider` 是答辩演示的保底能力，**不要删除**。
- 不要在 github.com 网页上直接编辑文件，改代码请走本地 `git pull → 修改 → commit → push`。
