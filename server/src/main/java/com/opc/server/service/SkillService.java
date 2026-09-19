package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.SkillResponse;
import com.opc.server.entity.Skill;
import com.opc.server.entity.enums.SkillType;
import com.opc.server.repository.SkillRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Skill 线路服务。
 *
 * <p>线路是纯配置数据，这里只读不写 —— 增删改由运营侧直接改数据库
 * 或后续做一个管理后台，用户端只负责查询和使用。
 */
@Service
public class SkillService {

    /** 线路启用状态。 */
    private static final int STATUS_ONLINE = 1;

    private final SkillRepository skillRepository;

    public SkillService(SkillRepository skillRepository) {
        this.skillRepository = skillRepository;
    }

    /**
     * 查询线路列表。
     *
     * <p>只返回启用中的线路：下线的线路不应该出现在首页横滑列表里。
     *
     * @param type  线路类型，null 表示查全部
     * @param limit 最多返回几条，null 表示不限制
     */
    @Transactional(readOnly = true)
    public List<SkillResponse> listSkills(SkillType type, Integer limit) {
        List<Skill> skills = (type == null)
                ? skillRepository.findByStatusOrderBySortOrderAscIdAsc(STATUS_ONLINE)
                : skillRepository.findByStatusAndTypeOrderBySortOrderAscIdAsc(
                        STATUS_ONLINE, type);

        return skills.stream()
                .limit(limit == null || limit <= 0 ? Long.MAX_VALUE : limit)
                .map(SkillResponse::from)
                .toList();
    }

    /** 线路详情。 */
    @Transactional(readOnly = true)
    public SkillResponse getSkill(Long id) {
        Skill skill = skillRepository.findByIdAndStatus(id, STATUS_ONLINE)
                .orElseThrow(() -> new BizException(ErrorCode.SKILL_NOT_FOUND));
        return SkillResponse.from(skill);
    }
}
