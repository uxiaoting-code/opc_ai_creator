package com.opc.server.repository;

import com.opc.server.entity.AiTask;
import com.opc.server.entity.enums.TaskStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/**
 * AI 任务数据访问。**Harness 调度的所有数据库操作都在这里。**
 */
@Repository
public interface AiTaskRepository extends JpaRepository<AiTask, Long> {

    Optional<AiTask> findByTaskNo(String taskNo);

    Optional<AiTask> findByIdAndUserIdAndDeletedFalse(Long id, Long userId);

    /**
     * 按状态分页查询用户的任务。{@code status} 传 null 表示查全部。
     *
     * <p>用 {@code :status is null or ...} 而不是写两个方法，
     * 是为了让「全部 / 排队中 / 生成中 / 成功 / 失败」五个筛选 Tab
     * 共用同一个查询。
     */
    @Query("""
            select t from AiTask t
             where t.userId = :userId
               and t.deleted = false
               and (:status is null or t.status = :status)
             order by t.createdAt desc
            """)
    Page<AiTask> findByUserAndStatus(
            @Param("userId") Long userId,
            @Param("status") TaskStatus status,
            Pageable pageable);

    /**
     * 捞出待调度的任务（按入队时间先来先服务）。
     *
     * <p>只查 QUEUED，配合 {@link #claim(Long, LocalDateTime, TaskStatus, TaskStatus)}
     * 的原子抢占，保证一个任务不会被消费两次。
     */
    @Query("""
            select t from AiTask t
             where t.status = :status
               and t.deleted = false
             order by t.queueAt asc
            """)
    List<AiTask> findDispatchable(@Param("status") TaskStatus status, Pageable pageable);

    /**
     * 原子地把任务从「排队中」抢占为「生成中」。
     *
     * <p><b>这是整个 Harness 并发安全的关键。</b>
     * {@code where ... and t.status = :queued} 让「检查」和「修改」合成一条 SQL，
     * 数据库行锁保证只有一个线程能成功。返回 1 表示抢到了，0 表示被别人抢先。
     *
     * <p>如果先 select 判断状态再 update，两个调度线程会同时读到 QUEUED，
     * 同一个任务被提交给 AI 服务商两次 —— 这正是「双花」问题。
     *
     * <p>{@code clearAutomatically = true} 保证同一事务里后续 select
     * 不会命中一级缓存里的脏实体。
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update AiTask t
               set t.status = :running,
                   t.startAt = :now,
                   t.progress = 0,
                   t.errorMsg = null
             where t.id = :id
               and t.status = :queued
            """)
    int claim(
            @Param("id") Long id,
            @Param("now") LocalDateTime now,
            @Param("running") TaskStatus running,
            @Param("queued") TaskStatus queued);

    /**
     * 单条 UPDATE 更新进度。
     *
     * <p>不用「查出来改再存」：进度回调很频繁，读改写会造成无谓的并发竞争，
     * 而丢一次进度更新完全无害。{@code status = RUNNING} 的条件
     * 保证迟到的回调不会把已经结束的任务改活。
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update AiTask t
               set t.progress = :progress
             where t.id = :id
               and t.status = :running
            """)
    int updateProgress(
            @Param("id") Long id,
            @Param("progress") int progress,
            @Param("running") TaskStatus running);

    /**
     * 最近进入终态的任务，用于派生消息通知。
     *
     * <p>消息内容在任务结束那一刻就确定了（成功/失败/取消），
     * 再单开一张通知表属于冗余存储，所以直接从任务表派生。
     */
    @Query("""
            select t from AiTask t
             where t.userId = :userId
               and t.deleted = false
               and t.status in :statuses
             order by t.finishAt desc nulls last, t.createdAt desc
            """)
    List<AiTask> findRecentFinished(
            @Param("userId") Long userId,
            @Param("statuses") Collection<TaskStatus> statuses,
            Pageable pageable);

    /** 统计各状态任务数，个人中心的数据统计用。 */
    long countByUserIdAndDeletedFalse(Long userId);

    long countByUserIdAndStatusAndDeletedFalse(Long userId, TaskStatus status);

    /** 各状态任务数，用于任务列表 Tab 上的角标。 */
    @Query("""
            select t.status, count(t) from AiTask t
             where t.userId = :userId and t.deleted = false
             group by t.status
            """)
    List<Object[]> countGroupByStatus(@Param("userId") Long userId);

    /**
     * 找出卡在「生成中」太久的任务。
     *
     * <p>用于超时清理：服务商可能一直不返回，而工作线程被阻塞住，
     * 任务就永远停在 RUNNING。调度器定期把超过阈值的任务判为失败，
     * 用户就能看到明确结果并选择重试。
     */
    List<AiTask> findByStatusAndStartAtBefore(TaskStatus status, LocalDateTime threshold);

    /**
     * 找出卡死的任务：认为已经在生成中、但开始时间早于阈值的任务。
     *
     * <p>服务重启后，之前标记为 RUNNING 的任务会永远停在那个状态，
     * 需要把它们重置回 QUEUED 重新调度。应用启动时调用一次。
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update AiTask t
               set t.status = :queued,
                   t.progress = 0,
                   t.startAt = null,
                   t.errorMsg = :reason
             where t.status = :running
            """)
    int resetStuckTasks(
            @Param("queued") TaskStatus queued,
            @Param("running") TaskStatus running,
            @Param("reason") String reason);
}
