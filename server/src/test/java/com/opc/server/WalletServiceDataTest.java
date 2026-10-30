package com.opc.server;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.PaymentCallbackRequest;
import com.opc.server.dto.RechargeCreateRequest;
import com.opc.server.dto.WithdrawCreateRequest;
import com.opc.server.dto.WithdrawStatusRequest;
import com.opc.server.entity.PaymentChannel;
import com.opc.server.entity.User;
import com.opc.server.entity.WalletAccount;
import com.opc.server.entity.enums.PaymentChannelDirection;
import com.opc.server.entity.enums.RechargeOrderStatus;
import com.opc.server.entity.enums.WithdrawStatus;
import com.opc.server.repository.CreditTransactionRepository;
import com.opc.server.repository.PaymentChannelRepository;
import com.opc.server.repository.RechargeOrderRepository;
import com.opc.server.repository.UserRepository;
import com.opc.server.repository.WalletAccountRepository;
import com.opc.server.repository.WalletTransactionRepository;
import com.opc.server.repository.WithdrawRequestRepository;
import com.opc.server.service.WalletService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
@Transactional
class WalletServiceDataTest {

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
    private UserRepository userRepository;
    @Autowired
    private CreditTransactionRepository creditTransactionRepository;

    private WalletService walletService;
    private User user;

    @BeforeEach
    void setUp() {
        walletService = new WalletService(
                walletAccountRepository,
                walletTransactionRepository,
                rechargeOrderRepository,
                withdrawRequestRepository,
                paymentChannelRepository,
                userRepository,
                creditTransactionRepository,
                "test-secret");
        user = userRepository.save(User.builder()
                .username("wallet-user")
                .password("x")
                .nickname("钱包测试")
                .role("USER")
                .credits(2000)
                .status(1)
                .deleted(false)
                .build());
        paymentChannelRepository.save(PaymentChannel.builder()
                .code("ALIPAY")
                .name("支付宝")
                .direction(PaymentChannelDirection.BOTH)
                .icon("alipay")
                .enabled(true)
                .minFen(100L)
                .maxFen(500000L)
                .feeRateBps(0)
                .sortOrder(10)
                .build());
    }

    @Test
    void summaryCreatesWalletAndIncludesCredits() {
        var summary = walletService.summary(user.getId());

        assertThat(summary.withdrawableFen()).isZero();
        assertThat(summary.frozenFen()).isZero();
        assertThat(summary.credits()).isEqualTo(2000);
        assertThat(walletAccountRepository.findByUserId(user.getId())).isPresent();
    }

    @Test
    void rechargeCallbackAddsCreditsAndIsIdempotent() {
        var created = walletService.createRecharge(user.getId(), new RechargeCreateRequest(5000L, "ALIPAY"));
        var request = new PaymentCallbackRequest(
                created.rechargeNo(), "ALI-001", 5000L, null, "test-secret");

        var paid = walletService.paymentCallback("ALIPAY", request);
        var repeated = walletService.paymentCallback("ALIPAY", request);

        assertThat(paid.status()).isEqualTo(RechargeOrderStatus.PAID);
        assertThat(repeated.status()).isEqualTo(RechargeOrderStatus.PAID);
        assertThat(userRepository.findById(user.getId()).orElseThrow().getCredits()).isEqualTo(7000);
        assertThat(creditTransactionRepository.count()).isEqualTo(1);
    }

    @Test
    void rejectsInvalidPaymentSignature() {
        var created = walletService.createRecharge(user.getId(), new RechargeCreateRequest(1000L, "ALIPAY"));

        assertThatThrownBy(() -> walletService.paymentCallback("ALIPAY",
                new PaymentCallbackRequest(created.rechargeNo(), "ALI-002", 1000L, null, "bad")))
                .isInstanceOf(BizException.class)
                .extracting(ex -> ((BizException) ex).getErrorCode())
                .isEqualTo(ErrorCode.PAYMENT_CALLBACK_INVALID);
    }

    @Test
    void createsWithdrawalAndFreezesBalance() {
        walletAccountRepository.save(WalletAccount.builder()
                .userId(user.getId())
                .withdrawableFen(10000L)
                .frozenFen(0L)
                .totalIncomeFen(10000L)
                .totalWithdrawnFen(0L)
                .build());

        var created = walletService.createWithdrawal(user.getId(),
                new WithdrawCreateRequest(3000L, "ALIPAY", "张三", "13800001234"));

        WalletAccount account = walletAccountRepository.findByUserId(user.getId()).orElseThrow();
        assertThat(created.status()).isEqualTo(WithdrawStatus.PENDING);
        assertThat(created.accountNoMasked()).doesNotContain("00001234");
        assertThat(account.getWithdrawableFen()).isEqualTo(7000);
        assertThat(account.getFrozenFen()).isEqualTo(3000);
    }

    @Test
    void successfulWithdrawalDeductsFrozenBalance() {
        walletAccountRepository.save(WalletAccount.builder()
                .userId(user.getId())
                .withdrawableFen(10000L)
                .frozenFen(0L)
                .totalIncomeFen(10000L)
                .totalWithdrawnFen(0L)
                .build());
        var created = walletService.createWithdrawal(user.getId(),
                new WithdrawCreateRequest(3000L, "ALIPAY", "张三", "13800001234"));

        walletService.updateWithdrawStatus(created.id(),
                new WithdrawStatusRequest(WithdrawStatus.PROCESSING, null, null));
        var result = walletService.updateWithdrawStatus(created.id(),
                new WithdrawStatusRequest(WithdrawStatus.SUCCESS, null, "PAYOUT-001"));

        WalletAccount account = walletAccountRepository.findByUserId(user.getId()).orElseThrow();
        assertThat(result.status()).isEqualTo(WithdrawStatus.SUCCESS);
        assertThat(account.getFrozenFen()).isZero();
        assertThat(account.getTotalWithdrawnFen()).isEqualTo(3000);
    }

    @Test
    void failedWithdrawalRefundsBalance() {
        walletAccountRepository.save(WalletAccount.builder()
                .userId(user.getId())
                .withdrawableFen(10000L)
                .frozenFen(0L)
                .totalIncomeFen(10000L)
                .totalWithdrawnFen(0L)
                .build());
        var created = walletService.createWithdrawal(user.getId(),
                new WithdrawCreateRequest(3000L, "ALIPAY", "张三", "13800001234"));

        walletService.updateWithdrawStatus(created.id(),
                new WithdrawStatusRequest(WithdrawStatus.FAILED, "渠道失败", null));

        WalletAccount account = walletAccountRepository.findByUserId(user.getId()).orElseThrow();
        assertThat(account.getWithdrawableFen()).isEqualTo(10000);
        assertThat(account.getFrozenFen()).isZero();
    }

    @Test
    void orderIncomeCreditsOnlyOnce() {
        walletService.creditOrderIncome(user.getId(), 99L, 6800L, "订单收入");
        walletService.creditOrderIncome(user.getId(), 99L, 6800L, "订单收入");

        WalletAccount account = walletAccountRepository.findByUserId(user.getId()).orElseThrow();
        assertThat(account.getWithdrawableFen()).isEqualTo(6800);
        assertThat(walletTransactionRepository.count()).isEqualTo(1);
    }
}