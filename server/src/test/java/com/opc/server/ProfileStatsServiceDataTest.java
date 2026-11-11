package com.opc.server;

import com.opc.server.entity.AiTask;
import com.opc.server.entity.Submission;
import com.opc.server.entity.User;
import com.opc.server.entity.WalletAccount;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.entity.enums.ReviewStatus;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.entity.enums.TaskType;
import com.opc.server.repository.AiTaskRepository;
import com.opc.server.repository.CreditTransactionRepository;
import com.opc.server.repository.PaymentChannelRepository;
import com.opc.server.repository.RechargeOrderRepository;
import com.opc.server.repository.SubmissionRepository;
import com.opc.server.repository.UserRepository;
import com.opc.server.repository.WalletAccountRepository;
import com.opc.server.repository.WalletTransactionRepository;
import com.opc.server.repository.WithdrawRequestRepository;
import com.opc.server.service.ProfileStatsService;
import com.opc.server.service.WalletService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@Import(WalletService.class)
@Transactional
class ProfileStatsServiceDataTest {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private WalletAccountRepository walletAccountRepository;
    @Autowired
    private WalletTransactionRepository walletTransactionRepository;
    @Autowired
    private RechargeOrderRepository rechargeOrderRepository;
    @Autowired
    private WithdrawRequestRepository withdrawRequestRepository;
    @Autowired
    private PaymentChannelRepository paymentChannelRepository;
    @Autowired
    private CreditTransactionRepository creditTransactionRepository;
    @Autowired
    private SubmissionRepository submissionRepository;
    @Autowired
    private AiTaskRepository taskRepository;
    @Autowired
    private WalletService walletService;

    private ProfileStatsService profileStatsService;
    private User user;

    @BeforeEach
    void setUp() {
        profileStatsService = new ProfileStatsService(
                walletService, submissionRepository, taskRepository);
        user = userRepository.save(User.builder()
                .username("profile-user")
                .password("x")
                .nickname("统计测试")
                .role("USER")
                .credits(5000)
                .status(1)
                .deleted(false)
                .build());
    }

    @Test
    void aggregatesWalletReviewAndTaskStats() {
        walletAccountRepository.save(WalletAccount.builder()
                .userId(user.getId())
                .withdrawableFen(12000L)
                .frozenFen(1000L)
                .totalIncomeFen(20000L)
                .totalWithdrawnFen(3000L)
                .build());
        submissionRepository.save(submission("SUB-PENDING", ReviewStatus.PENDING, 1L));
        submissionRepository.save(submission("SUB-APPROVED", ReviewStatus.APPROVED, 2L));
        submissionRepository.save(submission("SUB-REJECTED", ReviewStatus.REJECTED, 3L));
        taskRepository.save(task("TASK-SUCCESS", TaskStatus.SUCCESS));
        taskRepository.save(task("TASK-QUEUED", TaskStatus.QUEUED));

        var stats = profileStatsService.stats(user.getId());

        assertThat(stats.credits()).isEqualTo(5000);
        assertThat(stats.withdrawableFen()).isEqualTo(12000L);
        assertThat(stats.frozenFen()).isEqualTo(1000L);
        assertThat(stats.totalIncomeFen()).isEqualTo(20000L);
        assertThat(stats.totalWithdrawnFen()).isEqualTo(3000L);
        assertThat(stats.pendingReviewCount()).isEqualTo(1L);
        assertThat(stats.approvedReviewCount()).isEqualTo(1L);
        assertThat(stats.rejectedReviewCount()).isEqualTo(1L);
        assertThat(stats.taskStats()).containsEntry("SUCCESS", 1L);
        assertThat(stats.taskStats()).containsEntry("QUEUED", 1L);
        assertThat(stats.taskStats()).containsEntry("FAILED", 0L);
    }

    private Submission submission(String submissionNo, ReviewStatus status, Long orderId) {
        return Submission.builder()
                .submissionNo(submissionNo)
                .orderId(orderId)
                .acceptanceId(1L)
                .userId(user.getId())
                .taskId(1L)
                .mediaType(MediaType.IMAGE)
                .title(submissionNo)
                .resultUrl("/upload/test.png")
                .versionNo(1)
                .status(status)
                .submittedAt(LocalDateTime.now())
                .build();
    }

    private AiTask task(String taskNo, TaskStatus status) {
        return AiTask.builder()
                .taskNo(taskNo)
                .userId(user.getId())
                .type(TaskType.TEXT_TO_IMAGE)
                .status(status)
                .progress(status == TaskStatus.SUCCESS ? 100 : 0)
                .deleted(false)
                .build();
    }
}