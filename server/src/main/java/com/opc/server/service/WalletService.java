package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.PaymentCallbackRequest;
import com.opc.server.dto.PaymentChannelResponse;
import com.opc.server.dto.RechargeCreateRequest;
import com.opc.server.dto.RechargeOrderResponse;
import com.opc.server.dto.WalletSummaryResponse;
import com.opc.server.dto.WalletTransactionResponse;
import com.opc.server.dto.WithdrawCreateRequest;
import com.opc.server.dto.WithdrawRequestResponse;
import com.opc.server.dto.WithdrawStatusRequest;
import com.opc.server.entity.CreditTransaction;
import com.opc.server.entity.PaymentChannel;
import com.opc.server.entity.RechargeOrder;
import com.opc.server.entity.User;
import com.opc.server.entity.WalletAccount;
import com.opc.server.entity.WalletTransaction;
import com.opc.server.entity.WithdrawRequest;
import com.opc.server.entity.enums.PaymentChannelDirection;
import com.opc.server.entity.enums.RechargeOrderStatus;
import com.opc.server.entity.enums.WalletTransactionType;
import com.opc.server.entity.enums.WithdrawStatus;
import com.opc.server.repository.CreditTransactionRepository;
import com.opc.server.repository.PaymentChannelRepository;
import com.opc.server.repository.RechargeOrderRepository;
import com.opc.server.repository.UserRepository;
import com.opc.server.repository.WalletAccountRepository;
import com.opc.server.repository.WalletTransactionRepository;
import com.opc.server.repository.WithdrawRequestRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/** 钱包、算力充值、提现和后台打款状态服务（M3）。 */
@Service
public class WalletService {

    private static final int MAX_PAGE_SIZE = 50;
    private static final long MIN_WITHDRAW_FEN = 1000L;
    private static final DateTimeFormatter NO_FORMAT = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final WalletAccountRepository walletAccountRepository;
    private final WalletTransactionRepository walletTransactionRepository;
    private final RechargeOrderRepository rechargeOrderRepository;
    private final WithdrawRequestRepository withdrawRequestRepository;
    private final PaymentChannelRepository paymentChannelRepository;
    private final UserRepository userRepository;
    private final CreditTransactionRepository creditTransactionRepository;
    private final String callbackSecret;

    public WalletService(WalletAccountRepository walletAccountRepository,
                         WalletTransactionRepository walletTransactionRepository,
                         RechargeOrderRepository rechargeOrderRepository,
                         WithdrawRequestRepository withdrawRequestRepository,
                         PaymentChannelRepository paymentChannelRepository,
                         UserRepository userRepository,
                         CreditTransactionRepository creditTransactionRepository,
                         @Value("${opc.payment.callback-secret:dev-callback-secret}") String callbackSecret) {
        this.walletAccountRepository = walletAccountRepository;
        this.walletTransactionRepository = walletTransactionRepository;
        this.rechargeOrderRepository = rechargeOrderRepository;
        this.withdrawRequestRepository = withdrawRequestRepository;
        this.paymentChannelRepository = paymentChannelRepository;
        this.userRepository = userRepository;
        this.creditTransactionRepository = creditTransactionRepository;
        this.callbackSecret = callbackSecret;
    }

    @Transactional
    public WalletSummaryResponse summary(Long userId) {
        WalletAccount account = getOrCreateAccount(userId);
        User user = userRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() -> new BizException(ErrorCode.USER_NOT_FOUND));
        return new WalletSummaryResponse(
                account.getWithdrawableFen(),
                account.getFrozenFen(),
                account.getTotalIncomeFen(),
                account.getTotalWithdrawnFen(),
                user.getCredits());
    }

    @Transactional(readOnly = true)
    public PageResult<WalletTransactionResponse> listTransactions(
            Long userId,
            WalletTransactionType type,
            int page,
            int pageSize) {
        Pageable pageable = pageRequest(page, pageSize);
        return PageResult.from(
                walletTransactionRepository.findMy(userId, type, pageable),
                WalletTransactionResponse::from);
    }

    @Transactional(readOnly = true)
    public List<PaymentChannelResponse> listChannels(PaymentChannelDirection direction) {
        return paymentChannelRepository.findByEnabledTrueOrderBySortOrderAsc().stream()
                .filter(channel -> direction == PaymentChannelDirection.RECHARGE
                        ? channel.getDirection().supportsRecharge()
                        : channel.getDirection().supportsWithdraw())
                .map(PaymentChannelResponse::from)
                .toList();
    }

    @Transactional
    public RechargeOrderResponse createRecharge(Long userId, RechargeCreateRequest request) {
        PaymentChannel channel = requireChannel(request.channelCode(), PaymentChannelDirection.RECHARGE);
        validateAmount(request.amountFen(), channel, false);
        int credits = Math.toIntExact(request.amountFen());
        String rechargeNo = nextNo("RC");
        RechargeOrder order = rechargeOrderRepository.save(RechargeOrder.builder()
                .rechargeNo(rechargeNo)
                .userId(userId)
                .amountFen(request.amountFen())
                .credits(credits)
                .channelCode(channel.getCode())
                .status(RechargeOrderStatus.PENDING)
                .payUrl("/mock-pay/" + rechargeNo)
                .build());
        return RechargeOrderResponse.from(order);
    }

    @Transactional(readOnly = true)
    public RechargeOrderResponse getRecharge(Long userId, Long rechargeOrderId) {
        RechargeOrder order = rechargeOrderRepository.findByIdAndUserId(rechargeOrderId, userId)
                .orElseThrow(() -> new BizException(ErrorCode.RECHARGE_ORDER_NOT_FOUND));
        return RechargeOrderResponse.from(order);
    }
    /** 支付渠道回调。使用共享密钥签名作为当前课设环境的最小验签实现。 */
    @Transactional
    public RechargeOrderResponse paymentCallback(String channelCode, PaymentCallbackRequest request) {
        if (!signatureMatches(request.signature())) {
            throw new BizException(ErrorCode.PAYMENT_CALLBACK_INVALID);
        }
        RechargeOrder order = rechargeOrderRepository.findByRechargeNoForUpdate(request.rechargeNo())
                .orElseThrow(() -> new BizException(ErrorCode.RECHARGE_ORDER_NOT_FOUND));
        if (!channelCode.equalsIgnoreCase(order.getChannelCode())) {
            throw new BizException(ErrorCode.PAYMENT_CHANNEL_UNSUPPORTED);
        }
        if (!order.getAmountFen().equals(request.paidFen())) {
            throw new BizException(ErrorCode.PAYMENT_CALLBACK_INVALID, "支付金额与充值订单不一致");
        }        if (order.getStatus() == RechargeOrderStatus.PAID) {
            if (request.externalTradeNo().equals(order.getExternalTradeNo())) {
                return RechargeOrderResponse.from(order);
            }
            throw new BizException(ErrorCode.RECHARGE_STATUS_ILLEGAL, "充值订单已支付，外部交易号不一致");
        }
        if (order.getStatus() != RechargeOrderStatus.PENDING) {
            throw new BizException(ErrorCode.RECHARGE_STATUS_ILLEGAL);
        }

        if (rechargeOrderRepository.findByExternalTradeNo(request.externalTradeNo()).isPresent()) {
            throw new BizException(ErrorCode.WALLET_DUPLICATE_OPERATION);
        }

        int updated = userRepository.addCredits(order.getUserId(), order.getCredits());
        if (updated == 0) {
            throw new BizException(ErrorCode.USER_NOT_FOUND);
        }
        User user = userRepository.findById(order.getUserId())
                .orElseThrow(() -> new BizException(ErrorCode.USER_NOT_FOUND));

        LocalDateTime paidAt = request.paidAt() == null ? LocalDateTime.now() : request.paidAt();
        order.setStatus(RechargeOrderStatus.PAID);
        order.setExternalTradeNo(request.externalTradeNo());
        order.setPaidAt(paidAt);
        RechargeOrder saved = rechargeOrderRepository.save(order);

        creditTransactionRepository.save(CreditTransaction.builder()
                .userId(order.getUserId())
                .type("RECHARGE")
                .amount(order.getCredits())
                .balanceAfter(user.getCredits())
                .moneyAmount(BigDecimal.valueOf(order.getAmountFen()).movePointLeft(2))
                .orderNo(order.getRechargeNo())
                .channel(channelCode)
                .status("SUCCESS")
                .remark("算力充值")
                .build());
        return RechargeOrderResponse.from(saved);
    }
    @Transactional
    public WithdrawRequestResponse createWithdrawal(Long userId, WithdrawCreateRequest request) {
        PaymentChannel channel = requireChannel(request.channelCode(), PaymentChannelDirection.WITHDRAW);
        validateAmount(request.amountFen(), channel, true);
        WalletAccount account = getAccountForUpdate(userId);
        if (account.getWithdrawableFen() < request.amountFen()) {
            throw new BizException(ErrorCode.WALLET_INSUFFICIENT_BALANCE);
        }

        account.freeze(request.amountFen());
        walletAccountRepository.save(account);
        String withdrawNo = nextNo("WD");
        String masked = maskAccount(request.accountNo());
        WithdrawRequest withdraw = withdrawRequestRepository.save(WithdrawRequest.builder()
                .withdrawNo(withdrawNo)
                .userId(userId)
                .amountFen(request.amountFen())
                .channelCode(channel.getCode())
                .accountName(request.accountName().trim())
                .accountNoMasked(masked)
                .accountSnapshotJson("{\"accountName\":\"" + request.accountName().trim()
                        + "\",\"accountNoMasked\":\"" + masked + "\"}")
                .status(WithdrawStatus.PENDING)
                .build());

        saveTransaction(
                userId,
                WalletTransactionType.WITHDRAW_FREEZE,
                request.amountFen(),
                account.getWithdrawableFen(),
                "WITHDRAW",
                withdraw.getId(),
                "提现冻结 · " + channel.getName());
        return WithdrawRequestResponse.from(withdraw);
    }

    @Transactional(readOnly = true)
    public WithdrawRequestResponse getWithdrawal(Long userId, Long id) {
        WithdrawRequest withdraw = withdrawRequestRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new BizException(ErrorCode.WITHDRAW_STATUS_ILLEGAL, "提现申请不存在"));
        return WithdrawRequestResponse.from(withdraw);
    }
    /** 后台处理提现。SUCCESS 扣减冻结，FAILED/CANCELLED 退回可提现余额。 */
    @Transactional
    public WithdrawRequestResponse updateWithdrawStatus(Long id, WithdrawStatusRequest request) {
        WithdrawRequest withdraw = withdrawRequestRepository.findByIdForUpdate(id)
                .orElseThrow(() -> new BizException(ErrorCode.WITHDRAW_STATUS_ILLEGAL, "提现申请不存在"));
        WithdrawStatus current = withdraw.getStatus();
        WithdrawStatus target = request.status();
        if (current == target) {
            return WithdrawRequestResponse.from(withdraw);
        }
        if (current.isTerminal()) {
            throw new BizException(ErrorCode.WITHDRAW_STATUS_ILLEGAL);
        }
        boolean valid = (current == WithdrawStatus.PENDING
                && (target == WithdrawStatus.PROCESSING
                || target == WithdrawStatus.FAILED
                || target == WithdrawStatus.CANCELLED))
                || (current == WithdrawStatus.PROCESSING
                && (target == WithdrawStatus.SUCCESS || target == WithdrawStatus.FAILED));
        if (!valid) {
            throw new BizException(ErrorCode.WITHDRAW_STATUS_ILLEGAL);
        }

        WalletAccount account = getAccountForUpdate(withdraw.getUserId());
        LocalDateTime now = LocalDateTime.now();
        if (target == WithdrawStatus.SUCCESS) {
            account.completeWithdrawal(withdraw.getAmountFen());
            walletAccountRepository.save(account);
            saveTransaction(
                    withdraw.getUserId(),
                    WalletTransactionType.WITHDRAW_SUCCESS,
                    withdraw.getAmountFen(),
                    account.getWithdrawableFen(),
                    "WITHDRAW",
                    withdraw.getId(),
                    "提现成功 · " + withdraw.getChannelCode());
        } else if (target == WithdrawStatus.FAILED || target == WithdrawStatus.CANCELLED) {
            account.refundWithdrawal(withdraw.getAmountFen());
            walletAccountRepository.save(account);
            saveTransaction(
                    withdraw.getUserId(),
                    WalletTransactionType.WITHDRAW_REFUND,
                    withdraw.getAmountFen(),
                    account.getWithdrawableFen(),
                    "WITHDRAW",
                    withdraw.getId(),
                    target == WithdrawStatus.FAILED ? "提现失败退回" : "提现取消退回");
        }

        withdraw.setStatus(target);
        withdraw.setFailureReason(normalizeOptional(request.failureReason()));
        withdraw.setExternalTradeNo(normalizeOptional(request.externalTradeNo()));
        if (target.isTerminal()) {
            withdraw.setProcessedAt(now);
        }
        return WithdrawRequestResponse.from(withdrawRequestRepository.save(withdraw));
    }

    /** 审核通过时给用户钱包入账；按 SUBMISSION 引用保证只入账一次。 */
    @Transactional
    public void creditOrderIncome(Long userId,
                                  Long submissionId,
                                  Long amountFen,
                                  String description) {
        if (amountFen == null || amountFen <= 0) {
            return;
        }
        if (walletTransactionRepository.existsByTypeAndReferenceTypeAndReferenceId(
                WalletTransactionType.ORDER_INCOME, "SUBMISSION", submissionId)) {
            return;
        }
        WalletAccount account = getAccountForUpdate(userId);
        account.addIncome(amountFen);
        walletAccountRepository.save(account);
        saveTransaction(
                userId,
                WalletTransactionType.ORDER_INCOME,
                amountFen,
                account.getWithdrawableFen(),
                "SUBMISSION",
                submissionId,
                description == null ? "订单收入" : description);
    }
    private WalletAccount getOrCreateAccount(Long userId) {
        return walletAccountRepository.findByUserId(userId).orElseGet(() ->
                walletAccountRepository.save(WalletAccount.builder().userId(userId).build()));
    }

    private WalletAccount getAccountForUpdate(Long userId) {
        return walletAccountRepository.findByUserIdForUpdate(userId)
                .orElseGet(() -> walletAccountRepository.save(
                        WalletAccount.builder().userId(userId).build()));
    }

    private PaymentChannel requireChannel(String code, PaymentChannelDirection direction) {
        PaymentChannel channel = paymentChannelRepository.findByCode(code)
                .filter(item -> Boolean.TRUE.equals(item.getEnabled()))
                .orElseThrow(() -> new BizException(ErrorCode.PAYMENT_CHANNEL_UNSUPPORTED));
        boolean supported = direction == PaymentChannelDirection.RECHARGE
                ? channel.getDirection().supportsRecharge()
                : channel.getDirection().supportsWithdraw();
        if (!supported) {
            throw new BizException(ErrorCode.PAYMENT_CHANNEL_UNSUPPORTED);
        }
        return channel;
    }

    private void validateAmount(Long amountFen, PaymentChannel channel, boolean withdraw) {
        long minimum = withdraw ? Math.max(MIN_WITHDRAW_FEN, channel.getMinFen()) : channel.getMinFen();
        if (amountFen == null || amountFen <= 0
                || amountFen < minimum
                || amountFen > channel.getMaxFen()) {
            throw new BizException(withdraw
                    ? ErrorCode.WITHDRAW_AMOUNT_INVALID
                    : ErrorCode.RECHARGE_AMOUNT_INVALID);
        }
    }

    private WalletTransaction saveTransaction(Long userId,
                                              WalletTransactionType type,
                                              Long amountFen,
                                              Long balanceAfterFen,
                                              String referenceType,
                                              Long referenceId,
                                              String description) {
        return walletTransactionRepository.save(WalletTransaction.builder()
                .transactionNo(nextNo("WT"))
                .userId(userId)
                .type(type)
                .amountFen(amountFen)
                .balanceAfterFen(balanceAfterFen)
                .referenceType(referenceType)
                .referenceId(referenceId)
                .description(description)
                .build());
    }

    private boolean signatureMatches(String signature) {
        if (signature == null) return false;
        return MessageDigest.isEqual(
                callbackSecret.getBytes(StandardCharsets.UTF_8),
                signature.getBytes(StandardCharsets.UTF_8));
    }

    private String maskAccount(String accountNo) {
        String value = accountNo == null ? "" : accountNo.trim();
        if (value.length() <= 4) return "****";
        return value.substring(0, Math.min(2, value.length() - 4))
                + "****"
                + value.substring(value.length() - 4);
    }

    private String normalizeOptional(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private Pageable pageRequest(int page, int pageSize) {
        int safePage = Math.max(1, page);
        int safeSize = Math.min(MAX_PAGE_SIZE, Math.max(1, pageSize));
        return PageRequest.of(safePage - 1, safeSize);
    }

    private String nextNo(String prefix) {
        int random = ThreadLocalRandom.current().nextInt(10000);
        return prefix + LocalDateTime.now().format(NO_FORMAT) + String.format("%04d", random);
    }
}