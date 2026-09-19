package com.opc.server.repository;

import com.opc.server.entity.Skill;
import com.opc.server.entity.enums.SkillType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Skill 线路数据访问。
 *
 * <p>注意 {@code t_skill} 表没有 {@code deleted} 列 —— 线路是运营配置数据，
 * 下线用 {@code status = 0} 表达，不做逻辑删除，所以查询里不出现 deleted 条件。
 */
@Repository
public interface SkillRepository extends JpaRepository<Skill, Long> {

    Optional<Skill> findByCode(String code);

    Optional<Skill> findByIdAndStatus(Long id, Integer status);

    /** 按类型查启用中的线路；type 传 null 表示全部。 */
    List<Skill> findByStatusOrderBySortOrderAscIdAsc(Integer status);

    List<Skill> findByStatusAndTypeOrderBySortOrderAscIdAsc(Integer status, SkillType type);

    List<Skill> findByTypeOrderBySortOrderAscIdAsc(SkillType type);

    boolean existsByCode(String code);
}
