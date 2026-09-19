package com.opc.server.harness;

import tools.jackson.databind.ObjectMapper;
import com.opc.server.ai.AiProvider;
import com.opc.server.ai.AiProviderRouter;
import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.AiTaskResult;
import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.Skill;
import com.opc.server.entity.User;
import com.opc.server.entity.enums.SkillType;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.entity.enums.TaskType;
import com.opc.server.repository.AiTaskRepository;
import com.opc.server.repository.SkillRepository;
import com.opc.server.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Harness 任务调度系统的对外门面。
 *
 * <p>职责边界：
 * <ul>
 *   <li>本类 —— 任务的创建、查询、重试、取消，以及<b>单个任务的执行编排</b>；</li>
 *   <li>{@link TaskStateService} —— 所有写库动作（事务边界在那一边）；</li>
 *   <li>{@link HarnessScheduler} —— 定时轮询 + 投递到线程池。</li>
 * </ul>
 *
 * <p>关键设计：{@link #executeTask(Long)} <b>刻意不加 {@code @Transactional}</b>。
 * 因为方法内部要调用 AI 服务商，Mock 要 2~6 秒、真实模型可能几十秒，
 * 长时间占着数据库连接会把连接池拖垮。事务只包住「读任务」和「写结果」两小段。
 */
@Service
public class HarnessService {

    private static final Logger log = LoggerFactory.getLogger(HarnessService.class);

    private final AiTaskRepository taskRepository;
    private final SkillRepository skillRepository;
    private final UserRepository userRepository;
    private final TaskStateService stateService;
    private final AiProviderRouter providerRouter;
    private final AiTaskRequestFactory requestFactory;
    private final HarnessProperties properties;
    private final ObjectMapper objectMapper;

    public HarnessService(AiTaskRepository taskRepository,
                          SkillRepository skillRepository,
                          UserRepository userRepository,
                          TaskStateService stateService,
                          AiProviderRouter providerRouter,
                          AiTaskRequestFactory requestFactory,
                          HarnessProperties properties,
                          ObjectMapper objectMapper) {
        this.taskRepository = taskRepository;
        this.skillRepository = skillRepository;
        this.userRepository = userRepository;
        this.stateService = stateService;
        this.providerRouter = providerRouter;
        this.requestFactory = requestFactory;
        this.properties = properties;
        this.objectMapper = objectMapper;
    }

    // =========================================================================
    // 一、创建任务
    // =========================================================================

    /**
     * 创建生成任务，入库后处于「排队中」，等待调度器领取。
     *
     * <p>校验顺序是有讲究的：先校验业务参数、再校验线路、最后扣费 ——
     * 扣费放在最后，保证前面任何一步失败都不会白扣用户的算力点。
     */
    @Transactional
    public AiTask createTask(Long userId,
                             TaskType type,
                             Long skillId,
                             String prompt,
                             String negativePrompt,
                             String refImageUrl) {

        // ---- 1. 参数校验 ----
        if (type == null) {
            throw new BizException(ErrorCode.BAD_REQUEST, "任务类型不能为空");
        }
        if (type.requiresReferenceImage()
                && (refImageUrl == null || refImageUrl.isBlank())) {
            throw new BizException(ErrorCode.BAD_REQUEST, "图生视频必须提供首帧参考图");
        }
        if (type == TaskType.TEXT_TO_IMAGE && (prompt == null || prompt.isBlank())) {
            throw new BizException(ErrorCode.BAD_REQUEST, "请输入提示词");
        }

        // ---- 2. 线路校验 ----
        Skill skill = resolveSkill(skillId, type);

        // ---- 3. 用户与算力点 ----
        User user = userRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() -> new BizException(ErrorCode.USER_NOT_FOUND));

        // 按任务类型取单价：文生图 10 点、图生视频 15 点
        int cost = properties.creditsFor(type);
        if (!user.canAfford(cost)) {
            throw new BizException(ErrorCode.BAD_REQUEST,
                    "算力点不足，本次生成需要 %d 点，当前剩余 %d 点"
                            .formatted(cost, user.getCredits()));
        }

        // ---- 4. 组装任务 ----
        AiTask task = AiTask.builder()
                .taskNo(UUID.randomUUID().toString().replace("-", ""))
                .userId(userId)
                .type(type)
                .skillId(skill == null ? null : skill.getId())
                // 关键：把用户输入套进线路模板，拼出最终提示词
                .prompt(skill == null ? prompt : skill.buildFinalPrompt(prompt))
                .negativePrompt(skill == null
                        ? negativePrompt : skill.resolveNegativePrompt(negativePrompt))
                .refImageUrl(refImageUrl)
                .paramsJson(snapshotParams(skill))
                .provider(skill == null ? "mock" : skill.getProvider())
                .status(TaskStatus.QUEUED)
                .progress(0)
                .queueAt(LocalDateTime.now())
                .retryCount(0)
                .maxRetry(properties.getDefaultMaxRetry())
                .deleted(false)
                .build();

        // ---- 5. 扣费 + 落库（同一事务，要么都成功要么都回滚）----
        user.deductCredits(cost);
        userRepository.save(user);

        if (skill != null) {
            skill.increaseUsage();
            skillRepository.save(skill);
        }

        AiTask saved = taskRepository.save(task);
        if (skill != null) {
            saved.setSkillName(skill.getName());
            saved.setSkillCode(skill.getCode());
        }

        log.info("任务创建成功 taskNo={} type={} skill={} provider={}",
                saved.getTaskNo(), type, saved.getSkillId(), saved.getProvider());

        return saved;
    }

    /** 校验线路存在、在线、且类型与任务匹配。skillId 为空时返回 null（走默认参数）。 */
    private Skill resolveSkill(Long skillId, TaskType type) {
        if (skillId == null) {
            return null;
        }
        Skill skill = skillRepository.findById(skillId)
                .orElseThrow(() -> new BizException(ErrorCode.SKILL_NOT_FOUND));

        if (!skill.isOnline()) {
            throw new BizException(ErrorCode.SKILL_OFFLINE);
        }

        SkillType expected = SkillType.fromTaskType(type);
        if (skill.getType() != expected) {
            throw new BizException(ErrorCode.BAD_REQUEST,
                    "线路「%s」是%s线路，不能用于%s任务"
                            .formatted(skill.getName(), skill.getType().getLabel(),
                                    type.getLabel()));
        }
        return skill;
    }

    /**
     * 把线路参数快照成 JSON 存进任务。
     *
     * <p>为什么要快照：线路是运营可改的配置。如果只存 skillId，
     * 半年后运营把某条线路的模型换了，用户回看历史任务时看到的参数
     * 就和当初实际生成的不一致了。快照保证了历史可追溯。
     */
    private String snapshotParams(Skill skill) {
        if (skill == null) {
            return null;
        }
        try {
            Map<String, Object> params = new java.util.LinkedHashMap<>();
            params.put("skillCode", skill.getCode());
            params.put("skillName", skill.getName());
            params.put("provider", skill.getProvider());
            params.put("modelName", skill.getModelName());
            params.put("sampler", skill.getSampler());
            params.put("steps", skill.getSteps());
            params.put("cfgScale", skill.getCfgScale());
            params.put("width", skill.getWidth());
            params.put("height", skill.getHeight());
            params.put("promptPrefix", skill.getPromptPrefix());
            params.put("promptSuffix", skill.getPromptSuffix());
            return objectMapper.writeValueAsString(params);
        } catch (Exception e) {
            log.warn("线路参数快照失败 skillId={}: {}", skill.getId(), e.getMessage());
            return null;
        }
    }

    // =========================================================================
    // 二、查询
    // =========================================================================

    /**
     * 分页查询用户的任务。
     *
     * <p>前端页码从 1 开始，Spring Data 从 0 开始，这里做转换 ——
     * 别让这个 -1 泄露到 Controller 层，那样每个调用点都得记着减一。
     */
    @Transactional(readOnly = true)
    public Page<AiTask> listTasks(Long userId, TaskStatus status, int page, int pageSize) {
        Pageable pageable = PageRequest.of(Math.max(0, page - 1), Math.max(1, pageSize));
        Page<AiTask> result = taskRepository.findByUserAndStatus(userId, status, pageable);
        enrichSkillNames(result.getContent());
        return result;
    }

    /** 查单个任务，同时校验归属，防止越权看别人的任务。 */
    @Transactional(readOnly = true)
    public AiTask getTask(Long userId, Long taskId) {
        AiTask task = taskRepository.findByIdAndUserIdAndDeletedFalse(taskId, userId)
                .orElseThrow(() -> new BizException(ErrorCode.TASK_NOT_FOUND));
        enrichSkillNames(List.of(task));
        return task;
    }

    /**
     * 捞出待调度的任务，供 {@link HarnessScheduler} 轮询使用。
     *
     * <p>这里只做「查询」，不做「抢占」。抢占必须由调度器逐条调用
     * {@link TaskStateService#claim(Long)} 完成 —— 因为抢占是原子操作，
     * 而批量查询和批量抢占之间必然存在时间窗口。
     */
    @Transactional(readOnly = true)
    public List<AiTask> findDispatchable(int limit) {
        return taskRepository.findDispatchable(
                TaskStatus.QUEUED, PageRequest.of(0, Math.max(1, limit)));
    }

    /** 各状态任务数，任务列表的筛选 Tab 上可以显示角标。 */
    @Transactional(readOnly = true)
    public Map<TaskStatus, Long> countByStatus(Long userId) {
        Map<TaskStatus, Long> counts = new EnumMap<>(TaskStatus.class);
        for (TaskStatus status : TaskStatus.values()) {
            counts.put(status, 0L);
        }
        for (Object[] row : taskRepository.countGroupByStatus(userId)) {
            counts.put((TaskStatus) row[0], ((Number) row[1]).longValue());
        }
        return counts;
    }

    /**
     * 批量填充线路名称。
     *
     * <p>一次 {@code findAllById} 把整页涉及的线路查出来，避免逐条查询的 N+1。
     */
    private void enrichSkillNames(List<AiTask> tasks) {
        Set<Long> skillIds = tasks.stream()
                .map(AiTask::getSkillId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        if (skillIds.isEmpty()) {
            return;
        }

        Map<Long, Skill> skillMap = skillRepository.findAllById(skillIds).stream()
                .collect(Collectors.toMap(Skill::getId, s -> s));

        for (AiTask task : tasks) {
            Skill skill = skillMap.get(task.getSkillId());
            if (skill != null) {
                // @Transient 字段，不会被写库，纯展示用
                task.setSkillName(skill.getName());
                task.setSkillCode(skill.getCode());
            }
        }
    }

    // =========================================================================
    // 三、重试与取消
    // =========================================================================

    /**
     * 失败重试：把任务重新丢回队列。
     *
     * <p>不做成「立即执行」而是「重新排队」，是为了让它和普通任务走完全一样的
     * 调度路径 —— 否则重试任务会绕过并发限流，把服务商打挂。
     */
    @Transactional
    public AiTask retryTask(Long userId, Long taskId) {
        AiTask task = taskRepository.findByIdAndUserIdAndDeletedFalse(taskId, userId)
                .orElseThrow(() -> new BizException(ErrorCode.TASK_NOT_FOUND));

        if (task.getStatus() != TaskStatus.FAILED) {
            throw new BizException(ErrorCode.TASK_STATUS_ILLEGAL,
                    "只有失败的任务可以重试，当前状态：" + task.getStatus().getLabel());
        }
        if (!task.canRetry()) {
            throw new BizException(ErrorCode.TASK_RETRY_EXHAUSTED,
                    "重试次数已用尽（%d/%d）"
                            .formatted(task.getRetryCount(), task.getMaxRetry()));
        }

        task.requeue();
        AiTask saved = taskRepository.save(task);
        log.info("任务 {} 重新入队，第 {} 次尝试", taskId, saved.getRetryCount());
        return saved;
    }

    /** 取消任务：只允许取消还在排队的。 */
    @Transactional
    public AiTask cancelTask(Long userId, Long taskId) {
        AiTask task = taskRepository.findByIdAndUserIdAndDeletedFalse(taskId, userId)
                .orElseThrow(() -> new BizException(ErrorCode.TASK_NOT_FOUND));

        if (!task.canCancel()) {
            throw new BizException(ErrorCode.TASK_STATUS_ILLEGAL,
                    "只有排队中的任务可以取消，当前状态：" + task.getStatus().getLabel());
        }

        task.markCanceled();
        return taskRepository.save(task);
    }

    // =========================================================================
    // 四、执行（由调度器通过线程池调用）
    // =========================================================================

    /**
     * 执行一个已经抢占成功的任务。
     *
     * <p>加锁粒度说明：这里<b>不能</b>加 {@code @Transactional}。
     * 方法体里要调用 AI 服务商（几秒到几十秒），
     * 如果包在事务里，数据库连接会被长时间占住，并发一上来连接池就爆了。
     * 所以只有「读任务」和「写结果」两处短事务，中间的服务商调用在事务之外。
     */
    public void executeTask(Long taskId) {
        AiTask task = taskRepository.findById(taskId).orElse(null);
        if (task == null) {
            log.warn("任务 {} 不存在，跳过执行", taskId);
            return;
        }
        // 状态被改过（比如已被超时清理判失败）就不再执行
        if (task.getStatus() != TaskStatus.RUNNING) {
            log.warn("任务 {} 状态为 {}，跳过执行", taskId, task.getStatus());
            return;
        }

        Skill skill = task.getSkillId() == null
                ? null
                : skillRepository.findById(task.getSkillId()).orElse(null);

        AiTaskRequest request = requestFactory.build(task, skill);
        AiProvider provider = providerRouter.route(task.getProvider());

        log.info("开始执行任务 {} provider={} skill={}",
                taskId, provider.getName(), request.skillCode());

        AiTaskResult result;
        try {
            result = provider.submit(request,
                    percent -> stateService.updateProgress(taskId, percent));
        } catch (Exception e) {
            // Provider 内部已经兜过底，这里再兜一层防止线程池里的异常被吞掉
            log.error("任务 {} 执行时抛出未捕获异常", taskId, e);
            result = AiTaskResult.fail("生成异常：" + e.getMessage());
        }

        if (result.success()) {
            stateService.markSuccess(taskId, result);
        } else {
            stateService.markFailed(taskId, result.errorMessage());
        }
    }

    /** 供调度器做超时清理：把卡在「生成中」太久的任务判为失败。 */
    @Transactional
    public int failTimeoutTasks() {
        LocalDateTime threshold = LocalDateTime.now()
                .minusSeconds(properties.getTaskTimeoutSeconds());
        List<AiTask> stuck = taskRepository
                .findByStatusAndStartAtBefore(TaskStatus.RUNNING, threshold);

        for (AiTask task : stuck) {
            task.markFailed("生成超时（超过 %d 秒未返回），可重试"
                    .formatted(properties.getTaskTimeoutSeconds()));
            log.warn("任务 {} 生成超时，已标记失败", task.getId());
        }
        taskRepository.saveAll(stuck);
        return stuck.size();
    }
}
