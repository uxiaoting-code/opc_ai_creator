package com.opc.server;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.ReviewRequest;
import com.opc.server.dto.SubmissionCreateRequest;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.MarketOrder;
import com.opc.server.entity.OrderAcceptance;
import com.opc.server.entity.Submission;
import com.opc.server.entity.enums.AcceptanceStatus;
import com.opc.server.entity.enums.MarketOrderStatus;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.entity.enums.ReviewStatus;
import com.opc.server.entity.enums.TaskStatus;
import com.opc.server.entity.enums.TaskType;
import com.opc.server.repository.AiTaskRepository;
import com.opc.server.repository.MarketOrderRepository;
import com.opc.server.repository.OrderAcceptanceRepository;
import com.opc.server.repository.ReviewRecordRepository;
import com.opc.server.repository.SubmissionRepository;
import com.opc.server.repository.WalletAccountRepository;
import com.opc.server.service.SubmissionService;
import com.opc.server.service.WalletService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
@Import(WalletService.class)
@Transactional
class SubmissionServiceDataTest {

    @Autowired
    private SubmissionRepository submissionRepository;
    @Autowired
    private ReviewRecordRepository reviewRecordRepository;
    @Autowired
    private MarketOrderRepository marketOrderRepository;
    @Autowired
    private OrderAcceptanceRepository acceptanceRepository;
    @Autowired
    private AiTaskRepository taskRepository;
    @Autowired
    private WalletService walletService;
    @Autowired
    private WalletAccountRepository walletAccountRepository;

    private SubmissionService submissionService;

    @BeforeEach
    void setUp() {
        submissionService = new SubmissionService(
                submissionRepository,
                reviewRecordRepository,
                marketOrderRepository,
                acceptanceRepository,
                taskRepository,
                walletService);
    }

    @Test
    void submitsSuccessfulTaskAndMarksAcceptanceSubmitted() {
        MarketOrder order = saveOrder("MO-S-001", MediaType.IMAGE);
        OrderAcceptance acceptance = saveAcceptance(order.getId(), 1L, AcceptanceStatus.ACCEPTED);
        AiTask task = saveTask("TASK-S-001", 1L, TaskType.TEXT_TO_IMAGE, TaskStatus.SUCCESS);

        var response = submissionService.submit(1L, new SubmissionCreateRequest(
                order.getId(), task.getId(), "香水主图最终稿", "已完成四张主图"));

        assertThat(response.status()).isEqualTo(ReviewStatus.PENDING);
        assertThat(response.mediaType()).isEqualTo(MediaType.IMAGE);
        assertThat(response.resultUrl()).isEqualTo("/upload/task-s-001.png");
        assertThat(response.versionNo()).isEqualTo(1);

        OrderAcceptance updated = acceptanceRepository.findById(acceptance.getId()).orElseThrow();
        assertThat(updated.getStatus()).isEqualTo(AcceptanceStatus.SUBMITTED);
        assertThat(updated.getSubmittedAt()).isNotNull();
    }

    @Test
    void rejectsTaskOwnedByAnotherUser() {
        MarketOrder order = saveOrder("MO-S-002", MediaType.IMAGE);
        saveAcceptance(order.getId(), 1L, AcceptanceStatus.ACCEPTED);
        AiTask task = saveTask("TASK-S-002", 99L, TaskType.TEXT_TO_IMAGE, TaskStatus.SUCCESS);

        assertThatThrownBy(() -> submissionService.submit(1L, new SubmissionCreateRequest(
                order.getId(), task.getId(), "越权任务", null)))
                .isInstanceOf(BizException.class)
                .extracting(ex -> ((BizException) ex).getErrorCode())
                .isEqualTo(ErrorCode.TASK_NOT_FOUND);
    }

    @Test
    void rejectsMediaTypeMismatch() {
        MarketOrder order = saveOrder("MO-S-003", MediaType.VIDEO);
        saveAcceptance(order.getId(), 1L, AcceptanceStatus.ACCEPTED);
        AiTask task = saveTask("TASK-S-003", 1L, TaskType.TEXT_TO_IMAGE, TaskStatus.SUCCESS);

        assertThatThrownBy(() -> submissionService.submit(1L, new SubmissionCreateRequest(
                order.getId(), task.getId(), "类型不匹配", null)))
                .isInstanceOf(BizException.class)
                .extracting(ex -> ((BizException) ex).getErrorCode())
                .isEqualTo(ErrorCode.SUBMISSION_MEDIA_INVALID);
    }

    @Test
    void rejectsDuplicatePendingSubmission() {
        MarketOrder order = saveOrder("MO-S-004", MediaType.IMAGE);
        saveAcceptance(order.getId(), 1L, AcceptanceStatus.ACCEPTED);
        AiTask first = saveTask("TASK-S-004", 1L, TaskType.TEXT_TO_IMAGE, TaskStatus.SUCCESS);
        submissionService.submit(1L, new SubmissionCreateRequest(
                order.getId(), first.getId(), "第一版", null));

        AiTask second = saveTask("TASK-S-005", 1L, TaskType.TEXT_TO_IMAGE, TaskStatus.SUCCESS);
        assertThatThrownBy(() -> submissionService.submit(1L, new SubmissionCreateRequest(
                order.getId(), second.getId(), "第二版", null)))
                .isInstanceOf(BizException.class)
                .extracting(ex -> ((BizException) ex).getErrorCode())
                .isEqualTo(ErrorCode.SUBMISSION_ALREADY_PENDING);
    }

    @Test
    void approvesSubmissionAndUpdatesAcceptance() {
        MarketOrder order = saveOrder("MO-S-005", MediaType.IMAGE);
        OrderAcceptance acceptance = saveAcceptance(order.getId(), 1L, AcceptanceStatus.ACCEPTED);
        AiTask task = saveTask("TASK-S-006", 1L, TaskType.TEXT_TO_IMAGE, TaskStatus.SUCCESS);
        Submission created = submissionRepository.findById(
                submissionService.submit(1L, new SubmissionCreateRequest(
                        order.getId(), task.getId(), "待审核作品", null)).id()).orElseThrow();

        var reviewed = submissionService.review(
                2L, created.getId(), new ReviewRequest(ReviewStatus.APPROVED, "符合要求"));

        assertThat(reviewed.status()).isEqualTo(ReviewStatus.APPROVED);
        assertThat(reviewed.reviewNote()).isEqualTo("符合要求");
        assertThat(reviewRecordRepository.findBySubmissionId(created.getId())).isPresent();
        assertThat(acceptanceRepository.findById(acceptance.getId()).orElseThrow().getStatus())
                .isEqualTo(AcceptanceStatus.APPROVED);
        assertThat(walletAccountRepository.findByUserId(1L).orElseThrow().getWithdrawableFen())
                .isEqualTo(6800L);
    }

    @Test
    void rejectedSubmissionAllowsNextVersion() {
        MarketOrder order = saveOrder("MO-S-006", MediaType.IMAGE);
        saveAcceptance(order.getId(), 1L, AcceptanceStatus.ACCEPTED);
        AiTask first = saveTask("TASK-S-007", 1L, TaskType.TEXT_TO_IMAGE, TaskStatus.SUCCESS);
        Submission created = submissionRepository.findById(
                submissionService.submit(1L, new SubmissionCreateRequest(
                        order.getId(), first.getId(), "第一版", null)).id()).orElseThrow();
        submissionService.review(2L, created.getId(), new ReviewRequest(ReviewStatus.REJECTED, "需要调整"));

        AiTask second = saveTask("TASK-S-008", 1L, TaskType.TEXT_TO_IMAGE, TaskStatus.SUCCESS);
        var secondSubmission = submissionService.submit(1L, new SubmissionCreateRequest(
                order.getId(), second.getId(), "第二版", null));

        assertThat(secondSubmission.versionNo()).isEqualTo(2);
        assertThat(secondSubmission.status()).isEqualTo(ReviewStatus.PENDING);
    }

    @Test
    void listsSubmissionsWithFilters() {
        MarketOrder order = saveOrder("MO-S-007", MediaType.IMAGE);
        saveAcceptance(order.getId(), 1L, AcceptanceStatus.ACCEPTED);
        AiTask task = saveTask("TASK-S-009", 1L, TaskType.TEXT_TO_IMAGE, TaskStatus.SUCCESS);
        submissionService.submit(1L, new SubmissionCreateRequest(
                order.getId(), task.getId(), "列表作品", null));

        var page = submissionService.listMy(1L, ReviewStatus.PENDING, MediaType.IMAGE, 1, 10);

        assertThat(page.total()).isEqualTo(1);
        assertThat(page.list().getFirst().title()).isEqualTo("列表作品");
    }

    private MarketOrder saveOrder(String orderNo, MediaType mediaType) {
        return marketOrderRepository.save(MarketOrder.builder()
                .orderNo(orderNo)
                .title("测试订单 " + orderNo)
                .brandName("测试需求方")
                .description("测试订单描述")
                .mediaType(mediaType)
                .rewardFen(6800L)
                .creditCost(12)
                .requirements(List.of("提交 PNG"))
                .deadlineAt(LocalDateTime.now().plusDays(1))
                .tasksTotal(10)
                .tasksTaken(1)
                .status(MarketOrderStatus.OPEN)
                .build());
    }

    private OrderAcceptance saveAcceptance(Long orderId, Long userId, AcceptanceStatus status) {
        return acceptanceRepository.save(OrderAcceptance.builder()
                .acceptanceNo("OA-" + orderId + "-" + userId)
                .orderId(orderId)
                .userId(userId)
                .status(status)
                .acceptedAt(LocalDateTime.now())
                .build());
    }

    private AiTask saveTask(String taskNo, Long userId, TaskType type, TaskStatus status) {
        return taskRepository.save(AiTask.builder()
                .taskNo(taskNo)
                .userId(userId)
                .type(type)
                .status(status)
                .progress(status == TaskStatus.SUCCESS ? 100 : 0)
                .resultUrl("/upload/" + taskNo.toLowerCase() + ".png")
                .resultThumb("/upload/" + taskNo.toLowerCase() + ".png")
                .durationMs(1200L)
                .deleted(false)
                .build());
    }
}