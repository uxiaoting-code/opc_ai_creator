-- =============================================================================
--  OPC AI 多模态创作平台 · MySQL 8.0 建库建表脚本
-- -----------------------------------------------------------------------------
--  来源：docs/DATABASE.md 的表设计
--  校准基准：server/src/main/java/com/opc/server/entity/*.java（实体类是运行时的
--            真实契约，凡文档与实体冲突处一律以实体为准，差异见文件末尾「修订说明」）
--
--  数据库：ai_image_video（已手动建好，下面的 CREATE DATABASE 是幂等兜底，可忽略）
--
--  执行方式（PowerShell 里 mysql 客户端不支持 `<` 重定向，所以用 source）：
--      mysql -u root -p --default-character-set=utf8mb4
--      mysql> source E:/code_project/opc_ai_creator/server/docs/schema.sql
--
--  注意：本脚本只建表，不插入业务数据。
--        演示账号 / Skill 线路 / Prompt 数据由后端启动时 DataSeeder 自动写入
--        （密码哈希必须在运行期用 PBKDF2 现算，手写 INSERT 无法伪造，见文末说明）。
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `ai_image_video`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_general_ci;

USE `ai_image_video`;


-- =============================================================================
--  可选：重建库表（首次建库时不要执行；确认要清空重来再取消注释）
-- =============================================================================
-- DROP TABLE IF EXISTS `t_prompt_favorite`;
-- DROP TABLE IF EXISTS `t_work`;
-- DROP TABLE IF EXISTS `t_ai_task`;
-- DROP TABLE IF EXISTS `t_material`;
-- DROP TABLE IF EXISTS `t_prompt`;
-- DROP TABLE IF EXISTS `t_skill`;
-- DROP TABLE IF EXISTS `t_user`;


-- =============================================================================
--  1. t_user 用户表
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_user` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username`   VARCHAR(50)  NOT NULL                COMMENT '登录账号，唯一',
  `password`   VARCHAR(200) NOT NULL                COMMENT '密码哈希（PBKDF2，格式 迭代次数$盐$哈希，禁止明文）',
  `nickname`   VARCHAR(50)           DEFAULT NULL   COMMENT '昵称，为空时回退到 username',
  `avatar`     VARCHAR(255)          DEFAULT NULL   COMMENT '头像URL',
  `email`      VARCHAR(100)          DEFAULT NULL   COMMENT '邮箱',
  `phone`      VARCHAR(20)           DEFAULT NULL   COMMENT '手机号',
  `role`       VARCHAR(20)  NOT NULL DEFAULT 'USER' COMMENT '角色：USER / ADMIN',
  `credits`    INT          NOT NULL DEFAULT 200    COMMENT '剩余算力点，创建任务时扣减',
  `status`     TINYINT      NOT NULL DEFAULT 1      COMMENT '状态：1正常 0禁用',
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted`    TINYINT      NOT NULL DEFAULT 0      COMMENT '逻辑删除：0未删 1已删',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='用户表';


-- =============================================================================
--  2. t_skill Skill 线路配置表
--     一条记录 = 一整套生成参数模板。新增线路只需插一行，
--     前后端都不改代码、不重新打包（「多线路」需求的载体）。
--     provider 字段决定这条线路由哪个 AiProvider 实现类执行（MCP 解耦点）。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_skill` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT COMMENT '线路ID',
  `code`            VARCHAR(50)  NOT NULL                COMMENT '线路编码，如 anime_v1',
  `name`            VARCHAR(50)  NOT NULL                COMMENT '线路名称，如 二次元插画',
  `type`            VARCHAR(20)  NOT NULL                COMMENT '适用类型：TEXT_TO_IMAGE / IMAGE_TO_VIDEO',
  `cover_url`       VARCHAR(255)          DEFAULT NULL   COMMENT '封面示例图',
  `description`     VARCHAR(500)          DEFAULT NULL   COMMENT '线路说明',
  `scene`           VARCHAR(100)          DEFAULT NULL   COMMENT '适用场景，如 头像/海报/短视频',
  `provider`        VARCHAR(50)  NOT NULL DEFAULT 'mock' COMMENT 'AI服务商标识，决定路由到哪个 Provider 实现',
  `model_name`      VARCHAR(100)          DEFAULT NULL   COMMENT '模型名，如 sd-xl-anime',
  `sampler`         VARCHAR(50)           DEFAULT NULL   COMMENT '采样器，如 DPM++ 2M Karras',
  `steps`           INT          NOT NULL DEFAULT 25     COMMENT '采样步数',
  `cfg_scale`       DECIMAL(4,1) NOT NULL DEFAULT 7.0    COMMENT '提示词引导强度',
  `width`           INT          NOT NULL DEFAULT 1024   COMMENT '默认宽',
  `height`          INT          NOT NULL DEFAULT 1024   COMMENT '默认高',
  `prompt_prefix`   VARCHAR(500)          DEFAULT NULL   COMMENT '提示词前缀，如 masterpiece, best quality',
  `prompt_suffix`   VARCHAR(500)          DEFAULT NULL   COMMENT '提示词后缀',
  `negative_prompt` VARCHAR(500)          DEFAULT NULL   COMMENT '默认负面提示词',
  `params_json`     VARCHAR(4000)         DEFAULT NULL   COMMENT '扩展参数JSON，新增参数无需改表结构',
  `usage_count`     INT          NOT NULL DEFAULT 0      COMMENT '被使用次数，用于市场排序',
  `favorite_count`  INT          NOT NULL DEFAULT 0      COMMENT '被收藏次数',
  `sort_order`      INT          NOT NULL DEFAULT 0      COMMENT '排序权重',
  `status`          TINYINT      NOT NULL DEFAULT 1      COMMENT '1启用 0下线',
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_type_status` (`type`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Skill创作线路配置表';


-- =============================================================================
--  3. t_ai_task AI 任务表（Harness 调度核心）
--     并发安全靠 idx_status_queue 联合索引 + 调度器的原子条件 UPDATE，
--     所以不需要 version 乐观锁列（见文末修订说明第 3 条）。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_ai_task` (
  `id`               BIGINT        NOT NULL AUTO_INCREMENT COMMENT '任务ID',
  `task_no`          VARCHAR(64)   NOT NULL                COMMENT '任务编号（UUID），对外暴露用',
  `user_id`          BIGINT        NOT NULL                COMMENT '所属用户',
  `type`             VARCHAR(20)   NOT NULL                COMMENT '任务类型：TEXT_TO_IMAGE / IMAGE_TO_VIDEO',
  `skill_id`         BIGINT                 DEFAULT NULL   COMMENT '使用的Skill线路',
  `prompt`           VARCHAR(2000)          DEFAULT NULL   COMMENT '最终提示词（已拼上线路的风格前缀/后缀）',
  `negative_prompt`  VARCHAR(1000)          DEFAULT NULL   COMMENT '负面提示词',
  `ref_image_url`    VARCHAR(255)           DEFAULT NULL   COMMENT '参考图/首帧图URL（图生视频必填）',
  `params_json`      VARCHAR(4000)          DEFAULT NULL   COMMENT '完整生成参数快照',
  `status`           VARCHAR(20)   NOT NULL DEFAULT 'QUEUED' COMMENT 'QUEUED/RUNNING/SUCCESS/FAILED/CANCELED',
  `progress`         INT           NOT NULL DEFAULT 0      COMMENT '进度 0-100',
  `queue_at`         DATETIME               DEFAULT NULL   COMMENT '入队时间',
  `start_at`         DATETIME               DEFAULT NULL   COMMENT '开始生成时间',
  `finish_at`        DATETIME               DEFAULT NULL   COMMENT '结束时间',
  `duration_ms`      BIGINT                 DEFAULT NULL   COMMENT '总耗时（毫秒）',
  `result_url`       VARCHAR(255)           DEFAULT NULL   COMMENT '主结果URL',
  `result_thumb`     VARCHAR(255)           DEFAULT NULL   COMMENT '结果缩略图',
  `result_json`      VARCHAR(4000)          DEFAULT NULL   COMMENT '多结果/视频元信息',
  `error_msg`        VARCHAR(1000)          DEFAULT NULL   COMMENT '失败原因，直接展示给用户',
  `provider`         VARCHAR(50)            DEFAULT NULL   COMMENT '实际调用的服务商',
  `provider_task_id` VARCHAR(128)           DEFAULT NULL   COMMENT '服务商侧任务ID，用于回查',
  `retry_count`      INT           NOT NULL DEFAULT 0      COMMENT '已重试次数',
  `max_retry`        INT           NOT NULL DEFAULT 3      COMMENT '最大重试次数',
  `created_at`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`          TINYINT       NOT NULL DEFAULT 0      COMMENT '逻辑删除：0未删 1已删',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_no` (`task_no`),
  KEY `idx_user_status` (`user_id`, `status`),
  -- 调度器每秒执行：WHERE status='QUEUED' ORDER BY queue_at LIMIT n
  -- 这个联合索引让扫描走索引而不是全表
  KEY `idx_status_queue` (`status`, `queue_at`),
  KEY `idx_provider_task` (`provider`, `provider_task_id`),
  KEY `idx_skill` (`skill_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='AI生成任务表';


-- =============================================================================
--  4. t_material 素材表
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_material` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '素材ID',
  `user_id`    BIGINT       NOT NULL                COMMENT '所属用户',
  `name`       VARCHAR(100) NOT NULL                COMMENT '素材名称',
  `url`        VARCHAR(255) NOT NULL                COMMENT '原图URL',
  `thumb_url`  VARCHAR(255)          DEFAULT NULL   COMMENT '缩略图URL',
  `file_size`  BIGINT                DEFAULT NULL   COMMENT '文件大小（字节）',
  `width`      INT                   DEFAULT NULL   COMMENT '宽',
  `height`     INT                   DEFAULT NULL   COMMENT '高',
  `mime_type`  VARCHAR(50)           DEFAULT NULL   COMMENT 'MIME类型',
  `source`     VARCHAR(20)  NOT NULL DEFAULT 'UPLOAD' COMMENT '来源：UPLOAD/CAMERA/GENERATED',
  `group_name` VARCHAR(50)           DEFAULT NULL   COMMENT '分组名',
  `tags`       VARCHAR(255)          DEFAULT NULL   COMMENT '标签，逗号分隔',
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`    TINYINT      NOT NULL DEFAULT 0      COMMENT '逻辑删除：0未删 1已删',
  PRIMARY KEY (`id`),
  KEY `idx_user_deleted` (`user_id`, `deleted`),
  KEY `idx_group` (`user_id`, `group_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='素材库表';


-- =============================================================================
--  5. t_prompt Prompt 知识库表
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_prompt` (
  `id`               BIGINT        NOT NULL AUTO_INCREMENT COMMENT '提示词ID',
  `user_id`          BIGINT                 DEFAULT NULL   COMMENT '投稿者，NULL表示官方内置',
  `title`            VARCHAR(100)  NOT NULL                COMMENT '标题，用于列表展示',
  `content`          VARCHAR(4000) NOT NULL                COMMENT '提示词正文',
  `negative_content` VARCHAR(2000)          DEFAULT NULL   COMMENT '配套负面提示词',
  `category`         VARCHAR(50)            DEFAULT NULL   COMMENT '分类：人物/风景/电商/二次元/建筑',
  `tags`             VARCHAR(255)           DEFAULT NULL   COMMENT '标签，逗号分隔，用于检索',
  `cover_url`        VARCHAR(255)           DEFAULT NULL   COMMENT '效果预览图',
  `favorite_count`   INT           NOT NULL DEFAULT 0      COMMENT '收藏数',
  `use_count`        INT           NOT NULL DEFAULT 0      COMMENT '被使用次数',
  `is_public`        TINYINT       NOT NULL DEFAULT 1      COMMENT '1公开 0私有',
  `status`           TINYINT       NOT NULL DEFAULT 1      COMMENT '1正常 0下架',
  `created_at`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`          TINYINT       NOT NULL DEFAULT 0      COMMENT '逻辑删除：0未删 1已删',
  PRIMARY KEY (`id`),
  KEY `idx_category` (`category`, `status`),
  KEY `idx_user` (`user_id`),
  -- 全文索引：知识库检索的核心。
  -- MySQL 默认全文索引按空格分词，对中文无效；ngram 分词器按 2-3 字滑窗切分，
  -- 中文检索才能正常工作。若你的库是 MariaDB（无 ngram 解析器），
  -- 请删掉下面这一行，退化为 LIKE '%kw%' 查询。
  FULLTEXT KEY `ft_title_content` (`title`, `content`) WITH PARSER ngram
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Prompt知识库表';


-- =============================================================================
--  6. t_prompt_favorite 提示词收藏关联表
--     用户与提示词多对多，必须有中间表。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_prompt_favorite` (
  `id`         BIGINT   NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT   NOT NULL COMMENT '用户ID',
  `prompt_id`  BIGINT   NOT NULL COMMENT '提示词ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  -- 实体 PromptFavorite 继承 BaseEntity，插入时 JPA 会带上 updated_at，缺列直接报错
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  -- 唯一索引：防止重复收藏，同时天然支持「我是否已收藏」的快速查询
  UNIQUE KEY `uk_user_prompt` (`user_id`, `prompt_id`),
  KEY `idx_prompt` (`prompt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='提示词收藏关联表';


-- =============================================================================
--  7. t_work 作品表
--     任务表存「执行过程」（可删可重试），作品表存「用户可见的成果」（要长期保留）。
--     任务成功时由 Harness 自动落一条记录。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_work` (
  `id`              BIGINT        NOT NULL AUTO_INCREMENT COMMENT '作品ID',
  `user_id`         BIGINT        NOT NULL                COMMENT '作者',
  `task_id`         BIGINT                 DEFAULT NULL   COMMENT '来源任务',
  `title`           VARCHAR(100)           DEFAULT NULL   COMMENT '作品标题',
  `type`            VARCHAR(20)   NOT NULL                COMMENT 'IMAGE / VIDEO',
  `cover_url`       VARCHAR(255)           DEFAULT NULL   COMMENT '封面（视频取首帧）',
  `resource_url`    VARCHAR(255)  NOT NULL                COMMENT '作品资源URL',
  `prompt`          VARCHAR(2000)          DEFAULT NULL   COMMENT '生成用的提示词（详情页回显）',
  `negative_prompt` VARCHAR(1000)          DEFAULT NULL   COMMENT '负面提示词',
  `skill_id`        BIGINT                 DEFAULT NULL   COMMENT '使用的Skill线路',
  `params_json`     VARCHAR(4000)          DEFAULT NULL   COMMENT '生成参数',
  `width`           INT                    DEFAULT NULL,
  `height`          INT                    DEFAULT NULL,
  `duration`        INT                    DEFAULT NULL   COMMENT '视频时长（秒）',
  `is_public`       TINYINT       NOT NULL DEFAULT 0      COMMENT '1发布到公开画廊 0仅自己可见',
  `like_count`      INT           NOT NULL DEFAULT 0      COMMENT '点赞数',
  `view_count`      INT           NOT NULL DEFAULT 0      COMMENT '浏览数',
  `created_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         TINYINT       NOT NULL DEFAULT 0      COMMENT '逻辑删除：0未删 1已删',
  PRIMARY KEY (`id`),
  KEY `idx_user_type` (`user_id`, `type`, `deleted`),
  KEY `idx_public_created` (`is_public`, `created_at`),
  KEY `idx_task` (`task_id`),
  KEY `idx_skill` (`skill_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='作品表';


-- =============================================================================
--  可选：外键完整性约束
-- -----------------------------------------------------------------------------
--  默认不启用，原因：
--   1) 实体层没有任何 @ManyToOne 关联，全部按「应用层维护关联」设计，
--      这也是《阿里巴巴 Java 开发手册》的强制约定（不得使用外键与级联）；
--   2) 加外键后，日后清库、造测试数据都要按依赖顺序来，调试更麻烦。
--  若课程评分表里明确要求「外键完整性约束」，再逐条取消注释执行即可。
-- =============================================================================
-- ALTER TABLE `t_ai_task`         ADD CONSTRAINT `fk_task_user`     FOREIGN KEY (`user_id`)   REFERENCES `t_user` (`id`);
-- ALTER TABLE `t_ai_task`         ADD CONSTRAINT `fk_task_skill`    FOREIGN KEY (`skill_id`)  REFERENCES `t_skill` (`id`);
-- ALTER TABLE `t_material`        ADD CONSTRAINT `fk_material_user` FOREIGN KEY (`user_id`)   REFERENCES `t_user` (`id`);
-- ALTER TABLE `t_prompt`          ADD CONSTRAINT `fk_prompt_user`   FOREIGN KEY (`user_id`)   REFERENCES `t_user` (`id`);
-- ALTER TABLE `t_prompt_favorite` ADD CONSTRAINT `fk_fav_user`      FOREIGN KEY (`user_id`)   REFERENCES `t_user` (`id`);
-- ALTER TABLE `t_prompt_favorite` ADD CONSTRAINT `fk_fav_prompt`    FOREIGN KEY (`prompt_id`) REFERENCES `t_prompt` (`id`);
-- ALTER TABLE `t_work`            ADD CONSTRAINT `fk_work_user`     FOREIGN KEY (`user_id`)   REFERENCES `t_user` (`id`);
-- ALTER TABLE `t_work`            ADD CONSTRAINT `fk_work_task`     FOREIGN KEY (`task_id`)   REFERENCES `t_ai_task` (`id`);
-- ALTER TABLE `t_work`            ADD CONSTRAINT `fk_work_skill`    FOREIGN KEY (`skill_id`)  REFERENCES `t_skill` (`id`);


-- =============================================================================
--  校验：执行完后确认 7 张表都在
-- =============================================================================
-- SHOW TABLES;
-- SELECT TABLE_NAME, TABLE_COMMENT FROM information_schema.TABLES
--  WHERE TABLE_SCHEMA = 'ai_image_video';


-- =============================================================================
--  修订说明：本脚本相对 docs/DATABASE.md 的 4 处修改
-- -----------------------------------------------------------------------------
--  1) t_prompt_favorite 补上 `updated_at` 列。
--     ★ 这是会让程序直接跑不起来的坑：实体 PromptFavorite 继承 BaseEntity，
--       插入时 JPA 一定会写 created_at 和 updated_at 两列，
--       文档里的建表语句缺 updated_at，第一条收藏落库就会
--       「Unknown column 'updated_at'」报错。
--
--  2) t_user.password 由 VARCHAR(100) 放宽到 VARCHAR(200)。
--     实体 User 声明的是 length=200。当前 PBKDF2 哈希约 76 字符，
--     100 也放得下，但两边保持一致更安全（改迭代次数/密钥长度后不会溢出）。
--
--  3) 不加 `version` 乐观锁列。
--     DATABASE.md 第三节末尾建议加，但那是代码写出来之前的设想 ——
--     实际实现走的是 AiTaskRepository.claim() 的条件原子 UPDATE
--     （WHERE id=? AND status='QUEUED'），靠数据库行锁保证不重复消费，
--     并不使用 @Version。加一个没有任何代码读写的列只会造成困惑。
--
--  4) 文档标注为 TEXT / JSON 的列，一律按实体声明的长度建成 VARCHAR。
--     涉及：t_ai_task.prompt(2000)/negative_prompt(1000)/params_json(4000)/result_json(4000)/
--           error_msg(1000)、t_work.prompt(2000)/negative_prompt(1000)/params_json(4000)、
--           t_prompt.content(4000)/negative_content(2000)、t_skill.params_json(4000)。
--     原因：JPA 实体是按长度映射的，建表必须和实体对齐才不会有
--           「写入被截断」或「类型校验失败」的隐性偏差；
--           另外 MySQL 原生 JSON 列会强校验内容合法性，普通字符串写不进去就报错，
--           对课设演示只增加故障点、不带来收益。
-- =============================================================================
