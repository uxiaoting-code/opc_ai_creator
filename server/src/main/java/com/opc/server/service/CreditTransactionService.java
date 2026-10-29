package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.BillResponse;
import com.opc.server.dto.BillSummaryResponse;
import com.opc.server.dto.CreditByModelItem;
import com.opc.server.dto.CreditStatsResponse;
import com.opc.server.dto.ModelShareItem;
import com.opc.server.dto.OverviewResponse;
import com.opc.server.dto.RechargeRequest;
import com.opc.server.dto.TopUserItem;
import com.opc.server.dto.TrendPoint;
import com.opc.server.entity.CallLog;
import com.opc.server.entity.CreditTransaction;
import com.opc.server.entity.User;
import com.opc.server.entity.enums.ToolKind;
import com.opc.server.repository.CallLogRepository;
import com.opc.server.repository.CreditTransactionRepository;
import com.opc.server.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 算力流水 / 账单 / 数据概览 / 算力统计（需求 1.3 与 3.4）。
 *
 * <p>所有算力变动都经过这里落一条 {@code t_credit_transaction}，
 * 账单页与统计页都从这张表算，避免两套口径。
 */
@Service
public class CreditTransactionService {

    private static final DateTimeFormatter ORDER_TIME =
            DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final CreditTransactionRepository txnRepository;
    private final UserRepository userRepository;
    private final CallLogRepository callLogRepository;

    public CreditTransactionService(CreditTransactionRepository txnRepository,
                                    UserRepository userRepository,
                                    CallLogRepository callLogRepository) {
        this.txnRepository = txnRepository;
        this.userRepository = userRepository;
        this.callLogRepository = callLogRepository;
    }

    // =========================================================================
    // 写流水
    // =========================================================================

    @Transactional
    public CreditTransaction record(User user, String type, int amount,
                                    BigDecimal moneyAmount, String channel,
                                    String status, String remark, Long refTaskId) {
        CreditTransaction txn = CreditTransaction.builder()
                .userId(user.getId())
                .type(type)
                .amount(amount)
                .balanceAfter(user.getCredits() == null ? 0 : user.getCredits())
                .moneyAmount(moneyAmount)
                .orderNo(nextOrderNo(type))
                .channel(channel)
                .status(status == null ? "SUCCESS" : status)
                .remark(remark)
                .refTaskId(refTaskId)
                .build();
        return txnRepository.save(txn);
    }

    public CreditTransaction recordConsume(User user, int cost, Long taskId, String taskNo) {
        return record(user, "CONSUME", -Math.abs(cost), null,
                "算力余额", "SUCCESS", "任务消耗：" + taskNo, taskId);
    }

    public CreditTransaction recordAdjust(User user, int delta, String remark) {
        return record(user, "ADMIN_ADJUST", delta, null,
                "后台调整", "SUCCESS", remark, null);
    }

    // =========================================================================
    // 账单
    // =========================================================================

    @Transactional(readOnly = true)
    public PageResult<BillResponse> bills(int page, int pageSize, String type,
                                          LocalDate startDate, LocalDate endDate,
                                          String keyword) {
        final String typeValue = (type == null || type.isBlank())
                ? null : type.trim().toUpperCase();
        final LocalDateTime start = startDate == null ? null : startDate.atStartOfDay();
        final LocalDateTime end = endDate == null ? null : endDate.atTime(23, 59, 59);
        final String like = (keyword == null || keyword.isBlank())
                ? null : "%" + keyword.trim().toLowerCase() + "%";

        Specification<CreditTransaction> spec = (root, query, cb) -> cb.conjunction();
        if (typeValue != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("type"), typeValue));
        }
        if (start != null) {
            spec = spec.and((root, query, cb) ->
                    cb.greaterThanOrEqualTo(root.get("createdAt"), start));
        }
        if (end != null) {
            spec = spec.and((root, query, cb) ->
                    cb.lessThanOrEqualTo(root.get("createdAt"), end));
        }
        if (like != null) {
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(root.<String>get("orderNo")), like),
                    cb.like(cb.lower(root.<String>get("remark")), like)
            ));
        }

        int safePage = Math.max(1, page);
        int safeSize = Math.min(Math.max(1, pageSize), 100);
        Page<CreditTransaction> result = txnRepository.findAll(spec,
                PageRequest.of(safePage - 1, safeSize, Sort.by(Sort.Direction.DESC, "id")));
        Map<Long, String> names = userNames(result.getContent());
        return PageResult.from(result,
                t -> BillResponse.from(t, names.getOrDefault(t.getUserId(), "用户" + t.getUserId())));
    }

    @Transactional(readOnly = true)
    public BillSummaryResponse summary(LocalDate date) {
        LocalDate day = date == null ? LocalDate.now() : date;
        List<CreditTransaction> list = txnRepository
                .findByCreatedAtBetweenOrderByCreatedAtAsc(
                        day.atStartOfDay(), day.atTime(23, 59, 59));
        BigDecimal recharge = BigDecimal.ZERO;
        BigDecimal consume = BigDecimal.ZERO;
        for (CreditTransaction txn : list) {
            if ("RECHARGE".equals(txn.getType())) {
                recharge = recharge.add(moneyOf(txn));
            } else if ("CONSUME".equals(txn.getType())) {
                consume = consume.add(moneyOf(txn).abs());
            }
        }
        return new BillSummaryResponse(list.size(), recharge, consume);
    }

    @Transactional
    public BillResponse recharge(RechargeRequest request) {
        if (request == null || request.userId() == null
                || request.amount() == null
                || request.amount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "userId 与大于 0 的 amount 不能为空");
        }
        User user = userRepository.findByIdAndDeletedFalse(request.userId())
                .orElseThrow(() -> new BizException(ErrorCode.ADMIN_USER_NOT_FOUND));
        int credits = request.amount().intValue();
        user.setCredits((user.getCredits() == null ? 0 : user.getCredits()) + credits);
        User saved = userRepository.save(user);
        CreditTransaction txn = record(saved, "RECHARGE", credits, request.amount(),
                defaultIfBlank(request.channel(), "后台充值"), "SUCCESS",
                defaultIfBlank(request.remark(), "后台模拟充值"), null);
        return BillResponse.from(txn, displayName(saved));
    }

    @Transactional
    public BillResponse refund(Long transactionId, String remark) {
        CreditTransaction source = txnRepository.findById(transactionId)
                .orElseThrow(() -> new BizException(ErrorCode.ADMIN_RESOURCE_NOT_FOUND,
                        "账单流水不存在"));
        if (!"RECHARGE".equals(source.getType())) {
            throw new BizException(ErrorCode.ADMIN_OPERATION_NOT_ALLOWED,
                    "只有充值流水可以退款");
        }
        User user = userRepository.findByIdAndDeletedFalse(source.getUserId())
                .orElseThrow(() -> new BizException(ErrorCode.ADMIN_USER_NOT_FOUND));
        int refundCredits = source.getAmount() == null ? 0 : source.getAmount();
        user.setCredits(Math.max(0,
                (user.getCredits() == null ? 0 : user.getCredits()) - refundCredits));
        User saved = userRepository.save(user);
        CreditTransaction txn = record(saved, "REFUND", -refundCredits,
                moneyOf(source).negate(), "原路退回", "SUCCESS",
                defaultIfBlank(remark, "后台退款"), null);
        return BillResponse.from(txn, displayName(saved));
    }

    // =========================================================================
    // 概览
    // =========================================================================

    @Transactional(readOnly = true)
    public OverviewResponse overview() {
        LocalDate today = LocalDate.now();
        LocalDate yesterday = today.minusDays(1);

        long totalUsers = userRepository.countByDeletedFalse();
        long activeToday = userRepository.countByDeletedFalseAndLastActiveAtAfter(today.atStartOfDay());
        long activeYesterday = userRepository.countByDeletedFalseAndLastActiveAtBetween(
                yesterday.atStartOfDay(), yesterday.atTime(23, 59, 59));

        BigDecimal revenueToday = sumMoney("RECHARGE", today);
        BigDecimal revenueYesterday = sumMoney("RECHARGE", yesterday);
        long creditsToday = sumConsumeCredits(today);
        long creditsYesterday = sumConsumeCredits(yesterday);

        return new OverviewResponse(
                totalUsers, null,
                activeToday, delta(activeToday, activeYesterday),
                revenueToday, delta(revenueToday, revenueYesterday),
                creditsToday, delta(creditsToday, creditsYesterday)
        );
    }

    @Transactional(readOnly = true)
    public List<TrendPoint> revenueTrend(int days) {
        int safeDays = Math.min(Math.max(1, days), 90);
        LocalDate today = LocalDate.now();
        LocalDate start = today.minusDays(safeDays - 1L);
        List<CreditTransaction> list = txnRepository
                .findByCreatedAtBetweenOrderByCreatedAtAsc(
                        start.atStartOfDay(), today.atTime(23, 59, 59));

        Map<LocalDate, BigDecimal> byDate = new HashMap<>();
        for (CreditTransaction txn : list) {
            if ("RECHARGE".equals(txn.getType())) {
                LocalDate d = txn.getCreatedAt().toLocalDate();
                byDate.merge(d, moneyOf(txn), BigDecimal::add);
            }
        }
        List<TrendPoint> points = new ArrayList<>();
        for (int i = 0; i < safeDays; i++) {
            LocalDate d = start.plusDays(i);
            points.add(new TrendPoint(d.toString(),
                    byDate.getOrDefault(d, BigDecimal.ZERO)));
        }
        return points;
    }

    @Transactional(readOnly = true)
    public List<ModelShareItem> modelShare(String range) {
        LocalDateTime start = rangeStart(range);
        List<CallLog> logs = callLogRepository.findAll(
                (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("createdAt"), start));
        Map<String, Long> counts = logs.stream()
                .collect(Collectors.groupingBy(
                        l -> l.getToolKind() == null ? "UNKNOWN" : l.getToolKind(),
                        LinkedHashMap::new, Collectors.counting()));
        long total = counts.values().stream().mapToLong(Long::longValue).sum();
        return counts.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .map(e -> new ModelShareItem(
                        ToolKind.labelOf(e.getKey()), e.getValue(),
                        percent(e.getValue(), total)))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BillResponse> recentOrders(int limit) {
        int safeLimit = Math.min(Math.max(1, limit), 50);
        List<CreditTransaction> list = txnRepository.findAllByOrderByCreatedAtDesc()
                .stream().limit(safeLimit).toList();
        Map<Long, String> names = userNames(list);
        return list.stream()
                .map(t -> BillResponse.from(t, names.getOrDefault(t.getUserId(), "用户" + t.getUserId())))
                .toList();
    }

    // =========================================================================
    // 算力统计
    // =========================================================================

    @Transactional(readOnly = true)
    public CreditStatsResponse stats(String range) {
        LocalDate today = LocalDate.now();
        long todayUsed = sumConsumeCredits(today);
        long yesterdayUsed = sumConsumeCredits(today.minusDays(1));
        long monthUsed = sumConsumeCreditsBetween(
                today.withDayOfMonth(1), today);
        long lastMonthUsed = sumConsumeCreditsBetween(
                today.minusMonths(1).withDayOfMonth(1),
                today.withDayOfMonth(1).minusDays(1));

        long stock = userRepository.sumCredits() == null ? 0 : userRepository.sumCredits();
        long avg = averageDaily(today, 7);
        Integer stockDays = avg <= 0 ? null
                : (int) Math.min(Integer.MAX_VALUE, stock / avg);

        return new CreditStatsResponse(
                todayUsed, delta(todayUsed, yesterdayUsed),
                yesterdayUsed, monthUsed, delta(monthUsed, lastMonthUsed),
                stock, stockDays);
    }

    @Transactional(readOnly = true)
    public List<CreditByModelItem> byModel(String range) {
        LocalDateTime start = rangeStart(range);
        List<CallLog> logs = callLogRepository.findAll(
                (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("createdAt"), start));

        Map<String, List<CallLog>> grouped = logs.stream()
                .collect(Collectors.groupingBy(
                        l -> l.getToolKind() == null ? "UNKNOWN" : l.getToolKind()));
        long totalCalls = logs.size();
        List<CreditByModelItem> items = new ArrayList<>();
        for (Map.Entry<String, List<CallLog>> entry : grouped.entrySet()) {
            long calls = entry.getValue().size();
            long credits = entry.getValue().stream()
                    .map(CallLog::getCredits)
                    .filter(c -> c != null)
                    .mapToLong(BigDecimal::longValue)
                    .sum();
            items.add(new CreditByModelItem(
                    ToolKind.labelOf(entry.getKey()), calls, null, null,
                    credits, percent(calls, totalCalls)));
        }
        items.sort(Comparator.comparingLong(CreditByModelItem::calls).reversed());
        return items;
    }

    @Transactional(readOnly = true)
    public List<TopUserItem> topUsers(int limit) {
        int safeLimit = Math.min(Math.max(1, limit), 50);
        LocalDate today = LocalDate.now();
        List<CreditTransaction> list = txnRepository
                .findByCreatedAtBetweenOrderByCreatedAtAsc(
                        today.atStartOfDay(), today.atTime(23, 59, 59));
        if (list.stream().noneMatch(t -> "CONSUME".equals(t.getType()))) {
            list = txnRepository.findAllByOrderByCreatedAtDesc();
        }

        Map<Long, Long> used = new HashMap<>();
        for (CreditTransaction txn : list) {
            if ("CONSUME".equals(txn.getType())) {
                used.merge(txn.getUserId(),
                        (long) Math.abs(txn.getAmount() == null ? 0 : txn.getAmount()),
                        Long::sum);
            }
        }
        Map<Long, String> names = userNames(list);
        List<Map.Entry<Long, Long>> sorted = used.entrySet().stream()
                .sorted(Map.Entry.<Long, Long>comparingByValue().reversed())
                .limit(safeLimit)
                .toList();
        List<TopUserItem> result = new ArrayList<>();
        int rank = 1;
        for (Map.Entry<Long, Long> entry : sorted) {
            result.add(new TopUserItem(rank++, entry.getKey(),
                    names.getOrDefault(entry.getKey(), "用户" + entry.getKey()),
                    entry.getValue()));
        }
        return result;
    }

    // =========================================================================
    // 内部工具
    // =========================================================================

    private BigDecimal sumMoney(String type, LocalDate day) {
        return txnRepository.findByCreatedAtBetweenOrderByCreatedAtAsc(
                        day.atStartOfDay(), day.atTime(23, 59, 59)).stream()
                .filter(t -> type.equals(t.getType()))
                .map(this::moneyOf)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private long sumConsumeCredits(LocalDate day) {
        return sumConsumeCreditsBetween(day, day);
    }

    private long sumConsumeCreditsBetween(LocalDate start, LocalDate end) {
        return txnRepository.findByCreatedAtBetweenOrderByCreatedAtAsc(
                        start.atStartOfDay(), end.atTime(23, 59, 59)).stream()
                .filter(t -> "CONSUME".equals(t.getType()))
                .mapToLong(t -> Math.abs(t.getAmount() == null ? 0 : t.getAmount()))
                .sum();
    }

    private long averageDaily(LocalDate today, int days) {
        long total = 0;
        for (int i = 0; i < days; i++) {
            total += sumConsumeCredits(today.minusDays(i));
        }
        return total / days;
    }

    private Map<Long, String> userNames(List<CreditTransaction> list) {
        Set<Long> ids = list.stream().map(CreditTransaction::getUserId)
                .filter(id -> id != null).collect(Collectors.toSet());
        if (ids.isEmpty()) {
            return Map.of();
        }
        return userRepository.findAllById(ids).stream()
                .collect(Collectors.toMap(User::getId, CreditTransactionService::displayName, (a, b) -> a));
    }

    private BigDecimal moneyOf(CreditTransaction txn) {
        if (txn.getMoneyAmount() != null) {
            return txn.getMoneyAmount();
        }
        int amount = txn.getAmount() == null ? 0 : Math.abs(txn.getAmount());
        return BigDecimal.valueOf(amount);
    }

    private LocalDateTime rangeStart(String range) {
        LocalDate today = LocalDate.now();
        if ("month".equalsIgnoreCase(range)) {
            return today.withDayOfMonth(1).atStartOfDay();
        }
        if ("all".equalsIgnoreCase(range)) {
            return LocalDateTime.of(1970, 1, 1, 0, 0);
        }
        return today.atStartOfDay();
    }

    private double percent(long value, long total) {
        if (total <= 0) {
            return 0;
        }
        return BigDecimal.valueOf(value * 100.0 / total)
                .setScale(1, RoundingMode.HALF_UP).doubleValue();
    }

    private Double delta(long today, long yesterday) {
        if (yesterday == 0) {
            return today == 0 ? 0.0 : null;
        }
        return BigDecimal.valueOf((today - yesterday) * 100.0 / yesterday)
                .setScale(1, RoundingMode.HALF_UP).doubleValue();
    }

    private Double delta(BigDecimal today, BigDecimal yesterday) {
        if (yesterday == null || yesterday.compareTo(BigDecimal.ZERO) == 0) {
            return today == null || today.compareTo(BigDecimal.ZERO) == 0 ? 0.0 : null;
        }
        return today.subtract(yesterday)
                .multiply(BigDecimal.valueOf(100))
                .divide(yesterday, 1, RoundingMode.HALF_UP)
                .doubleValue();
    }

    private String nextOrderNo(String type) {
        String prefix = switch (type == null ? "" : type) {
            case "RECHARGE" -> "P";
            case "CONSUME" -> "C";
            case "REFUND" -> "R";
            case "GIFT" -> "G";
            default -> "A";
        };
        int random = (int) (Math.random() * 1000);
        return prefix + LocalDateTime.now().format(ORDER_TIME)
                + String.format("%03d", random);
    }

    private static String displayName(User user) {
        return user.getNickname() == null || user.getNickname().isBlank()
                ? user.getUsername() : user.getNickname();
    }

    private static String defaultIfBlank(String value, String fallback) {
        return (value == null || value.isBlank()) ? fallback : value;
    }
}
