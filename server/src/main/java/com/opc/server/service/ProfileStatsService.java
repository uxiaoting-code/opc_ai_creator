package com.opc.server.service;

import com.opc.server.dto.ProfileStatsResponse;
import com.opc.server.dto.WalletSummaryResponse;
import com.opc.server.entity.enums.ReviewStatus;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.repository.AiTaskRepository;
import com.opc.server.repository.SubmissionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;

/** 个人中心统计聚合，避免前端分别猜测钱包、审核和任务统计口径。 */
@Service
public class ProfileStatsService {

    private final WalletService walletService;
    private final SubmissionRepository submissionRepository;
    private final AiTaskRepository taskRepository;

    public ProfileStatsService(WalletService walletService,
                               SubmissionRepository submissionRepository,
                               AiTaskRepository taskRepository) {
        this.walletService = walletService;
        this.submissionRepository = submissionRepository;
        this.taskRepository = taskRepository;
    }

    @Transactional
    public ProfileStatsResponse stats(Long userId) {
        WalletSummaryResponse wallet = walletService.summary(userId);

        Map<String, Long> taskStats = new LinkedHashMap<>();
        for (TaskStatus status : TaskStatus.values()) {
            taskStats.put(status.name(), 0L);
        }
        for (Object[] row : taskRepository.countGroupByStatus(userId)) {
            taskStats.put(((TaskStatus) row[0]).name(), ((Number) row[1]).longValue());
        }

        return new ProfileStatsResponse(
                wallet.credits(),
                wallet.withdrawableFen(),
                wallet.frozenFen(),
                wallet.totalIncomeFen(),
                wallet.totalWithdrawnFen(),
                submissionRepository.countByUserIdAndStatus(userId, ReviewStatus.PENDING),
                submissionRepository.countByUserIdAndStatus(userId, ReviewStatus.APPROVED),
                submissionRepository.countByUserIdAndStatus(userId, ReviewStatus.REJECTED),
                taskStats
        );
    }
}