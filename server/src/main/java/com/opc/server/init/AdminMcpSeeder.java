package com.opc.server.init;

import com.opc.server.dto.McpServerRequest;
import com.opc.server.dto.McpServerResponse;
import com.opc.server.repository.McpServerRepository;
import com.opc.server.service.McpService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** MCP 演示数据：一个 mock:// 服务端 + 3 个工具。 */
@Component
@Order(5)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled",
        havingValue = "true", matchIfMissing = true)
public class AdminMcpSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminMcpSeeder.class);

    private final McpServerRepository serverRepository;
    private final McpService mcpService;

    public AdminMcpSeeder(McpServerRepository serverRepository, McpService mcpService) {
        this.serverRepository = serverRepository;
        this.mcpService = mcpService;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (serverRepository.countByDeletedFalse() > 0) {
            log.info("MCP 服务端已存在，跳过初始化");
            return;
        }
        McpServerResponse server = mcpService.createServer(new McpServerRequest(
                "Mock MCP Server", "HTTP", "mock://demo",
                null, null, "NONE", null));
        int count = mcpService.discover(server.id()).size();
        log.info("已初始化 MCP 演示服务端，发现 {} 个工具", count);
    }
}
