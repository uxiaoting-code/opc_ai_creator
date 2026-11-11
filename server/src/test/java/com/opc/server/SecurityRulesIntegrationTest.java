package com.opc.server;

import com.opc.server.entity.User;
import com.opc.server.repository.UserRepository;
import com.opc.server.security.TokenService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.MOCK,
        properties = {
                "spring.datasource.url=jdbc:h2:mem:security-rules-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "opc.seed.enabled=false",
                "opc.security.dev-token-enabled=true"
        })
@AutoConfigureMockMvc
class SecurityRulesIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TokenService tokenService;

    private User user;

    @BeforeEach
    void setUp() {
        user = userRepository.findByUsernameAndDeletedFalse("security-user")
                .orElseGet(() -> userRepository.save(User.builder()
                        .username("security-user")
                        .password("x")
                        .nickname("安全测试")
                        .role("USER")
                        .credits(1000)
                        .status(1)
                        .deleted(false)
                        .build()));
    }

    @Test
    void developmentTokenCannotAccessAdminApi() throws Exception {
        mockMvc.perform(get("/api/admin/users")
                        .header("Authorization", "Bearer mock-token-for-scaffold"))
                .andExpect(status().isForbidden());
    }

    @Test
    void normalUserCannotAccessAdminApi() throws Exception {
        String token = tokenService.issue(user.getId(), user.getUsername());

        mockMvc.perform(get("/api/admin/users")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());
    }
}