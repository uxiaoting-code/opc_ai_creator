package com.opc.server.repository;

import com.opc.server.entity.RegressionCase;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RegressionCaseRepository extends JpaRepository<RegressionCase, Long> {

    List<RegressionCase> findByAgentIdAndEnabledTrueOrderByIdAsc(Long agentId);

    List<RegressionCase> findByAgentIdOrderByIdAsc(Long agentId);

    long countByAgentId(Long agentId);
}
