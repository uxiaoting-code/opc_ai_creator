package com.opc.server.repository;

import com.opc.server.entity.McpTool;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface McpToolRepository extends JpaRepository<McpTool, Long> {

    Optional<McpTool> findByIdAndDeletedFalse(Long id);

    Optional<McpTool> findByServerIdAndToolNameAndDeletedFalse(Long serverId, String toolName);

    List<McpTool> findByServerIdAndDeletedFalseOrderByIdAsc(Long serverId);

    List<McpTool> findByEnabledTrueAndDeletedFalseOrderByIdAsc();

    long countByServerIdAndEnabledTrueAndDeletedFalse(Long serverId);
}
