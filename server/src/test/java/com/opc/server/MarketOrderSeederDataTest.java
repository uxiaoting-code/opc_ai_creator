package com.opc.server;

import com.opc.server.init.MarketOrderSeeder;
import com.opc.server.repository.MarketOrderRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.transaction.annotation.Transactional;

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
}
