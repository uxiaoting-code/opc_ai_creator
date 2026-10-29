# OPC AI 多模态创作平台

> 移动应用开发课程设计 · **Flutter + Spring Boot**
> 前台 App + AI 能力后台 + Flutter 管理控制台

---

## 一、项目简介

OPC（一人公司）场景的 AI 内容生产平台，核心链路是 **文生图 / 图生视频**。
用户通过统一入口选择智能体或创作线路，完成电商组图、短视频素材、营销图片等内容生产；
运营人员通过后台配置模型、编排智能体、管理知识与素材、查看算力账单。

项目由三部分组成：

| 部分 | 目录 | 技术栈 | 状态 |
|---|---|---|---|
| **终端 App（前台）** | `lib/` | Flutter 3（Web + Android） | 13 页中 12 页完成，Skill 市场页仍是占位 |
| **后端 API** | `server/` | Spring Boot 4.1.1 + Java 21 + JPA + H2/MySQL | C 端 22 个接口 + 管理端 P0~P8 已跑通 |
| **后台控制台（最终交付）** | `lib/admin/` | Flutter（复刻 `admin-web/` 原型） | 尚未开始 |
| **后台原型（视觉参考）** | `admin-web/` | 原生 HTML + CSS + JS | 已完成，仅作参考 |

> `web/` 是 Flutter Web 的启动壳，不是后台控制台。
> 后台的视觉基准在 `admin-web/`，最终交付是 `lib/admin/` 的 Flutter 版本。

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
| 管理端 | Flutter（复刻 `admin-web/` 原型） |
| 接口文档 | Knife4j（`/doc.html`）+ `docs/api.md` / `docs/api-admin.md` |

---

## 四、目录结构

```text
opc_ai_creator/
├── lib/                      Flutter App
│   ├── admin/                Flutter 管理端（待做）
│   ├── core/                 配置 / 路由 / 网络 / 主题 / 工具
│   ├── data/                 models / repositories / mock
│   ├── pages/                13 个业务页面
│   ├── providers/            状态管理
│   └── widgets/              通用组件 + 业务组件
├── server/                   Spring Boot 后端
│   ├── src/main/java/...     controller / service / entity / harness / ai / admin
│   ├── src/main/resources/   application.yml / application-mysql.yml
│   └── docs/schema.sql       MySQL 建表脚本（24 张表）
├── admin-web/                老师给的 HTML 原型 + 原生 JS 实现（视觉参考）
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

### 3. 查看后台原型（视觉参考）

用 VS Code 的 **Live Server** 打开 `admin-web/index.html`（`mock/*.json` 需要 HTTP 服务）。

### 4. 启动 Flutter 管理端（待做）

```bash
flutter run -d chrome -t lib/admin/main_admin.dart
```

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
| [docs/requirements-opc-admin.pdf](docs/requirements-opc-admin.pdf) | 老师给的需求文档 |
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
- [x] Flutter App 12/13 页
- [x] Prompt 知识库页
- [x] 素材库 / 用户管理 / 系统设置（C 端与后台接口）
- [x] `admin-web/` 原型与 mock 数据（视觉参考）

### 待完成

- [ ] **Flutter 管理端 `lib/admin/`：组件 + 12 个页面**（老师新增要求）
- [ ] App 的 **Skill 市场页**（当前是占位）
- [ ] 设置页的「待实现」区块（实现或删除）
- [ ] 端到端联调 + 演示脚本
- [ ] 打包 APK
- [ ] 关闭 `dev-token-enabled` 与 `bypassLogin`

> 详细的逐项任务和勾选框见 `docs/SCHEDULE.md`。

---

## 九、交付前检查

- [ ] App 13 个页面可运行
- [ ] Flutter 管理端 12 个页面可运行（按 `admin-web/` 原型复刻）
- [ ] 管理端 P0~P8 接口全部可用
- [ ] 统一工具库包含：内置 + 模型 + MCP + 知识库
- [ ] `docs/api-admin.md` 与代码一致
- [ ] `docs/COMPONENTS.md` 包含 App + 管理端组件清单
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

- `admin-web/` 是老师给的 HTML 原型的**视觉参考**，最终管理端是 `lib/admin/` 的 Flutter 版。
- `MockAiProvider` 是答辩演示的保底能力，**不要删除**。
- 不要在 github.com 网页上直接编辑文件，改代码请走本地 `git pull → 修改 → commit → push`。
