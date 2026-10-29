package com.opc.server;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.entity.MarketOrder;
import com.opc.server.entity.enums.AcceptanceStatus;
import com.opc.server.entity.enums.MarketOrderStatus;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.repository.MarketOrderRepository;
import com.opc.server.repository.OrderAcceptanceRepository;
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

    private OrderService orderService;

    @BeforeEach
    void setUp() {
        orderService = new OrderService(marketOrderRepository, acceptanceRepository);
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