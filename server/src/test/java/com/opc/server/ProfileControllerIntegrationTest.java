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
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.MOCK,
        properties = {
                "spring.datasource.url=jdbc:h2:mem:profile-http-test;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "opc.seed.enabled=false",
                "opc.security.dev-token-enabled=false"
        })
@AutoConfigureMockMvc
class ProfileControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TokenService tokenService;

    private User user;
    private String token;

    @BeforeEach
    void setUp() {
        user = userRepository.findByUsernameAndDeletedFalse("profile-http-user")
                .orElseGet(() -> userRepository.save(User.builder()
                        .username("profile-http-user")
                        .password("x")
                        .nickname("接口统计测试")
                        .role("USER")
                        .credits(3210)
                        .status(1)
                        .deleted(false)
                        .build()));
        token = tokenService.issue(user.getId(), user.getUsername());
    }

    @Test
    void requiresLogin() throws Exception {
        mockMvc.perform(get("/api/profile/stats"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void returnsCurrentUserStatsWithAuth() throws Exception {
        mockMvc.perform(get("/api/profile/stats")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.credits").value(3210))
                .andExpect(jsonPath("$.data.withdrawableFen").value(0))
                .andExpect(jsonPath("$.data.pendingReviewCount").value(0))
                .andExpect(jsonPath("$.data.taskStats.QUEUED").value(0));
    }
}