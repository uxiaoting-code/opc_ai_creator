package com.opc.server.repository;

import com.opc.server.entity.Agent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AgentRepository
        extends JpaRepository<Agent, Long>, JpaSpecificationExecutor<Agent> {

    Optional<Agent> findByIdAndDeletedFalse(Long id);

    Optional<Agent> findByCodeAndDeletedFalse(String code);

    boolean existsByCodeAndDeletedFalse(String code);

    boolean existsByCodeAndDeletedFalseAndIdNot(String code, Long id);

    long countByDeletedFalse();
}
