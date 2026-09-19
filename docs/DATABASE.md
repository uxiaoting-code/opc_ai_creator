# 数据库设计（MySQL 8.0）

> OPC AI 多模态创作平台 · 后端数据模型
> 字符集 `utf8mb4` / 排序规则 `utf8mb4_general_ci` / 引擎 `InnoDB`

## 表清单

| # | 表名 | 说明 | 对应需求 |
|---|------|------|---------|
| 1 | `t_user` | 用户表 | 登录注册 |
| 2 | `t_skill` | Skill 线路配置表 | Skill（多线路） |
| 3 | `t_ai_task` | AI 任务表 | OPC 链路 + Harness 调度 |
| 4 | `t_material` | 素材表 | 素材库 |
| 5 | `t_prompt` | Prompt 知识库表 | 知识库 |
| 6 | `t_prompt_favorite` | 提示词收藏关联表 | 知识库（收藏） |
| 7 | `t_work` | 作品表 | 作品画廊 / 作品详情 |

> 老师要求的 5 张核心表是 1~5。第 6、7 张是**页面清单推导出来的必要补充**：
> 「Prompt 知识库」要求支持收藏，用户与提示词是多对多，必须有中间表；
> 「作品画廊 / 作品详情」两个页面需要独立的作品实体 —— 任务表存的是**执行过程**，
> 作品表存的是**用户可见的成果**，两者生命周期不同（任务可删，作品要留）。

---

## 一、ER 关系

```
t_user ──1:N──▶ t_ai_task ──N:1──▶ t_skill
   │                 │
   │                 └──1:1──▶ t_work        （任务成功 → 产出作品）
   │
   ├──1:N──▶ t_material
   ├──1:N──▶ t_prompt        （用户投稿的提示词）
   └──1:N──▶ t_prompt_favorite ──N:1──▶ t_prompt
```

---

## 二、表结构 DDL

### 1. t_user 用户表

```sql
CREATE TABLE `t_user` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username`    VARCHAR(50)  NOT NULL                COMMENT '登录账号，唯一',
  `password`    VARCHAR(100) NOT NULL                COMMENT '密码（BCrypt 加密，禁止明文）',
  `nickname`    VARCHAR(50)           DEFAULT NULL   COMMENT '昵称，为空时回退到 username',
  `avatar`      VARCHAR(255)          DEFAULT NULL   COMMENT '头像URL',
  `email`       VARCHAR(100)          DEFAULT NULL   COMMENT '邮箱',
  `phone`       VARCHAR(20)           DEFAULT NULL   COMMENT '手机号',
  `role`        VARCHAR(20)  NOT NULL DEFAULT 'USER' COMMENT '角色：USER / ADMIN',
  `credits`     INT          NOT NULL DEFAULT 200    COMMENT '剩余算力点，创建任务时扣减',
  `status`      TINYINT      NOT NULL DEFAULT 1      COMMENT '状态：1正常 0禁用',
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`     TINYINT      NOT NULL DEFAULT 0      COMMENT '逻辑删除：0未删 1已删',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
```

### 2. t_skill Skill 线路配置表

Skill = 一整套生成参数模板。用户切换线路即切换风格，**不需要改任何代码** ——
新增一条线路就是往这张表插一行。

```sql
CREATE TABLE `t_skill` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '线路ID',
  `code`            VARCHAR(50)  NOT NULL                COMMENT '线路编码，如 anime_v1',
  `name`            VARCHAR(50)  NOT NULL                COMMENT '线路名称，如 二次元插画',
  `type`            VARCHAR(20)  NOT NULL                COMMENT '适用类型：TEXT_TO_IMAGE / IMAGE_TO_VIDEO',
  `cover_url`       VARCHAR(255)          DEFAULT NULL   COMMENT '封面示例图',
  `description`     VARCHAR(500)          DEFAULT NULL   COMMENT '线路说明',
  `scene`           VARCHAR(100)          DEFAULT NULL   COMMENT '适用场景，如 头像/海报/短视频',
  -- ↓ 模型与推理参数：MCP 思想里「能力描述」的部分
  `provider`        VARCHAR(50)  NOT NULL DEFAULT 'mock' COMMENT 'AI服务商标识，决定路由到哪个 Provider 实现',
  `model_name`      VARCHAR(100)          DEFAULT NULL   COMMENT '模型名，如 sd-xl-anime',
  `sampler`         VARCHAR(50)           DEFAULT NULL   COMMENT '采样器，如 DPM++ 2M Karras',
  `steps`           INT          NOT NULL DEFAULT 25     COMMENT '采样步数',
  `cfg_scale`       DECIMAL(4,1) NOT NULL DEFAULT 7.0    COMMENT '提示词引导强度',
  `width`           INT          NOT NULL DEFAULT 1024   COMMENT '默认宽',
  `height`          INT          NOT NULL DEFAULT 1024   COMMENT '默认高',
  -- ↓ 提示词模板：拼接在用户输入前后，保证风格稳定
  `prompt_prefix`   VARCHAR(500)          DEFAULT NULL   COMMENT '提示词前缀，如 masterpiece, best quality',
  `prompt_suffix`   VARCHAR(500)          DEFAULT NULL   COMMENT '提示词后缀',
  `negative_prompt` VARCHAR(500)          DEFAULT NULL   COMMENT '默认负面提示词',
  `params_json`     JSON                  DEFAULT NULL   COMMENT '扩展参数，新增参数无需改表结构',
  `usage_count`     INT          NOT NULL DEFAULT 0      COMMENT '被使用次数，用于市场排序',
  `favorite_count`  INT          NOT NULL DEFAULT 0      COMMENT '被收藏次数',
  `sort_order`      INT          NOT NULL DEFAULT 0      COMMENT '排序权重',
  `status`          TINYINT      NOT NULL DEFAULT 1      COMMENT '1启用 0下线',
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_type_status` (`type`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Skill创作线路配置表';
```

### 3. t_ai_task AI 任务表（Harness 核心）

```sql
CREATE TABLE `t_ai_task` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '任务ID',
  `task_no`         VARCHAR(64)  NOT NULL                COMMENT '任务编号（UUID），对外暴露用',
  `user_id`         BIGINT       NOT NULL                COMMENT '所属用户',
  `type`            VARCHAR(20)  NOT NULL                COMMENT '任务类型：TEXT_TO_IMAGE / IMAGE_TO_VIDEO',
  `skill_id`        BIGINT                DEFAULT NULL   COMMENT '使用的Skill线路',
  -- ↓ 输入参数（创建任务时快照，Skill 后续被改不影响历史任务）
  `prompt`          TEXT                  DEFAULT NULL   COMMENT '用户输入的提示词',
  `negative_prompt` TEXT                  DEFAULT NULL   COMMENT '负面提示词',
  `ref_image_url`   VARCHAR(255)          DEFAULT NULL   COMMENT '参考图/首帧图URL（图生视频必填）',
  `params_json`     JSON                  DEFAULT NULL   COMMENT '完整生成参数快照',
  -- ↓ Harness 调度状态
  `status`          VARCHAR(20)  NOT NULL DEFAULT 'QUEUED' COMMENT 'QUEUED/RUNNING/SUCCESS/FAILED/CANCELED',
  `progress`        INT          NOT NULL DEFAULT 0      COMMENT '进度 0-100',
  `queue_at`        DATETIME              DEFAULT NULL   COMMENT '入队时间',
  `start_at`        DATETIME              DEFAULT NULL   COMMENT '开始生成时间',
  `finish_at`       DATETIME              DEFAULT NULL   COMMENT '结束时间',
  `duration_ms`     BIGINT                DEFAULT NULL   COMMENT '总耗时（毫秒）',
  -- ↓ 结果
  `result_url`      VARCHAR(255)          DEFAULT NULL   COMMENT '主结果URL',
  `result_thumb`    VARCHAR(255)          DEFAULT NULL   COMMENT '结果缩略图',
  `result_json`     JSON                  DEFAULT NULL   COMMENT '多结果/视频元信息',
  `error_msg`       VARCHAR(1000)         DEFAULT NULL   COMMENT '失败原因，直接展示给用户',
  -- ↓ 服务商解耦（MCP 思想）
  `provider`        VARCHAR(50)           DEFAULT NULL   COMMENT '实际调用的服务商',
  `provider_task_id` VARCHAR(128)         DEFAULT NULL   COMMENT '服务商侧任务ID，用于回查',
  -- ↓ 重试
  `retry_count`     INT          NOT NULL DEFAULT 0      COMMENT '已重试次数',
  `max_retry`       INT          NOT NULL DEFAULT 3      COMMENT '最大重试次数',
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_no` (`task_no`),
  KEY `idx_user_status` (`user_id`, `status`),
  KEY `idx_status_queue` (`status`, `queue_at`),
  KEY `idx_provider_task` (`provider`, `provider_task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI生成任务表';
```

> `idx_status_queue` 是给调度器用的：轮询器每秒执行
> `SELECT * FROM t_ai_task WHERE status='QUEUED' ORDER BY queue_at LIMIT 10`，
> 这个联合索引让扫描走索引而不是全表。

### 4. t_material 素材表

```sql
CREATE TABLE `t_material` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '素材ID',
  `user_id`     BIGINT       NOT NULL                COMMENT '所属用户',
  `name`        VARCHAR(100) NOT NULL                COMMENT '素材名称',
  `url`         VARCHAR(255) NOT NULL                COMMENT '原图URL',
  `thumb_url`   VARCHAR(255)          DEFAULT NULL   COMMENT '缩略图URL',
  `file_size`   BIGINT                DEFAULT NULL   COMMENT '文件大小（字节）',
  `width`       INT                   DEFAULT NULL   COMMENT '宽',
  `height`      INT                   DEFAULT NULL   COMMENT '高',
  `mime_type`   VARCHAR(50)           DEFAULT NULL   COMMENT 'MIME类型',
  `source`      VARCHAR(20)  NOT NULL DEFAULT 'UPLOAD' COMMENT '来源：UPLOAD/CAMERA/GENERATED',
  `group_name`  VARCHAR(50)           DEFAULT NULL   COMMENT '分组名',
  `tags`        VARCHAR(255)          DEFAULT NULL   COMMENT '标签，逗号分隔',
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`     TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_user_deleted` (`user_id`, `deleted`),
  KEY `idx_group` (`user_id`, `group_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='素材库表';
```

### 5. t_prompt Prompt 知识库表

```sql
CREATE TABLE `t_prompt` (
  `id`               BIGINT       NOT NULL AUTO_INCREMENT COMMENT '提示词ID',
  `user_id`          BIGINT                DEFAULT NULL   COMMENT '投稿者，NULL表示官方内置',
  `title`            VARCHAR(100) NOT NULL                COMMENT '标题，用于列表展示',
  `content`          TEXT         NOT NULL                COMMENT '提示词正文',
  `negative_content` TEXT                  DEFAULT NULL   COMMENT '配套负面提示词',
  `category`         VARCHAR(50)           DEFAULT NULL   COMMENT '分类：人物/风景/电商/二次元/建筑',
  `tags`             VARCHAR(255)          DEFAULT NULL   COMMENT '标签，逗号分隔，用于检索',
  `cover_url`        VARCHAR(255)          DEFAULT NULL   COMMENT '效果预览图',
  `favorite_count`   INT          NOT NULL DEFAULT 0      COMMENT '收藏数',
  `use_count`        INT          NOT NULL DEFAULT 0      COMMENT '被使用次数',
  `is_public`        TINYINT      NOT NULL DEFAULT 1      COMMENT '1公开 0私有',
  `status`           TINYINT      NOT NULL DEFAULT 1      COMMENT '1正常 0下架',
  `created_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`          TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_category` (`category`, `status`),
  KEY `idx_user` (`user_id`),
  -- 全文索引：知识库检索的核心
  FULLTEXT KEY `ft_title_content` (`title`, `content`) WITH PARSER ngram
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Prompt知识库表';
```

> `WITH PARSER ngram` 是关键：MySQL 默认全文索引按空格分词，**对中文无效**。
> ngram 分词器按 2-3 字滑窗切分，中文检索才能正常工作。
> 若不想用全文索引，退化为 `title LIKE '%kw%' OR content LIKE '%kw%'` 也能过课设，
> 但数据量上千后性能会明显下降。

### 6. t_prompt_favorite 提示词收藏关联表

```sql
CREATE TABLE `t_prompt_favorite` (
  `id`         BIGINT   NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT   NOT NULL COMMENT '用户ID',
  `prompt_id`  BIGINT   NOT NULL COMMENT '提示词ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  -- 唯一索引：防止重复收藏，同时天然支持「我是否已收藏」的快速查询
  UNIQUE KEY `uk_user_prompt` (`user_id`, `prompt_id`),
  KEY `idx_prompt` (`prompt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='提示词收藏关联表';
```

### 7. t_work 作品表

```sql
CREATE TABLE `t_work` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '作品ID',
  `user_id`         BIGINT       NOT NULL                COMMENT '作者',
  `task_id`         BIGINT                DEFAULT NULL   COMMENT '来源任务',
  `title`           VARCHAR(100)          DEFAULT NULL   COMMENT '作品标题',
  `type`            VARCHAR(20)  NOT NULL                COMMENT 'IMAGE / VIDEO',
  `cover_url`       VARCHAR(255)          DEFAULT NULL   COMMENT '封面（视频取首帧）',
  `resource_url`    VARCHAR(255) NOT NULL                COMMENT '作品资源URL',
  `prompt`          TEXT                  DEFAULT NULL   COMMENT '生成用的提示词（详情页回显）',
  `negative_prompt` TEXT                  DEFAULT NULL   COMMENT '负面提示词',
  `skill_id`        BIGINT                DEFAULT NULL   COMMENT '使用的Skill线路',
  `params_json`     JSON                  DEFAULT NULL   COMMENT '生成参数',
  `width`           INT                   DEFAULT NULL,
  `height`          INT                   DEFAULT NULL,
  `duration`        INT                   DEFAULT NULL   COMMENT '视频时长（秒）',
  `is_public`       TINYINT      NOT NULL DEFAULT 0      COMMENT '1发布到公开画廊 0仅自己可见',
  `like_count`      INT          NOT NULL DEFAULT 0,
  `view_count`      INT          NOT NULL DEFAULT 0,
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_user_type` (`user_id`, `type`, `deleted`),
  KEY `idx_public_created` (`is_public`, `created_at`),
  KEY `idx_task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='作品表';
```

---

## 三、Harness 任务状态机

需求原文：**排队 → 生成中 → 成功 / 失败，支持失败重试**。

```
                    ┌──────────────────────────────┐
                    │                              │ 重试（retry_count < max_retry）
                    ▼                              │
              ┌──────────┐   调度器取任务    ┌──────────┐
   创建任务 ──▶│ QUEUED   │─────────────────▶│ RUNNING  │
              │  排队中  │                  │ 生成中   │
              └──────────┘                  └──────────┘
                    │                        │       │
                    │ 用户取消                │       │ 服务商返回失败
                    ▼                        ▼       ▼
              ┌──────────┐            ┌──────────┐  ┌──────────┐
              │ CANCELED │            │ SUCCESS  │  │  FAILED  │
              │ 已取消   │            │  成功    │  │  失败    │
              └──────────┘            └──────────┘  └──────────┘
                                                         │
                                              重试次数用尽 └──▶ 终态，展示 error_msg
```

合法迁移：

| 起点 | 终点 | 触发者 |
|------|------|--------|
| `QUEUED` | `RUNNING` | 调度器（轮询取任务） |
| `QUEUED` | `CANCELED` | 用户主动取消 |
| `RUNNING` | `SUCCESS` | 服务商回调 / 轮询查到完成 |
| `RUNNING` | `FAILED` | 服务商报错 / 超时 |
| `FAILED` | `QUEUED` | 用户点「重试」，`retry_count + 1` |

**终态**：`SUCCESS` / `CANCELED`，以及 `FAILED && retry_count >= max_retry`。

### 调度器（Scheduled 轮询）

后端起一个 `@Scheduled(fixedDelay = 3000)` 的轮询器：

1. 捞 `status='QUEUED'` 且 `retry_count < max_retry` 的任务，按 `queue_at` 排序取一批；
2. 用**乐观锁**抢占，防多线程/多实例重复消费：
   ```sql
   UPDATE t_ai_task SET status='RUNNING', start_at=NOW(), version=version+1
   WHERE id=? AND status='QUEUED';   -- 影响行数为 0 说明被别人抢走了
   ```
3. 查 Skill 线路 → 拼最终提示词 → 交给 `AiProvider` 实现类执行；
4. 写回 `SUCCESS`/`FAILED` + `result_url`/`error_msg` + `finish_at`/`duration_ms`；
5. 任务成功则同时往 `t_work` 插一条作品记录。

> 表里建议再加一列 `version INT NOT NULL DEFAULT 0` 配合上面的乐观锁，
> MySQL 也能直接用 `@Version` 注解（JPA）或手写 SQL。

---

## 四、AI 服务商解耦（MCP 思想）

需求原文：**封装 AI 服务商调用接口，解耦，预留动态切换不同模型后端的能力；
不需要完整实现 MCP 底层协议，但架构上要做到可扩展。**

核心是**三个解耦点**：

```
                    ┌─────────────────────────────────────────┐
                    │   HarnessTaskScheduler（只管调度）        │
                    │   不知道任何具体服务商                     │
                    └───────────────────┬─────────────────────┘
                                        │ 依赖接口，不依赖实现
                                        ▼
                    ┌─────────────────────────────────────────┐
                    │      AiProvider（接口，MCP 的雏形）       │
                    │  + getName() / supports(Skill)          │
                    │  + submit(AiTaskRequest): AiTaskResult   │
                    │  + query(providerTaskId): AiTaskResult   │
                    │  + cancel(providerTaskId)                │
                    └───────────────────┬─────────────────────┘
                                        │
              ┌──────────────┬──────────┴───────┬──────────────────┐
              ▼              ▼                  ▼                  ▼
      MockAiProvider   StableDiffusion    OpenAIProvider     (未来扩展)
      （课设默认，      Provider           （DALL·E）
        本地出图）        （自建/云端 SD）
```

三个解耦点：

1. **接口解耦**：调度器只依赖 `AiProvider` 接口，新增服务商 = 新增一个实现类 + 注册，**不动调度代码**。
2. **配置解耦**：选哪个服务商由 `t_skill.provider` 字段决定，**改数据库即可切换，不改代码、不重新打包**。
3. **参数解耦**：`AiTaskRequest` 用统一的参数载体（prompt / negativePrompt / width / height / extraParams），
   各 Provider 内部自己做参数翻译（比如 SD 要 steps/cfg，DALL·E 只要 size），
   调用方不需要为每个服务商写不同逻辑。

Spring 里用 `Map<String, AiProvider>` 注入，Spring 会按 bean 名字自动装配：

```java
@Service
public class AiProviderRouter {
    private final Map<String, AiProvider> providers;   // beanName -> 实现

    public AiProviderRouter(Map<String, AiProvider> providers) {
        this.providers = providers;
    }

    /** 按 Skill 配置的 provider 字段路由；找不到就兜底到 mock，保证课设演示永远能跑通。 */
    public AiProvider route(String providerName) {
        AiProvider provider = providers.get(providerName);
        if (provider == null) {
            // 服务商不可用时降级，而不是直接让任务失败
            return providers.getOrDefault("mockAiProvider", providers.values().iterator().next());
        }
        return provider;
    }
}
```

接口预留了 `query()` 和 `providerTaskId` 字段，是为了支持**异步服务商**
（提交后返回一个 ID，之后轮询查进度）—— 这正是 Harness 需要的能力。
课设阶段 `MockAiProvider` 可以本地生成图片，保证演示不依赖外部付费 API。

---

## 五、实体类映射

JPA 实体与表的对应关系（`@TableName` 是 MyBatis-Plus 写法，二选一）：

| 实体类 | 表 | 关键注解 / 字段说明 |
|--------|-----|-------------------|
| `User` | `t_user` | `@TableLogic` 标记 `deleted` 逻辑删除；`password` 用 `@JsonIgnore` 防止序列化泄露 |
| `Skill` | `t_skill` | `paramsJson` 用 `@TableField(typeHandler = JacksonTypeHandler.class)` 映射 JSON 列 |
| `AiTask` | `t_ai_task` | `status` 用枚举 `TaskStatus`；`@Version` 乐观锁；`paramsJson`/`resultJson` 同上 |
| `Material` | `t_material` | `@TableLogic` 逻辑删除 |
| `Prompt` | `t_prompt` | `@TableLogic`；`tags` 冗余存储便于检索 |
| `PromptFavorite` | `t_prompt_favorite` | 联合唯一索引 `uk_user_prompt` |
| `Work` | `t_work` | `@TableLogic`；`isPublic` 控制画廊可见性 |

### 状态枚举

```java
public enum TaskStatus {
    QUEUED("排队中"),
    RUNNING("生成中"),
    SUCCESS("成功"),
    FAILED("失败"),
    CANCELED("已取消");

    private final String label;
    TaskStatus(String label) { this.label = label; }
    public String getLabel() { return label; }

    /** 是否终态：终态任务不再被调度器拾取 */
    public boolean isTerminal() {
        return this == SUCCESS || this == CANCELED || this == FAILED;
    }
}
```

> 这个枚举与前端 `AppColors` 里的四个状态语义色一一对应：
> `QUEUED` → `statusQueued`(灰) / `RUNNING` → `statusRunning`(蓝) /
> `SUCCESS` → `statusSuccess`(绿) / `FAILED` → `statusFailed`(红) / `CANCELED` → `statusCanceled`(浅灰)。
> 前端 `StatusChip` 组件已按这套颜色实现，两端的视觉语言保持一致。

---

## 六、初始化数据建议

课设演示前至少准备：

```sql
-- 演示账号（密码明文 demo123，入库前用 BCrypt 加密）
INSERT INTO t_user (username, password, nickname, role, credits) VALUES
('demo', '$2a$10$...BCrypt...', '课设演示账号', 'USER', 200);

-- 至少 5 条 Skill 线路，覆盖两个任务类型
INSERT INTO t_skill (code, name, type, scene, provider, model_name, steps, cfg_scale, prompt_prefix) VALUES
('anime_v1',   '二次元插画', 'TEXT_TO_IMAGE',  '头像 / 立绘',   'mock', 'sd-xl-anime',   28, 7.5, 'masterpiece, best quality, anime style'),
('realistic_v1','写实摄影',  'TEXT_TO_IMAGE',  '人像 / 风景',   'mock', 'sd-xl-real',    30, 6.5, 'photorealistic, 8k, sharp focus'),
('ecommerce_v1','电商海报',  'TEXT_TO_IMAGE',  '商品主图',      'mock', 'sd-xl-product', 25, 7.0, 'product photography, clean background'),
('guofeng_v1', '国风水墨',   'TEXT_TO_IMAGE',  '国潮 / 文创',   'mock', 'sd-xl-ink',     26, 7.0, 'chinese ink painting, traditional'),
('motion_v1',  '短视频运镜', 'IMAGE_TO_VIDEO', '产品展示 / 转场','mock', 'svd-xt',        20, 6.0, NULL);

-- 若干条 Prompt 知识库数据
INSERT INTO t_prompt (title, content, category, tags) VALUES
('赛博朋克城市夜景', 'cyberpunk city at night, neon lights, rainy street, reflections', '风景', '赛博朋克,夜景');
```

> `MockAiProvider` 建议实现为：本地生成一张带提示词文字的占位图（或从内置图库随机取），
> 并 `Thread.sleep(3~8秒)` 模拟生成耗时 —— 这样 Harness 的
> 「排队 → 生成中 → 成功」状态流转在答辩演示时**肉眼可见**，
> 比瞬间返回更有说服力，也不依赖任何外部付费 API。
