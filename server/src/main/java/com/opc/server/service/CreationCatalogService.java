package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.CreationModelResponse;
import com.opc.server.repository.AiProviderConfigRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.Set;

/** 用户端创作模型目录：只返回已上架、且不包含敏感配置的模型。 */
@Service
public class CreationCatalogService {

    private static final Set<String> ALLOWED_TYPES = Set.of("IMAGE", "VIDEO", "AUDIO");

    private final AiProviderConfigRepository providerRepository;

    public CreationCatalogService(AiProviderConfigRepository providerRepository) {
        this.providerRepository = providerRepository;
    }

    @Transactional(readOnly = true)
    public List<CreationModelResponse> models(String mediaType) {
        String type = normalizeType(mediaType);
        return providerRepository
                .findByTypeAndOnlineTrueAndDeletedFalseOrderBySortOrderAscIdAsc(type)
                .stream()
                .map(CreationModelResponse::from)
                .toList();
    }

    private String normalizeType(String mediaType) {
        if (mediaType == null || mediaType.isBlank()) {
            throw new BizException(ErrorCode.BAD_REQUEST, "mediaType 不能为空");
        }
        String value = mediaType.trim().toUpperCase(Locale.ROOT);
        if (!ALLOWED_TYPES.contains(value)) {
            throw new BizException(
                    ErrorCode.BAD_REQUEST,
                    "mediaType 必须是 IMAGE / VIDEO / AUDIO"
            );
        }
        return value;
    }
}
