package com.opc.server.repository;

import com.opc.server.entity.McpServer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface McpServerRepository extends JpaRepository<McpServer, Long> {

    Optional<McpServer> findByIdAndDeletedFalse(Long id);

    List<McpServer> findAllByDeletedFalseOrderByIdAsc();

    long countByDeletedFalse();
}
