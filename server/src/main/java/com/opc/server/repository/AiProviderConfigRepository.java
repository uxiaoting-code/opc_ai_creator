package com.opc.server.repository;

import com.opc.server.entity.AiProviderConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AiProviderConfigRepository
        extends JpaRepository<AiProviderConfig, Long>,
                JpaSpecificationExecutor<AiProviderConfig> {

    Optional<AiProviderConfig> findByIdAndDeletedFalse(Long id);

    Optional<AiProviderConfig> findByChannelAndDeletedFalse(String channel);

    boolean existsByChannelAndDeletedFalse(String channel);

    boolean existsByChannelAndDeletedFalseAndIdNot(String channel, Long id);

    /** 工具库 / 智能体节点只允许引用已上架的模型。 */
    List<AiProviderConfig> findByOnlineTrueAndDeletedFalseOrderBySortOrderAscIdAsc();

    long countByDeletedFalse();
}
