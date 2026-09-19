package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.WorkResponse;
import com.opc.server.entity.Skill;
import com.opc.server.entity.Work;
import com.opc.server.repository.SkillRepository;
import com.opc.server.repository.WorkRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 作品服务。
 *
 * <p>作品记录由 Harness 在任务成功时自动落库（见 {@code TaskStateService}），
 * 这里负责查询与发布，不负责创建。
 */
@Service
public class WorkService {

    private final WorkRepository workRepository;
    private final SkillRepository skillRepository;

    public WorkService(WorkRepository workRepository, SkillRepository skillRepository) {
        this.workRepository = workRepository;
        this.skillRepository = skillRepository;
    }

    /**
     * 查询我的作品。
     *
     * <p>返回<b>纯数组</b>而不是分页包裹对象 —— 前端
     * {@code WorkRepository.fetchMyWorks} 就是按数组解析的。
     * 等做作品画廊的无限滚动时再统一改成分页结构，届时前后端一起调整。
     */
    @Transactional(readOnly = true)
    public List<WorkResponse> listMyWorks(Long userId, int page, int pageSize, Integer limit) {
        // 前端首页只要最近几条，用 limit 覆盖 pageSize 更直观
        int size = (limit != null && limit > 0) ? limit : Math.max(1, pageSize);
        Pageable pageable = PageRequest.of(Math.max(0, page - 1), size);

        List<Work> works = workRepository
                .findByUserIdAndDeletedFalseOrderByCreatedAtDesc(userId, pageable)
                .getContent();

        return enrichAndMap(works);
    }

    /** 画廊：所有用户发布到公开画廊的作品。 */
    @Transactional(readOnly = true)
    public List<WorkResponse> listPublicWorks(int page, int pageSize) {
        Pageable pageable = PageRequest.of(Math.max(0, page - 1), Math.max(1, pageSize));
        List<Work> works = workRepository
                .findByIsPublicTrueAndDeletedFalseOrderByCreatedAtDesc(pageable)
                .getContent();
        return enrichAndMap(works);
    }

    /** 作品详情，校验归属。 */
    @Transactional(readOnly = true)
    public WorkResponse getWork(Long userId, Long workId) {
        Work work = workRepository.findByIdAndUserIdAndDeletedFalse(workId, userId)
                .orElseThrow(() -> new BizException(ErrorCode.WORK_NOT_FOUND));
        return enrichAndMap(List.of(work)).get(0);
    }

    /**
     * 发布 / 取消发布到公开画廊。
     *
     * <p>只改 {@code isPublic} 一个字段，所以用「读-改-写」是安全的：
     * 同一用户不会并发地既发布又取消发布同一个作品。
     */
    @Transactional
    public WorkResponse publish(Long userId, Long workId, boolean isPublic) {
        Work work = workRepository.findByIdAndUserIdAndDeletedFalse(workId, userId)
                .orElseThrow(() -> new BizException(ErrorCode.WORK_NOT_FOUND));

        work.setIsPublic(isPublic);
        Work saved = workRepository.save(work);
        return enrichAndMap(List.of(saved)).get(0);
    }

    /**
     * 批量补线路名 + 转 DTO。
     *
     * <p>一次性把整页涉及的线路查出来，避免逐条查询造成 N+1。
     */
    private List<WorkResponse> enrichAndMap(List<Work> works) {
        if (works.isEmpty()) {
            return List.of();
        }

        Set<Long> skillIds = works.stream()
                .map(Work::getSkillId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        Map<Long, String> skillNames = skillIds.isEmpty()
                ? Map.of()
                : skillRepository.findAllById(skillIds).stream()
                        .collect(Collectors.toMap(Skill::getId, Skill::getName));

        for (Work work : works) {
            // @Transient 字段，仅用于响应展示
            work.setSkillName(skillNames.get(work.getSkillId()));
        }

        return works.stream().map(WorkResponse::from).toList();
    }
}
