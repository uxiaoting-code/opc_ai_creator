package com.opc.server.repository;

import com.opc.server.entity.AgentVersion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AgentVersionRepository extends JpaRepository<AgentVersion, Long> {

    List<AgentVersion> findByAgentIdOrderByVersionNoDesc(Long agentId);

    Optional<AgentVersion> findByAgentIdAndVersionNo(Long agentId, Integer versionNo);

    Optional<AgentVersion> findTopByAgentIdOrderByVersionNoDesc(Long agentId);
}
