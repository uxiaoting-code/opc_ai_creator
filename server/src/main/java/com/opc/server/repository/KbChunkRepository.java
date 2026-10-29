package com.opc.server.repository;

import com.opc.server.entity.KbChunk;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface KbChunkRepository extends JpaRepository<KbChunk, Long> {

    List<KbChunk> findByKbIdAndDeletedFalseOrderByIdAsc(Long kbId);

    List<KbChunk> findByDocumentIdAndDeletedFalseOrderByChunkIndexAsc(Long documentId);

    long countByKbIdAndDeletedFalse(Long kbId);

    void deleteByKbId(Long kbId);

    void deleteByDocumentId(Long documentId);
}
