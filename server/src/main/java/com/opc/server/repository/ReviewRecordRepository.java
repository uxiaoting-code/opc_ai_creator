package com.opc.server.repository;

import com.opc.server.entity.ReviewRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ReviewRecordRepository extends JpaRepository<ReviewRecord, Long> {

    Optional<ReviewRecord> findBySubmissionId(Long submissionId);
}