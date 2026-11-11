package com.opc.server;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.entity.MarketOrder;
import com.opc.server.entity.enums.AcceptanceStatus;
import com.opc.server.entity.enums.MarketOrderStatus;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.repository.MarketOrderRepository;
import com.opc.server.repository.OrderAcceptanceRepository;
import com.opc.server.repository.SubmissionRepository;
import com.opc.server.service.OrderService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
@Transactional
class OrderServiceDataTest {

    @Autowired
    private MarketOrderRepository marketOrderRepository;

    @Autowired
    private OrderAcceptanceRepository acceptanceRepository;

    @Autowired
    private SubmissionRepository submissionRepository;

    private OrderService orderService;

    @BeforeEach
    void setUp() {
        orderService = new OrderService(marketOrderRepository, acceptanceRepository, submissionRepository);
    }

    @Test
    void listsAvailableOrdersAndDeserializesRequirements() {
        MarketOrder order = saveOrder("MO-T-001", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));

        var page = orderService.listAvailable(1L, MediaType.IMAGE, 1, 10);

        assertThat(page.total()).isEqualTo(1);
        assertThat(page.list()).hasSize(1);
        assertThat(page.list().getFirst().id()).isEqualTo(order.getId());
        assertThat(page.list().getFirst().requirements()).containsExactly("1:1 方图", "提交 PNG");
    }

    @Test
    void acceptsOrderAndReturnsWorkbenchContext() {
        MarketOrder order = saveOrder("MO-T-002", MediaType.VIDEO, 5, 0, LocalDateTime.now().plusHours(2));

        var result = orderService.acceptOrder(1L, order.getId());

        assertThat(result.acceptance().status()).isEqualTo(AcceptanceStatus.ACCEPTED);
        assertThat(result.acceptance().orderId()).isEqualTo(order.getId());
        assertThat(result.workbench().canGenerate()).isTrue();
        assertThat(result.workbench().recommendedMediaType()).isEqualTo(MediaType.VIDEO);

        MarketOrder updated = marketOrderRepository.findById(order.getId()).orElseThrow();
        assertThat(updated.getTasksTaken()).isEqualTo(1);
        assertThat(updated.getStatus()).isEqualTo(MarketOrderStatus.OPEN);
    }

    @Test
    void completesOrderWhenLastSlotIsTaken() {
        MarketOrder order = saveOrder("MO-T-003", MediaType.AUDIO, 1, 0, LocalDateTime.now().plusHours(2));

        orderService.acceptOrder(1L, order.getId());

        MarketOrder updated = marketOrderRepository.findById(order.getId()).orElseThrow();
        assertThat(updated.getTasksTaken()).isEqualTo(1);
        assertThat(updated.getStatus()).isEqualTo(MarketOrderStatus.COMPLETED);
    }

    @Test
    void rejectsDuplicateAcceptance() {
        MarketOrder order = saveOrder("MO-T-004", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));
        orderService.acceptOrder(1L, order.getId());

        assertThatThrownBy(() -> orderService.acceptOrder(1L, order.getId()))
                .isInstanceOf(BizException.class)
                .extracting(ex -> ((BizException) ex).getErrorCode())
                .isEqualTo(ErrorCode.ORDER_ALREADY_ACCEPTED);
    }

    @Test
    void rejectsSecondActiveOrder() {
        MarketOrder first = saveOrder("MO-T-005", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));
        MarketOrder second = saveOrder("MO-T-006", MediaType.VIDEO, 5, 0, LocalDateTime.now().plusHours(2));
        orderService.acceptOrder(1L, first.getId());

        assertThatThrownBy(() -> orderService.acceptOrder(1L, second.getId()))
                .isInstanceOf(BizException.class)
                .extracting(ex -> ((BizException) ex).getErrorCode())
                .isEqualTo(ErrorCode.ORDER_ACTIVE_EXISTS);
    }

    @Test
    void expiredAcceptanceDoesNotBlockNewOrder() {
        MarketOrder expired = saveOrder(
                "MO-T-010", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));
        MarketOrder next = saveOrder(
                "MO-T-011", MediaType.VIDEO, 5, 0, LocalDateTime.now().plusHours(2));
        orderService.acceptOrder(1L, expired.getId());

        expired.setDeadlineAt(LocalDateTime.now().minusMinutes(1));
        marketOrderRepository.save(expired);

        var result = orderService.acceptOrder(1L, next.getId());

        assertThat(result.acceptance().status()).isEqualTo(AcceptanceStatus.ACCEPTED);
        assertThat(acceptanceRepository.findByOrderIdAndUserId(expired.getId(), 1L)
                .orElseThrow()
                .getStatus())
                .isEqualTo(AcceptanceStatus.CANCELLED);
    }

    @Test
    void expiredSubmittedAcceptanceDoesNotBlockNewOrder() {
        MarketOrder expired = saveOrder(
                "MO-T-012", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));
        MarketOrder next = saveOrder(
                "MO-T-013", MediaType.VIDEO, 5, 0, LocalDateTime.now().plusHours(2));
        orderService.acceptOrder(1L, expired.getId());

        var acceptance = acceptanceRepository.findByOrderIdAndUserId(expired.getId(), 1L)
                .orElseThrow();
        acceptance.setStatus(AcceptanceStatus.SUBMITTED);
        acceptanceRepository.save(acceptance);
        expired.setDeadlineAt(LocalDateTime.now().minusMinutes(1));
        marketOrderRepository.save(expired);

        var result = orderService.acceptOrder(1L, next.getId());

        assertThat(result.acceptance().status()).isEqualTo(AcceptanceStatus.ACCEPTED);
    }

    @Test
    void submittedOrderDoesNotBlockNewOrder() {
        MarketOrder submitted = saveOrder(
                "MO-T-014", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));
        MarketOrder next = saveOrder(
                "MO-T-015", MediaType.VIDEO, 5, 0, LocalDateTime.now().plusHours(2));
        orderService.acceptOrder(1L, submitted.getId());

        var acceptance = acceptanceRepository.findByOrderIdAndUserId(submitted.getId(), 1L)
                .orElseThrow();
        acceptance.setStatus(AcceptanceStatus.SUBMITTED);
        acceptanceRepository.save(acceptance);

        var context = orderService.getCurrentWork(1L);
        assertThat(context.action()).isEqualTo("VIEW_REVIEW");
        assertThat(context.canAcceptNew()).isTrue();

        var result = orderService.acceptOrder(1L, next.getId());
        assertThat(result.acceptance().status()).isEqualTo(AcceptanceStatus.ACCEPTED);
    }

    @Test
    void expiredAcceptedWorkbenchCancelsAndCannotGenerate() {
        MarketOrder order = saveOrder(
                "MO-T-016", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));
        orderService.acceptOrder(1L, order.getId());

        order.setDeadlineAt(LocalDateTime.now().minusMinutes(1));
        marketOrderRepository.save(order);

        var context = orderService.getWorkbench(1L, order.getId());

        assertThat(context.canGenerate()).isFalse();
        assertThat(context.unavailableReason()).isEqualTo("订单已过截止时间");
        assertThat(acceptanceRepository.findByOrderIdAndUserId(order.getId(), 1L)
                .orElseThrow()
                .getStatus())
                .isEqualTo(AcceptanceStatus.CANCELLED);
    }

    @Test
    void expiredOrderDetailCancelsAcceptance() {
        MarketOrder order = saveOrder(
                "MO-T-017", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));
        orderService.acceptOrder(1L, order.getId());
        order.setDeadlineAt(LocalDateTime.now().minusMinutes(1));
        marketOrderRepository.save(order);

        var detail = orderService.getDetail(1L, order.getId());

        assertThat(detail.canAccept()).isFalse();
        assertThat(detail.unavailableReason()).isEqualTo("订单已过截止时间");
        assertThat(detail.myAcceptance().status()).isEqualTo(AcceptanceStatus.CANCELLED);
    }

    @Test
    void expiredAcceptanceIsHiddenFromAcceptedFilter() {
        MarketOrder order = saveOrder(
                "MO-T-018", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));
        orderService.acceptOrder(1L, order.getId());
        order.setDeadlineAt(LocalDateTime.now().minusMinutes(1));
        marketOrderRepository.save(order);

        var accepted = orderService.listMyAcceptances(
                1L, AcceptanceStatus.ACCEPTED, 1, 10);
        var all = orderService.listMyAcceptances(1L, null, 1, 10);

        assertThat(accepted.total()).isZero();
        assertThat(all.total()).isEqualTo(1);
        assertThat(all.list().getFirst().status()).isEqualTo(AcceptanceStatus.CANCELLED);
    }

    @Test
    void rejectsExpiredOrder() {
        MarketOrder order = saveOrder("MO-T-007", MediaType.IMAGE, 5, 0, LocalDateTime.now().minusMinutes(1));

        assertThatThrownBy(() -> orderService.acceptOrder(1L, order.getId()))
                .isInstanceOf(BizException.class)
                .extracting(ex -> ((BizException) ex).getErrorCode())
                .isEqualTo(ErrorCode.ORDER_DEADLINE_PASSED);
    }

    @Test
    void rejectsWorkbenchAccessForAnotherUser() {
        MarketOrder order = saveOrder("MO-T-008", MediaType.IMAGE, 5, 0, LocalDateTime.now().plusHours(2));
        orderService.acceptOrder(1L, order.getId());

        assertThatThrownBy(() -> orderService.getWorkbench(2L, order.getId()))
                .isInstanceOf(BizException.class)
                .extracting(ex -> ((BizException) ex).getErrorCode())
                .isEqualTo(ErrorCode.ORDER_ACCESS_DENIED);
    }

    private MarketOrder saveOrder(String orderNo,
                                  MediaType mediaType,
                                  int total,
                                  int taken,
                                  LocalDateTime deadline) {
        return marketOrderRepository.save(MarketOrder.builder()
                .orderNo(orderNo)
                .title("测试订单 " + orderNo)
                .brandName("测试需求方")
                .description("测试订单描述")
                .mediaType(mediaType)
                .rewardFen(6800L)
                .creditCost(12)
                .requirements(List.of("1:1 方图", "提交 PNG"))
                .deadlineAt(deadline)
                .tasksTotal(total)
                .tasksTaken(taken)
                .status(MarketOrderStatus.OPEN)
                .build());
    }
}
