package com.opc.server.init;

import com.opc.server.entity.User;
import com.opc.server.entity.WalletAccount;
import com.opc.server.entity.WalletTransaction;
import com.opc.server.entity.enums.WalletTransactionType;
import com.opc.server.repository.UserRepository;
import com.opc.server.repository.WalletAccountRepository;
import com.opc.server.repository.WalletTransactionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** 钱包演示数据（M3）。 */
@Component
@Order(10)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled", havingValue = "true", matchIfMissing = true)
public class WalletSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(WalletSeeder.class);

    private final UserRepository userRepository;
    private final WalletAccountRepository walletAccountRepository;
    private final WalletTransactionRepository walletTransactionRepository;

    public WalletSeeder(UserRepository userRepository,
                        WalletAccountRepository walletAccountRepository,
                        WalletTransactionRepository walletTransactionRepository) {
        this.userRepository = userRepository;
        this.walletAccountRepository = walletAccountRepository;
        this.walletTransactionRepository = walletTransactionRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        User demo = userRepository.findByUsernameAndDeletedFalse("demo").orElse(null);
        if (demo == null || walletAccountRepository.findByUserId(demo.getId()).isPresent()) {
            return;
        }
        WalletAccount account = walletAccountRepository.save(WalletAccount.builder()
                .userId(demo.getId())
                .withdrawableFen(36800L)
                .frozenFen(0L)
                .totalIncomeFen(36800L)
                .totalWithdrawnFen(0L)
                .build());
        walletTransactionRepository.save(WalletTransaction.builder()
                .transactionNo("WT20261030000001")
                .userId(demo.getId())
                .type(WalletTransactionType.ORDER_INCOME)
                .amountFen(36800L)
                .balanceAfterFen(account.getWithdrawableFen())
                .referenceType("SEED")
                .referenceId(1L)
                .description("演示订单收入")
                .build());
        log.info("已初始化 demo 用户钱包演示数据");
    }
}