package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.ReviewRequest;
import com.opc.server.dto.SubmissionCreateRequest;
import com.opc.server.dto.SubmissionResponse;
import com.opc.server.dto.SubmissionResultResponse;
import com.opc.server.dto.TaskResponse;
import com.opc.server.entity.AiTask;
import com.opc.server.entity.MarketOrder;
import com.opc.server.entity.OrderAcceptance;
import com.opc.server.entity.ReviewRecord;
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
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;
import java.util.function.Function;
import java.util.stream.Collectors;

/** 作品提交、审核状态和后台审核服务（M2）。 */
@Service
public class SubmissionService {

    private static final int MAX_PAGE_SIZE = 50;
    private static final DateTimeFormatter NO_FORMAT = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
    private static final Set<AcceptanceStatus> SUBMITTABLE_STATUSES = Set.of(
            AcceptanceStatus.ACCEPTED,
            AcceptanceStatus.REJECTED);

    private final SubmissionRepository submissionRepository;
    private final ReviewRecordRepository reviewRecordRepository;
    private final MarketOrderRepository marketOrderRepository;
    private final OrderAcceptanceRepository acceptanceRepository;
    private final AiTaskRepository taskRepository;

    public SubmissionService(SubmissionRepository submissionRepository,
                             ReviewRecordRepository reviewRecordRepository,
                             MarketOrderRepository marketOrderRepository,
                             OrderAcceptanceRepository acceptanceRepository,
                             AiTaskRepository taskRepository) {
        this.submissionRepository = submissionRepository;
        this.reviewRecordRepository = reviewRecordRepository;
        this.marketOrderRepository = marketOrderRepository;
        this.acceptanceRepository = acceptanceRepository;
        this.taskRepository = taskRepository;
    }

    @Transactional
    public SubmissionResponse submit(Long userId, SubmissionCreateRequest request) {
        MarketOrder order = marketOrderRepository.findById(request.orderId())
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        if (order.getStatus() == MarketOrderStatus.CLOSED) {
            throw new BizException(ErrorCode.SUBMISSION_NOT_ALLOWED);
        }

        OrderAcceptance acceptance = acceptanceRepository
                .findByOrderIdAndUserId(request.orderId(), userId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_ACCESS_DENIED));
        if (submissionRepository.existsByOrderIdAndUserIdAndStatus(
                request.orderId(), userId, ReviewStatus.PENDING)) {
            throw new BizException(ErrorCode.SUBMISSION_ALREADY_PENDING);
        }
        if (!SUBMITTABLE_STATUSES.contains(acceptance.getStatus())) {
            throw new BizException(ErrorCode.SUBMISSION_NOT_ALLOWED);
        }

        AiTask task = taskRepository.findByIdAndUserIdAndDeletedFalse(request.taskId(), userId)
                .orElseThrow(() -> new BizException(ErrorCode.TASK_NOT_FOUND));
        if (task.getStatus() != TaskStatus.SUCCESS
                || task.getResultUrl() == null
                || task.getResultUrl().isBlank()) {
            throw new BizException(ErrorCode.SUBMISSION_NOT_ALLOWED, "任务尚未成功生成可提交的结果");
        }

        MediaType mediaType = mediaTypeOf(task.getType());
        if (mediaType != order.getMediaType()) {
            throw new BizException(ErrorCode.SUBMISSION_MEDIA_INVALID);
        }

        int nextVersion = submissionRepository
                .findTopByOrderIdAndUserIdOrderByVersionNoDesc(order.getId(), userId)
                .map(item -> item.getVersionNo() + 1)
                .orElse(1);
        LocalDateTime now = LocalDateTime.now();
        Submission submission = Submission.builder()
                .submissionNo(nextSubmissionNo())
                .orderId(order.getId())
                .acceptanceId(acceptance.getId())
                .userId(userId)
                .taskId(task.getId())
                .mediaType(mediaType)
                .title(request.title().trim())
                .note(normalizeOptional(request.note()))
                .resultUrl(task.getResultUrl())
                .thumbnailUrl(task.getResultThumb())
                .durationMs(task.getDurationMs())
                .versionNo(nextVersion)
                .status(ReviewStatus.PENDING)
                .submittedAt(now)
                .build();
        Submission saved = submissionRepository.save(submission);

        acceptance.setStatus(AcceptanceStatus.SUBMITTED);
        acceptance.setSubmittedAt(now);
        acceptanceRepository.save(acceptance);

        return SubmissionResponse.from(saved, order);
    }

    @Transactional(readOnly = true)
    public PageResult<SubmissionResponse> listMy(
            Long userId,
            ReviewStatus status,
            MediaType mediaType,
            int page,
            int pageSize) {
        Pageable pageable = pageRequest(page, pageSize);
        Page<Submission> pageResult = submissionRepository.findMy(
                userId, status, mediaType, pageable);
        Map<Long, MarketOrder> orders = loadOrders(pageResult.getContent());
        return PageResult.from(pageResult, submission ->
                SubmissionResponse.from(submission, orders.get(submission.getOrderId())));
    }

    @Transactional(readOnly = true)
    public SubmissionResponse getDetail(Long userId, Long submissionId) {
        Submission submission = submissionRepository.findByIdAndUserId(submissionId, userId)
                .orElseThrow(() -> new BizException(ErrorCode.SUBMISSION_NOT_FOUND));
        return SubmissionResponse.from(submission, getOrder(submission.getOrderId()));
    }

    @Transactional(readOnly = true)
    public SubmissionResultResponse getResult(Long userId, Long submissionId) {
        Submission submission = submissionRepository.findByIdAndUserId(submissionId, userId)
                .orElseThrow(() -> new BizException(ErrorCode.SUBMISSION_NOT_FOUND));
        AiTask task = taskRepository.findByIdAndUserIdAndDeletedFalse(
                        submission.getTaskId(), userId)
                .orElseThrow(() -> new BizException(ErrorCode.TASK_NOT_FOUND));
        return new SubmissionResultResponse(
                SubmissionResponse.from(submission, getOrder(submission.getOrderId())),
                TaskResponse.from(task));
    }
    /** 后台审核：只允许从 PENDING 进入 APPROVED / REJECTED。 */
    @Transactional
    public SubmissionResponse review(Long reviewerId, Long submissionId, ReviewRequest request) {
        if (request.decision() == ReviewStatus.PENDING) {
            throw new BizException(ErrorCode.REVIEW_NOT_PENDING, "审核结果不能是 PENDING");
        }
        Submission submission = submissionRepository.findByIdForUpdate(submissionId)
                .orElseThrow(() -> new BizException(ErrorCode.SUBMISSION_NOT_FOUND));
        if (submission.getStatus() != ReviewStatus.PENDING) {
            throw new BizException(ErrorCode.REVIEW_ALREADY_FINALIZED);
        }
        if (reviewRecordRepository.findBySubmissionId(submissionId).isPresent()) {
            throw new BizException(ErrorCode.REVIEW_ALREADY_FINALIZED);
        }

        LocalDateTime now = LocalDateTime.now();
        submission.setStatus(request.decision());
        submission.setReviewNote(normalizeOptional(request.comment()));
        submission.setReviewedAt(now);
        submissionRepository.save(submission);

        reviewRecordRepository.save(ReviewRecord.builder()
                .submissionId(submissionId)
                .reviewerId(reviewerId)
                .decision(request.decision())
                .comment(normalizeOptional(request.comment()))
                .build());

        OrderAcceptance acceptance = acceptanceRepository.findById(submission.getAcceptanceId())
                .orElseThrow(() -> new BizException(ErrorCode.REVIEW_NOT_FOUND, "接单记录不存在"));
        if (request.decision() == ReviewStatus.APPROVED) {
            acceptance.setStatus(AcceptanceStatus.APPROVED);
            acceptance.setApprovedAt(now);
        } else {
            acceptance.setStatus(AcceptanceStatus.REJECTED);
        }
        acceptanceRepository.save(acceptance);

        return SubmissionResponse.from(submission, getOrder(submission.getOrderId()));
    }

    private MediaType mediaTypeOf(TaskType taskType) {
        if (taskType == TaskType.TEXT_TO_IMAGE) return MediaType.IMAGE;
        if (taskType == TaskType.IMAGE_TO_VIDEO) return MediaType.VIDEO;
        throw new BizException(ErrorCode.SUBMISSION_MEDIA_INVALID);
    }

    private MarketOrder getOrder(Long orderId) {
        return marketOrderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
    }

    private Map<Long, MarketOrder> loadOrders(List<Submission> submissions) {
        Set<Long> ids = submissions.stream()
                .map(Submission::getOrderId)
                .collect(Collectors.toSet());
        if (ids.isEmpty()) return Map.of();
        return marketOrderRepository.findAllById(ids).stream()
                .collect(Collectors.toMap(MarketOrder::getId, Function.identity()));
    }

    private Pageable pageRequest(int page, int pageSize) {
        int safePage = Math.max(1, page);
        int safeSize = Math.min(MAX_PAGE_SIZE, Math.max(1, pageSize));
        return PageRequest.of(safePage - 1, safeSize);
    }

    private String normalizeOptional(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String nextSubmissionNo() {
        int random = ThreadLocalRandom.current().nextInt(10000);
        return "SB" + LocalDateTime.now().format(NO_FORMAT) + String.format("%04d", random);
    }
}