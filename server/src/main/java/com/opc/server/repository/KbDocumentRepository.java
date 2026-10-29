package com.opc.server.repository;

import com.opc.server.entity.KbDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface KbDocumentRepository extends JpaRepository<KbDocument, Long> {

    Optional<KbDocument> findByIdAndDeletedFalse(Long id);

    List<KbDocument> findByKbIdAndDeletedFalseOrderByIdAsc(Long kbId);

    long countByKbIdAndDeletedFalse(Long kbId);

    void deleteByKbId(Long kbId);
}
