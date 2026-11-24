package com.opc.server.dto;

import com.opc.server.entity.AiProviderConfig;
import com.opc.server.entity.enums.ProviderType;

/**
 * 用户端可选择的模型通道。
 *
 * <p>只暴露选择所需的公开字段，绝不能把 Base URL、API Key、请求模板等
 * 服务端配置返回给 Flutter。
 */
public record CreationModelResponse(
        Long id,
        String name,
        String vendor,
        String type,
        String typeLabel,
        String modelName
) {

    public static CreationModelResponse from(AiProviderConfig config) {
        return new CreationModelResponse(
                config.getId(),
                config.getName(),
                config.getVendor(),
                config.getType(),
                ProviderType.labelOf(config.getType()),
                config.getModelName()
        );
    }
}
