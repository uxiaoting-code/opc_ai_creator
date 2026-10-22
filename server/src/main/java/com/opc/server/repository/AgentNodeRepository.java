package com.opc.server.repository;

import com.opc.server.entity.AgentNode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AgentNodeRepository extends JpaRepository<AgentNode, Long> {

    List<AgentNode> findByAgentIdOrderByOrderIndexAscIdAsc(Long agentId);

    Optional<AgentNode> findByAgentIdAndNodeKey(Long agentId, String nodeKey);

    Optional<AgentNode> findByIdAndAgentId(Long id, Long agentId);

    void deleteByAgentId(Long agentId);
}
