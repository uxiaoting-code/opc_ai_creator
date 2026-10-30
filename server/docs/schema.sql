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
  `credits`    INT          NOT NULL DEFAULT 10000  COMMENT '剩余算力点，创建任务时扣减',
  `status`     TINYINT      NOT NULL DEFAULT 1      COMMENT '状态：1正常 0禁用',
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `last_active_at` DATETIME          DEFAULT NULL   COMMENT '最近活跃时间（鉴权成功时节流更新）',
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
  `title`      VARCHAR(100)          DEFAULT NULL   COMMENT '管理端展示名称',
  `url`        VARCHAR(255) NOT NULL                COMMENT '原图URL',
  `thumb_url`  VARCHAR(255)          DEFAULT NULL   COMMENT '缩略图URL',
  `file_size`  BIGINT                DEFAULT NULL   COMMENT '文件大小（字节）',
  `width`      INT                   DEFAULT NULL   COMMENT '宽',
  `height`     INT                   DEFAULT NULL   COMMENT '高',
  `mime_type`  VARCHAR(50)           DEFAULT NULL   COMMENT 'MIME类型',
  `source`     VARCHAR(20)  NOT NULL DEFAULT 'UPLOAD' COMMENT '来源：UPLOAD/CAMERA/GENERATED',
  `group_name` VARCHAR(50)           DEFAULT NULL   COMMENT '分组名',
  `category_id` BIGINT               DEFAULT NULL   COMMENT '素材分类树节点ID',
  `tags`       VARCHAR(255)          DEFAULT NULL   COMMENT '标签，逗号分隔',
  `version`    INT                   DEFAULT 1      COMMENT '当前版本号',
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`    TINYINT      NOT NULL DEFAULT 0      COMMENT '逻辑删除：0未删 1已删',
  PRIMARY KEY (`id`),
  KEY `idx_user_deleted` (`user_id`, `deleted`),
  KEY `idx_group` (`user_id`, `group_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='素材库表';

-- 素材分类树（parent_id 为空表示一级分类）
CREATE TABLE IF NOT EXISTS `t_material_category` (
  `id`         BIGINT      NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(50) NOT NULL,
  `parent_id`  BIGINT               DEFAULT NULL,
  `sort_order` INT         NOT NULL DEFAULT 0,
  `created_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`    TINYINT     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_material_category_parent` (`parent_id`, `deleted`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='素材分类树';

-- 素材多级标签（parent_id 为空表示一级标签）
CREATE TABLE IF NOT EXISTS `t_material_tag` (
  `id`         BIGINT      NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(50) NOT NULL,
  `parent_id`  BIGINT               DEFAULT NULL,
  `sort_order` INT         NOT NULL DEFAULT 0,
  `created_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`    TINYINT     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_material_tag_parent` (`parent_id`, `deleted`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='素材多级标签树';

-- 素材与标签的多对多关联
CREATE TABLE IF NOT EXISTS `t_material_tag_rel` (
  `material_id` BIGINT NOT NULL,
  `tag_id`      BIGINT NOT NULL,
  PRIMARY KEY (`material_id`, `tag_id`),
  KEY `idx_material_rel_tag` (`tag_id`),
  CONSTRAINT `fk_material_rel_material` FOREIGN KEY (`material_id`)
    REFERENCES `t_material` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_material_rel_tag` FOREIGN KEY (`tag_id`)
    REFERENCES `t_material_tag` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='素材标签关联';

-- 素材版本快照（标签 ID 使用 JSON 数组）
CREATE TABLE IF NOT EXISTS `t_material_version` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT,
  `material_id`   BIGINT       NOT NULL,
  `version_no`    INT          NOT NULL,
  `title`         VARCHAR(100) NOT NULL,
  `category_id`   BIGINT                DEFAULT NULL,
  `tag_ids_json`  VARCHAR(2000)         DEFAULT NULL,
  `file_url`      VARCHAR(255) NOT NULL,
  `thumb_url`     VARCHAR(255)          DEFAULT NULL,
  `file_size`     BIGINT                DEFAULT NULL,
  `mime_type`     VARCHAR(50)           DEFAULT NULL,
  `width`         INT                   DEFAULT NULL,
  `height`        INT                   DEFAULT NULL,
  `change_note`   VARCHAR(500)          DEFAULT NULL,
  `created_by`    BIGINT                DEFAULT NULL,
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_material_version` (`material_id`, `version_no`),
  CONSTRAINT `fk_material_version_material` FOREIGN KEY (`material_id`)
    REFERENCES `t_material` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='素材版本快照';


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
--  8. t_ai_provider_config 模型/API 配置表（管理端 P0 追加，需求 3.1）
--     与 t_skill 的关系：t_skill 是「创作线路」（面向 App 用户），
--     本表是「可接入的模型通道」（面向运营人员）。两者不是一回事，不要合并。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_ai_provider_config` (
  `id`                     BIGINT        NOT NULL AUTO_INCREMENT COMMENT '配置ID',
  `name`                   VARCHAR(100)  NOT NULL                COMMENT '模型名称，如 TT Image 2',
  `vendor`                 VARCHAR(50)            DEFAULT NULL   COMMENT '厂商，如 字节跳动',
  `type`                   VARCHAR(20)   NOT NULL               COMMENT 'CHAT/IMAGE/VIDEO/AUDIO',
  `channel`                VARCHAR(50)            DEFAULT NULL   COMMENT '渠道标识，如 DE-TT-oai-pro',
  `model_name`             VARCHAR(100)           DEFAULT NULL   COMMENT '传给服务商的模型名',
  `base_url`               VARCHAR(255)           DEFAULT NULL   COMMENT '服务地址',
  `provider_impl`          VARCHAR(50)   NOT NULL DEFAULT 'mock' COMMENT '走哪个Java实现：mock/stable-diffusion/http',
  `auth_type`              VARCHAR(20)   NOT NULL DEFAULT 'NONE' COMMENT 'NONE/API_KEY/OAUTH/CUSTOM_HEADER',
  `api_key`                VARCHAR(255)           DEFAULT NULL   COMMENT '密钥（展示时脱敏）',
  `header_name`            VARCHAR(100)           DEFAULT NULL   COMMENT '自定义头名',
  `header_value`           VARCHAR(255)           DEFAULT NULL   COMMENT '自定义头值',
  `oauth_token_url`        VARCHAR(255)           DEFAULT NULL,
  `oauth_client_id`        VARCHAR(100)           DEFAULT NULL,
  `oauth_client_secret`    VARCHAR(255)           DEFAULT NULL,
  `request_method`         VARCHAR(10)   NOT NULL DEFAULT 'POST',
  `request_path`           VARCHAR(255)           DEFAULT NULL   COMMENT '请求路径，支持 {{变量}}',
  `request_content_type`   VARCHAR(100)  NOT NULL DEFAULT 'application/json',
  `request_query_json`     VARCHAR(2000)          DEFAULT NULL,
  `request_headers_json`   VARCHAR(2000)          DEFAULT NULL,
  `request_body_json`      VARCHAR(4000)          DEFAULT NULL   COMMENT '请求体模板，含 {{prompt}} 等变量',
  `response_success_path`  VARCHAR(255)           DEFAULT NULL   COMMENT '成功判定路径，如 data.0.url',
  `response_result_url_path` VARCHAR(255)         DEFAULT NULL   COMMENT '结果地址提取路径',
  `response_thumb_path`    VARCHAR(255)           DEFAULT NULL,
  `response_error_path`    VARCHAR(255)           DEFAULT NULL   COMMENT '错误信息提取路径',
  `response_task_id_path`  VARCHAR(255)           DEFAULT NULL   COMMENT '异步任务ID路径',
  `input_price`            DECIMAL(10,4)          DEFAULT NULL,
  `output_price`           DECIMAL(10,4)          DEFAULT NULL,
  `price_unit`             VARCHAR(20)   NOT NULL DEFAULT 'TOKEN' COMMENT 'TOKEN/SECOND/CALL',
  `timeout_seconds`        INT           NOT NULL DEFAULT 180,
  `online`                 TINYINT       NOT NULL DEFAULT 0      COMMENT '1上架 0下线',
  `sort_order`             INT           NOT NULL DEFAULT 0,
  `remark`                 VARCHAR(500)           DEFAULT NULL,
  `deleted`                TINYINT       NOT NULL DEFAULT 0,
  `created_at`             DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`             DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_channel` (`channel`),
  KEY `idx_type_online` (`type`, `online`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='模型API配置表';


-- =============================================================================
--  9. t_agent 智能体表（管理端 P0 追加，需求 3.5）
--     注意：与 t_skill（App 的创作线路）是完全不同的两个概念，不要混淆、不要合并。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_agent` (
  `id`                 BIGINT       NOT NULL AUTO_INCREMENT,
  `name`               VARCHAR(100) NOT NULL               COMMENT '智能体名称',
  `code`               VARCHAR(50)  NOT NULL               COMMENT '英文标识，用于API调用',
  `category`           VARCHAR(30)  NOT NULL DEFAULT 'OTHER' COMMENT 'CUSTOMER_SERVICE/MARKETING/DESIGN/DATA_ANALYSIS/OTHER',
  `description`        VARCHAR(500)          DEFAULT NULL,
  `icon`               VARCHAR(20)           DEFAULT NULL  COMMENT 'emoji 头像',
  `model_provider_id`  BIGINT                DEFAULT NULL  COMMENT '绑定模型，指向 t_ai_provider_config.id',
  `system_prompt`      TEXT                  DEFAULT NULL,
  `greeting`           VARCHAR(500)          DEFAULT NULL  COMMENT '开场白',
  `base_cost`          DECIMAL(10,2) NOT NULL DEFAULT 0    COMMENT '单次调用基础算力',
  `max_rounds`         INT          NOT NULL DEFAULT 8,
  `timeout_seconds`    INT          NOT NULL DEFAULT 60,
  `daily_quota`        INT          NOT NULL DEFAULT 5000,
  `allow_user_skill`   TINYINT      NOT NULL DEFAULT 0,
  `log_full_conversation` TINYINT   NOT NULL DEFAULT 1,
  `status`             VARCHAR(20)  NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT/PUBLISHED/OFFLINE',
  `current_version`    INT          NOT NULL DEFAULT 1,
  `today_calls`        INT          NOT NULL DEFAULT 0     COMMENT '今日调用（可由 t_call_log 聚合，先留列便于演示）',
  `avg_elapsed_ms`     BIGINT                DEFAULT NULL,
  `success_rate`       DECIMAL(5,2)         DEFAULT NULL,
  `deleted`            TINYINT      NOT NULL DEFAULT 0,
  `created_at`         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`),
  KEY `idx_category_status` (`category`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='智能体表';


-- =============================================================================
--  10. t_agent_node 智能体节点表（工作台编排的最小单元）
--      node 不区分「内置/模型/MCP/知识库」四种类型，统一用 tool_source + tool_ref_id 定位，
--      这样工作台只需要一套渲染逻辑，新增能力来源不用改工作台。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_agent_node` (
  `id`                  BIGINT       NOT NULL AUTO_INCREMENT,
  `agent_id`            BIGINT       NOT NULL,
  `node_key`            VARCHAR(50)  NOT NULL               COMMENT '节点标识，编排内唯一，如 n1',
  `name`                VARCHAR(100) NOT NULL               COMMENT '节点显示名，如 意图识别',
  `tool_source`         VARCHAR(20)  NOT NULL               COMMENT 'MODEL/KNOWLEDGE/MCP/BUILTIN',
  `tool_ref_id`         BIGINT                DEFAULT NULL  COMMENT '对应表id，BUILTIN 为 null',
  `tool_key`            VARCHAR(100) NOT NULL               COMMENT '工具标识，见 admin-freeze.md 2.2',
  `tool_name_snapshot`  VARCHAR(100)          DEFAULT NULL  COMMENT '引用时的名称快照，防原对象被删后显示不出来',
  `params_json`         VARCHAR(4000)         DEFAULT NULL  COMMENT '节点参数',
  `enabled`             TINYINT      NOT NULL DEFAULT 1,
  `order_index`         INT          NOT NULL DEFAULT 0     COMMENT '顺序，从小到大执行',
  `route_keywords`      VARCHAR(255)          DEFAULT NULL  COMMENT '条件路由：命中这些关键词(逗号分隔)时改走目标节点',
  `route_target_key`    VARCHAR(50)           DEFAULT NULL  COMMENT '条件路由的目标 node_key',
  `created_at`          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agent_node` (`agent_id`, `node_key`),
  KEY `idx_agent_order` (`agent_id`, `order_index`),
  KEY `idx_tool` (`tool_source`, `tool_ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='智能体节点表';


-- =============================================================================
--  11. t_agent_version 智能体版本表（需求 3.5「版本保存和回滚」）
--     保存编排时自动存一份快照（nodes 全量 JSON），回滚 = 用快照覆盖当前编排。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_agent_version` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT,
  `agent_id`      BIGINT       NOT NULL,
  `version_no`    INT          NOT NULL,
  `snapshot_json` TEXT         NOT NULL COMMENT '整份编排快照（基础信息 + billing + nodes）',
  `remark`        VARCHAR(255)          DEFAULT NULL,
  `operator`      VARCHAR(50)           DEFAULT NULL COMMENT '谁保存的',
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agent_version` (`agent_id`, `version_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='智能体版本表';


-- =============================================================================
--  12. t_credit_transaction 算力流水表（管理端 P0 追加，需求 1.3「算力计量」）
--     规则：任何算力变动都必须落一条流水 —— 用户充值、任务消耗、退款、后台加算力。
--     账单页、算力统计页、用户「累计消费」全部从这张表算，不再各算各的。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_credit_transaction` (
  `id`             BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`        BIGINT       NOT NULL,
  `type`           VARCHAR(20)  NOT NULL               COMMENT 'RECHARGE/CONSUME/REFUND/GIFT/ADMIN_ADJUST',
  `amount`         INT          NOT NULL               COMMENT '算力变动，正数增加负数减少',
  `balance_after`  INT          NOT NULL               COMMENT '变动后余额，对账用',
  `money_amount`   DECIMAL(10,2)         DEFAULT NULL  COMMENT '对应金额（元），消耗类可为空',
  `order_no`       VARCHAR(40)           DEFAULT NULL  COMMENT '订单号 P/C/R + yyyyMMdd + 序号',
  `channel`        VARCHAR(30)           DEFAULT NULL  COMMENT '微信支付/支付宝/算力余额/后台调整',
  `status`         VARCHAR(20)  NOT NULL DEFAULT 'SUCCESS' COMMENT 'SUCCESS/PENDING/FAILED',
  `remark`         VARCHAR(255)          DEFAULT NULL,
  `ref_task_id`    BIGINT                DEFAULT NULL  COMMENT '消耗时关联的任务ID',
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_created` (`user_id`, `created_at`),
  KEY `idx_type_created` (`type`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='算力流水表';

-- =============================================================================
--  校验：执行完后确认 24 张表都在（7 张 C 端 + 17 张管理端）
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

-- =============================================================================
--  17. t_call_log 调试调用日志表（管理端 P3，需求 3.2）
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_call_log` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT,
  `session_id`  VARCHAR(64)           DEFAULT NULL COMMENT '一次调试的会话ID',
  `agent_id`    BIGINT                DEFAULT NULL,
  `agent_name`  VARCHAR(100)          DEFAULT NULL COMMENT '智能体名称快照',
  `mode`        VARCHAR(20)  NOT NULL COMMENT 'NODE/CHAIN/CHAT/REGRESSION',
  `node_id`     BIGINT                DEFAULT NULL,
  `node_key`    VARCHAR(50)           DEFAULT NULL,
  `node_name`   VARCHAR(100)          DEFAULT NULL,
  `tool_kind`   VARCHAR(30)           DEFAULT NULL,
  `input`       TEXT                  DEFAULT NULL,
  `output`      TEXT                  DEFAULT NULL,
  `success`     TINYINT      NOT NULL DEFAULT 1,
  `elapsed_ms`  BIGINT                DEFAULT NULL,
  `credits`     DECIMAL(10,2)         DEFAULT NULL,
  `error_msg`   VARCHAR(1000)         DEFAULT NULL,
  `operator`    VARCHAR(50)           DEFAULT NULL,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_log_agent` (`agent_id`, `id`),
  KEY `idx_log_session` (`session_id`),
  KEY `idx_log_mode` (`mode`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='调试调用日志表';

-- =============================================================================
--  18. t_regression_case 回归测试用例表（管理端 P3，需求 3.2）
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_regression_case` (
  `id`                BIGINT       NOT NULL AUTO_INCREMENT,
  `agent_id`          BIGINT       NOT NULL,
  `name`              VARCHAR(100) NOT NULL,
  `input`             TEXT         NOT NULL,
  `expected_keywords` VARCHAR(500)          DEFAULT NULL COMMENT '逗号分隔，全部命中才算通过',
  `enabled`           TINYINT      NOT NULL DEFAULT 1,
  `created_by`        VARCHAR(50)           DEFAULT NULL,
  `created_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_case_agent` (`agent_id`, `enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='回归测试用例表';

-- =============================================================================
--  19. t_mcp_server MCP 服务端表（管理端 P4，需求 3.3）
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_mcp_server` (
  `id`               BIGINT       NOT NULL AUTO_INCREMENT,
  `name`             VARCHAR(100) NOT NULL,
  `transport`        VARCHAR(20)  NOT NULL DEFAULT 'HTTP' COMMENT 'HTTP/SSE/STDIO',
  `endpoint`         VARCHAR(255)          DEFAULT NULL,
  `command`          VARCHAR(500)          DEFAULT NULL COMMENT 'STDIO 启动命令',
  `env_json`         VARCHAR(2000)         DEFAULT NULL,
  `auth_type`        VARCHAR(20)  NOT NULL DEFAULT 'NONE',
  `api_key`          VARCHAR(255)          DEFAULT NULL,
  `status`           VARCHAR(20)  NOT NULL DEFAULT 'OFFLINE' COMMENT 'ONLINE/OFFLINE',
  `last_discover_at` DATETIME              DEFAULT NULL,
  `tool_count`       INT          NOT NULL DEFAULT 0,
  `deleted`          TINYINT      NOT NULL DEFAULT 0,
  `created_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='MCP服务端表';

-- =============================================================================
--  20. t_mcp_tool MCP 工具表（管理端 P4，需求 3.3）
--     tool_key = mcp_{serverId}_{toolName}，映射为平台标准工具。
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_mcp_tool` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT,
  `server_id`       BIGINT       NOT NULL,
  `tool_name`       VARCHAR(100) NOT NULL,
  `tool_key`        VARCHAR(120) NOT NULL,
  `display_name`    VARCHAR(100)          DEFAULT NULL,
  `description`     VARCHAR(500)          DEFAULT NULL,
  `input_schema`    TEXT                  DEFAULT NULL,
  `enabled`         TINYINT      NOT NULL DEFAULT 1,
  `last_invoked_at` DATETIME              DEFAULT NULL,
  `deleted`         TINYINT      NOT NULL DEFAULT 0,
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_mcp_tool_key` (`tool_key`),
  KEY `idx_mcp_server` (`server_id`, `enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='MCP工具表';

-- =============================================================================
--  21. t_knowledge_base 知识库表（管理端 P5，需求 3.4.1）
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_knowledge_base` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT,
  `name`            VARCHAR(100) NOT NULL,
  `description`     VARCHAR(500)          DEFAULT NULL,
  `embedding_model` VARCHAR(100)          DEFAULT 'keyword-v1',
  `status`          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
  `document_count`  INT          NOT NULL DEFAULT 0,
  `chunk_count`     INT          NOT NULL DEFAULT 0,
  `bound_agent_ids` VARCHAR(1000)         DEFAULT NULL COMMENT '绑定的智能体ID，逗号分隔',
  `deleted`         TINYINT      NOT NULL DEFAULT 0,
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='知识库表';

-- =============================================================================
--  22. t_kb_document 知识库文档表（管理端 P5，需求 3.4.1）
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_kb_document` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT,
  `kb_id`       BIGINT       NOT NULL,
  `name`        VARCHAR(200) NOT NULL,
  `source_type` VARCHAR(20)  NOT NULL COMMENT 'TEXT/FILE/URL/API_SYNC',
  `source_url`  VARCHAR(500)          DEFAULT NULL,
  `content`     TEXT                  DEFAULT NULL,
  `mime_type`   VARCHAR(100)          DEFAULT NULL,
  `file_size`   BIGINT                DEFAULT NULL,
  `chunk_count` INT          NOT NULL DEFAULT 0,
  `status`      VARCHAR(20)  NOT NULL DEFAULT 'READY',
  `error_msg`   VARCHAR(1000)         DEFAULT NULL,
  `deleted`     TINYINT      NOT NULL DEFAULT 0,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_kb_doc` (`kb_id`, `deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='知识库文档表';

-- =============================================================================
--  23. t_kb_chunk 知识库分段表（管理端 P5，需求 3.4.1）
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_kb_chunk` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT,
  `kb_id`       BIGINT       NOT NULL,
  `document_id` BIGINT       NOT NULL,
  `chunk_index` INT          NOT NULL,
  `content`     TEXT         NOT NULL,
  `keywords`    VARCHAR(500)          DEFAULT NULL,
  `deleted`     TINYINT      NOT NULL DEFAULT 0,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_kb_chunk` (`kb_id`, `deleted`),
  KEY `idx_doc_chunk` (`document_id`, `chunk_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='知识库分段表';

-- =============================================================================
--  24. t_gateway_endpoint 对外网关接口定义表（管理端 P8，需求 1.3）
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_gateway_endpoint` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(100) NOT NULL,
  `method`        VARCHAR(10)  NOT NULL DEFAULT 'POST',
  `path`          VARCHAR(200) NOT NULL,
  `agent_id`      BIGINT                DEFAULT NULL,
  `auth_required` TINYINT      NOT NULL DEFAULT 1,
  `rate_limit`    VARCHAR(50)           DEFAULT NULL,
  `online`        TINYINT      NOT NULL DEFAULT 1,
  `call_count`    BIGINT       NOT NULL DEFAULT 0,
  `remark`        VARCHAR(500)          DEFAULT NULL,
  `deleted`       TINYINT      NOT NULL DEFAULT 0,
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_gateway_method_path` (`method`, `path`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='对外网关接口定义表';
-- =============================================================================
-- 用户端 v2 · M1 接单市场
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_market_order` (
  `id`                BIGINT       NOT NULL AUTO_INCREMENT COMMENT '订单ID',
  `order_no`          VARCHAR(32)  NOT NULL COMMENT '对外订单号',
  `title`             VARCHAR(120) NOT NULL COMMENT '订单标题',
  `brand_name`        VARCHAR(100) NOT NULL COMMENT '需求方名称',
  `description`       TEXT         NOT NULL COMMENT '需求说明',
  `media_type`        VARCHAR(20)  NOT NULL COMMENT 'IMAGE / VIDEO / AUDIO',
  `reward_fen`        BIGINT       NOT NULL COMMENT '订单报酬，单位分',
  `credit_cost`       INT          NOT NULL DEFAULT 0 COMMENT '预计算力消耗',
  `requirements_json` JSON         DEFAULT NULL COMMENT '交付要求字符串数组',
  `deadline_at`       DATETIME     NOT NULL COMMENT '截止时间',
  `tasks_total`       INT          NOT NULL DEFAULT 0 COMMENT '总名额',
  `tasks_taken`       INT          NOT NULL DEFAULT 0 COMMENT '已接名额',
  `status`            VARCHAR(20)  NOT NULL DEFAULT 'OPEN' COMMENT 'OPEN / CLOSED / COMPLETED',
  `version`           BIGINT       NOT NULL DEFAULT 0 COMMENT '乐观锁',
  `created_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_market_order_no` (`order_no`),
  KEY `idx_market_status_deadline` (`status`, `deadline_at`),
  KEY `idx_market_media_type` (`media_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='接单市场订单';

CREATE TABLE IF NOT EXISTS `t_order_acceptance` (
  `id`             BIGINT      NOT NULL AUTO_INCREMENT COMMENT '接单记录ID',
  `acceptance_no`  VARCHAR(32) NOT NULL COMMENT '对外接单号',
  `order_id`       BIGINT      NOT NULL COMMENT '订单ID',
  `user_id`        BIGINT      NOT NULL COMMENT '接单用户ID',
  `status`         VARCHAR(20) NOT NULL DEFAULT 'ACCEPTED' COMMENT 'ACCEPTED / SUBMITTED / APPROVED / REJECTED / CANCELLED',
  `accepted_at`    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `submitted_at`   DATETIME    DEFAULT NULL,
  `approved_at`    DATETIME    DEFAULT NULL,
  `created_at`     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_acceptance_no` (`acceptance_no`),
  UNIQUE KEY `uk_order_user` (`order_id`, `user_id`),
  KEY `idx_acceptance_user_status` (`user_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户接单记录';
-- =============================================================================
-- 用户端 v2 · M2 作品提交与审核
-- =============================================================================
CREATE TABLE IF NOT EXISTS `t_submission` (
  `id`             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '提交记录ID',
  `submission_no`  VARCHAR(32)  NOT NULL COMMENT '对外提交号',
  `order_id`       BIGINT       NOT NULL COMMENT '订单ID',
  `acceptance_id`  BIGINT       NOT NULL COMMENT '接单记录ID',
  `user_id`        BIGINT       NOT NULL COMMENT '用户ID',
  `task_id`        BIGINT       NOT NULL COMMENT '生成任务ID',
  `media_type`     VARCHAR(20)  NOT NULL COMMENT 'IMAGE / VIDEO / AUDIO',
  `title`          VARCHAR(120) NOT NULL COMMENT '作品标题',
  `note`           VARCHAR(1000) DEFAULT NULL COMMENT '交付说明',
  `result_url`     VARCHAR(500) NOT NULL COMMENT '结果资源地址',
  `thumbnail_url`  VARCHAR(500) DEFAULT NULL COMMENT '缩略图地址',
  `duration_ms`    BIGINT       DEFAULT NULL COMMENT '媒体时长',
  `version_no`     INT          NOT NULL DEFAULT 1 COMMENT '同一订单下的提交版本',
  `status`         VARCHAR(20)  NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING / APPROVED / REJECTED',
  `review_note`    VARCHAR(1000) DEFAULT NULL COMMENT '审核意见',
  `submitted_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reviewed_at`    DATETIME     DEFAULT NULL,
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_submission_no` (`submission_no`),
  UNIQUE KEY `uk_order_user_version` (`order_id`, `user_id`, `version_no`),
  KEY `idx_submission_user_status` (`user_id`, `status`),
  KEY `idx_submission_task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单作品提交记录';

CREATE TABLE IF NOT EXISTS `t_review_record` (
  `id`             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '审核记录ID',
  `submission_id`  BIGINT       NOT NULL COMMENT '提交记录ID',
  `reviewer_id`    BIGINT       DEFAULT NULL COMMENT '审核人ID',
  `decision`       VARCHAR(20)  NOT NULL COMMENT 'APPROVED / REJECTED',
  `comment`        VARCHAR(1000) DEFAULT NULL COMMENT '审核意见',
  `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_review_submission` (`submission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='作品审核记录';