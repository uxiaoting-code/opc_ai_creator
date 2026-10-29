package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.AcceptOrderResponse;
import com.opc.server.dto.MarketOrderResponse;
import com.opc.server.dto.OrderAcceptanceResponse;
import com.opc.server.dto.OrderDetailResponse;
import com.opc.server.dto.WorkbenchContextResponse;
import com.opc.server.entity.MarketOrder;
import com.opc.server.entity.OrderAcceptance;
import com.opc.server.entity.enums.AcceptanceStatus;
import com.opc.server.entity.enums.MarketOrderStatus;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.repository.MarketOrderRepository;
import com.opc.server.repository.OrderAcceptanceRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.EnumSet;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;

/** 接单市场与工作台上下文服务（M1）。 */
@Service
public class OrderService {

    private static final int MAX_PAGE_SIZE = 50;
    private static final DateTimeFormatter NO_FORMAT = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
    private static final Set<AcceptanceStatus> ACTIVE_STATUSES = EnumSet.of(
            AcceptanceStatus.ACCEPTED,
            AcceptanceStatus.SUBMITTED,
            AcceptanceStatus.REJECTED);

    private final MarketOrderRepository marketOrderRepository;
    private final OrderAcceptanceRepository acceptanceRepository;

    public OrderService(MarketOrderRepository marketOrderRepository,
                        OrderAcceptanceRepository acceptanceRepository) {
        this.marketOrderRepository = marketOrderRepository;
        this.acceptanceRepository = acceptanceRepository;
    }

    @Transactional(readOnly = true)
    public PageResult<MarketOrderResponse> listAvailable(
            Long userId,
            MediaType mediaType,
            int page,
            int pageSize) {
        Pageable pageable = pageRequest(page, pageSize);
        Page<MarketOrder> orders = marketOrderRepository.findAvailable(
                userId, mediaType, LocalDateTime.now(), pageable);
        return PageResult.from(orders, order -> MarketOrderResponse.from(order, null));
    }

    @Transactional(readOnly = true)
    public OrderDetailResponse getDetail(Long userId, Long orderId) {
        MarketOrder order = getOrder(orderId);
        OrderAcceptance acceptance = acceptanceRepository
                .findByOrderIdAndUserId(orderId, userId)
                .orElse(null);
        String unavailableReason = acceptUnavailableReason(userId, order, acceptance, LocalDateTime.now());
        return new OrderDetailResponse(
                MarketOrderResponse.from(order, acceptance == null ? null : acceptance.getStatus()),
                acceptance == null ? null : OrderAcceptanceResponse.from(acceptance),
                unavailableReason == null,
                unavailableReason);
    }

    @Transactional(readOnly = true)
    public PageResult<OrderAcceptanceResponse> listMyAcceptances(
            Long userId,
            AcceptanceStatus status,
            int page,
            int pageSize) {
        Pageable pageable = pageRequest(page, pageSize);
        Page<OrderAcceptance> pageResult = status == null
                ? acceptanceRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                : acceptanceRepository.findByUserIdAndStatusOrderByCreatedAtDesc(userId, status, pageable);
        return PageResult.from(pageResult, OrderAcceptanceResponse::from);
    }
    /**
     * 接单。
     *
     * <p>订单行使用悲观锁，确保名额扣减和接单记录创建在并发下只有成功者生效。
     */
    @Transactional
    public AcceptOrderResponse acceptOrder(Long userId, Long orderId) {
        if (acceptanceRepository.existsByOrderIdAndUserId(orderId, userId)) {
            throw new BizException(ErrorCode.ORDER_ALREADY_ACCEPTED);
        }
        if (acceptanceRepository.existsByUserIdAndStatusIn(userId, ACTIVE_STATUSES)) {
            throw new BizException(ErrorCode.ORDER_ACTIVE_EXISTS);
        }

        MarketOrder order = marketOrderRepository.findByIdForUpdate(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
        LocalDateTime now = LocalDateTime.now();
        validateForAccept(order, now);

        // 锁内再次检查，防止两个并发请求在加锁前都通过预检查。
        if (acceptanceRepository.existsByOrderIdAndUserId(orderId, userId)) {
            throw new BizException(ErrorCode.ORDER_ALREADY_ACCEPTED);
        }

        order.takeOneSlot();
        marketOrderRepository.save(order);

        OrderAcceptance acceptance = OrderAcceptance.builder()
                .acceptanceNo(nextAcceptanceNo())
                .orderId(orderId)
                .userId(userId)
                .status(AcceptanceStatus.ACCEPTED)
                .acceptedAt(now)
                .build();
        OrderAcceptance saved = acceptanceRepository.save(acceptance);

        return new AcceptOrderResponse(
                OrderAcceptanceResponse.from(saved),
                buildWorkbench(order, saved));
    }

    /** 工作台上下文。只有已接该订单的用户可以访问。 */
    @Transactional(readOnly = true)
    public WorkbenchContextResponse getWorkbench(Long userId, Long orderId) {
        MarketOrder order = getOrder(orderId);
        OrderAcceptance acceptance = acceptanceRepository
                .findByOrderIdAndUserId(orderId, userId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_ACCESS_DENIED));
        return buildWorkbench(order, acceptance);
    }

    private WorkbenchContextResponse buildWorkbench(MarketOrder order, OrderAcceptance acceptance) {
        boolean canGenerate = acceptance.getStatus() == AcceptanceStatus.ACCEPTED
                || acceptance.getStatus() == AcceptanceStatus.REJECTED;
        String reason = null;
        if (order.getStatus() == MarketOrderStatus.CLOSED) {
            canGenerate = false;
            reason = "订单已关闭";
        } else if (acceptance.getStatus() == AcceptanceStatus.SUBMITTED) {
            reason = "作品已提交，等待审核";
        } else if (acceptance.getStatus() == AcceptanceStatus.APPROVED) {
            reason = "订单已完成";
        } else if (acceptance.getStatus() == AcceptanceStatus.CANCELLED) {
            reason = "接单已取消";
        }

        return new WorkbenchContextResponse(
                MarketOrderResponse.from(order, acceptance.getStatus()),
                OrderAcceptanceResponse.from(acceptance),
                order.getMediaType(),
                null,
                canGenerate,
                reason);
    }

    private void validateForAccept(MarketOrder order, LocalDateTime now) {
        if (order.getStatus() != MarketOrderStatus.OPEN) {
            throw new BizException(ErrorCode.ORDER_NOT_OPEN);
        }
        if (order.isExpired(now)) {
            throw new BizException(ErrorCode.ORDER_DEADLINE_PASSED);
        }
        if (order.isFull()) {
            throw new BizException(ErrorCode.ORDER_QUOTA_FULL);
        }
    }

    private String acceptUnavailableReason(
            Long userId,
            MarketOrder order,
            OrderAcceptance acceptance,
            LocalDateTime now) {
        if (acceptance != null) {
            return "你已经接过该订单";
        }
        if (order.getStatus() != MarketOrderStatus.OPEN) {
            return "当前订单不可接取";
        }
        if (order.isExpired(now)) {
            return "订单已过截止时间";
        }
        if (order.isFull()) {
            return "该订单名额已满";
        }
        if (acceptanceRepository.existsByUserIdAndStatusIn(userId, ACTIVE_STATUSES)) {
            return "你已有进行中的接单，请先完成或放弃";
        }
        return null;
    }

    private MarketOrder getOrder(Long orderId) {
        return marketOrderRepository.findById(orderId)
                .orElseThrow(() -> new BizException(ErrorCode.ORDER_NOT_FOUND));
    }

    private Pageable pageRequest(int page, int pageSize) {
        int safePage = Math.max(1, page);
        int safeSize = Math.min(MAX_PAGE_SIZE, Math.max(1, pageSize));
        return PageRequest.of(safePage - 1, safeSize);
    }

    private String nextAcceptanceNo() {
        int random = ThreadLocalRandom.current().nextInt(10000);
        return "OA" + LocalDateTime.now().format(NO_FORMAT) + String.format("%04d", random);
    }
}