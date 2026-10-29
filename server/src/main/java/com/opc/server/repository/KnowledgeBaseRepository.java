package com.opc.server.repository;

import com.opc.server.entity.KnowledgeBase;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface KnowledgeBaseRepository
        extends JpaRepository<KnowledgeBase, Long>,
                JpaSpecificationExecutor<KnowledgeBase> {

    Optional<KnowledgeBase> findByIdAndDeletedFalse(Long id);

    List<KnowledgeBase> findAllByDeletedFalseOrderByIdAsc();

    long countByDeletedFalse();
}
