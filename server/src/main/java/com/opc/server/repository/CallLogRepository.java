package com.opc.server.repository;

import com.opc.server.entity.CallLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface CallLogRepository
        extends JpaRepository<CallLog, Long>, JpaSpecificationExecutor<CallLog> {
}
