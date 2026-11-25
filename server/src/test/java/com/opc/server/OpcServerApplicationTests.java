package com.opc.server;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:opc-context-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "opc.seed.enabled=false",
        "opc.security.dev-token-enabled=false"
})
class OpcServerApplicationTests {

    @Test
    void contextLoads() {
    }
}