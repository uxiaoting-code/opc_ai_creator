package com.opc.server;

import com.opc.server.init.MarketOrderSeeder;
import com.opc.server.repository.MarketOrderRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@Transactional
class MarketOrderSeederDataTest {

    @Autowired
    private MarketOrderRepository repository;

    @Test
    void insertsThreeNewDemoOrdersWithoutDuplicates() {
        MarketOrderSeeder seeder = new MarketOrderSeeder(repository);

        seeder.run(null);
        seeder.run(null);

        assertThat(repository.count()).isEqualTo(9);
        assertThat(repository.findByOrderNo("MO202611050001")).isPresent();
        assertThat(repository.findByOrderNo("MO202611050002")).isPresent();
        assertThat(repository.findByOrderNo("MO202611050003")).isPresent();
    }

    @Test
    void refreshesExpiredDemoOrderDeadlineOnRestart() {
        MarketOrderSeeder seeder = new MarketOrderSeeder(repository);
        seeder.run(null);

        var expired = repository.findByOrderNo("MO202611050001").orElseThrow();
        expired.setDeadlineAt(LocalDateTime.now().minusDays(1));
        repository.save(expired);

        seeder.run(null);

        var refreshed = repository.findByOrderNo("MO202611050001").orElseThrow();
        assertThat(refreshed.getDeadlineAt()).isAfter(LocalDateTime.now());
        assertThat(repository.count()).isEqualTo(9);
    }
}
