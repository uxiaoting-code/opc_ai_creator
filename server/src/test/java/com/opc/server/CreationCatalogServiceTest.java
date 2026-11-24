package com.opc.server;

import com.opc.server.entity.AiProviderConfig;
import com.opc.server.repository.AiProviderConfigRepository;
import com.opc.server.service.CreationCatalogService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CreationCatalogServiceTest {

    @Mock
    private AiProviderConfigRepository repository;

    @InjectMocks
    private CreationCatalogService catalogService;

    @Test
    void returnsPublicFieldsForRequestedMediaType() {
        when(repository.findByTypeAndOnlineTrueAndDeletedFalseOrderBySortOrderAscIdAsc("IMAGE"))
                .thenReturn(List.of(config("TT Image 2", "IMAGE", "tt-image-2")));

        var models = catalogService.models("image");

        assertThat(models).hasSize(1);
        assertThat(models.getFirst().name()).isEqualTo("TT Image 2");
        assertThat(models.getFirst().modelName()).isEqualTo("tt-image-2");
    }

    private AiProviderConfig config(String name, String type, String modelName) {
        return AiProviderConfig.builder()
                .name(name)
                .vendor("测试厂商")
                .type(type)
                .channel("test-channel")
                .modelName(modelName)
                .providerImpl("mock")
                .authType("NONE")
                .requestMethod("POST")
                .requestContentType("application/json")
                .inputPrice(BigDecimal.ZERO)
                .outputPrice(BigDecimal.ZERO)
                .priceUnit("CALL")
                .timeoutSeconds(60)
                .online(true)
                .sortOrder(1)
                .deleted(false)
                .build();
        // ID 由 BaseEntity/数据库生成；这里仅验证服务过滤和公开字段映射。
    }
}
