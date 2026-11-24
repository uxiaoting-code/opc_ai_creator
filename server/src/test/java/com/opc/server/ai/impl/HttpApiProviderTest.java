package com.opc.server.ai.impl;

import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.ProviderRuntimeConfig;
import com.opc.server.entity.enums.TaskType;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class HttpApiProviderTest {

    @Test
    void selectedProviderModelOverridesSkillSnapshotModelName() {
        ProviderRuntimeConfig config = new ProviderRuntimeConfig(
                "http",
                "火山 Seedream",
                "doubao-seedream-5-5-261028",
                "IMAGE",
                "https://ark.cn-beijing.volces.com/api/v3",
                "NONE",
                null,
                null,
                null,
                "POST",
                "/images/generations",
                "application/json",
                null,
                null,
                "{\"model\":\"{{modelName}}\",\"prompt\":\"{{prompt}}\"}",
                null,
                "data.0.url",
                null,
                "error.message",
                null,
                30);
        AiTaskRequest request = new AiTaskRequest(
                "task-001",
                TaskType.TEXT_TO_IMAGE,
                "一只橘猫",
                null,
                null,
                "anime_v1",
                "doubao-seedream-5-5-261028",
                28,
                7.5,
                1024,
                1024,
                null,
                0,
                Map.of("modelName", "sd-xl-anime"));

        Map<String, String> vars = new HttpApiProvider(new ObjectMapper())
                .buildVars(config, request);

        assertThat(vars.get("modelName"))
                .isEqualTo("doubao-seedream-5-5-261028");
    }
}
