package com.opc.server.service;

import com.opc.server.ai.ProviderNames;
import com.opc.server.ai.ProviderRuntimeConfig;
import com.opc.server.ai.ProviderTestResult;
import com.opc.server.ai.impl.HttpApiProvider;
import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.ProviderAuthRequest;
import com.opc.server.dto.ProviderCreateRequest;
import com.opc.server.dto.ProviderDetailResponse;
import com.opc.server.dto.ProviderPricingRequest;
import com.opc.server.dto.ProviderRequestTemplateRequest;
import com.opc.server.dto.ProviderResponse;
import com.opc.server.dto.ProviderResponseTemplateRequest;
import com.opc.server.dto.ProviderTestRequest;
import com.opc.server.dto.ProviderTestResponse;
import com.opc.server.entity.AiProviderConfig;
import com.opc.server.entity.enums.AuthType;
import com.opc.server.entity.enums.PriceUnit;
import com.opc.server.entity.enums.ProviderType;
import com.opc.server.repository.AiProviderConfigRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Set;
import java.util.UUID;

/**
 * 模型 / API 配置服务（需求 3.1 的六步流水线）。
 *
 * <p>菜单归属：管理端「大模型配置」页（{@code pg-models}）。
 */
@Service
public class AiProviderConfigService {

    private static final Set<String> ALLOWED_IMPLS =
            Set.of(ProviderNames.MOCK, ProviderNames.STABLE_DIFFUSION, ProviderNames.HTTP);

    private static final Set<String> ALLOWED_HTTP_METHODS =
            Set.of("GET", "POST", "PUT", "PATCH", "DELETE");

    private final AiProviderConfigRepository repository;
    private final HttpApiProvider httpApiProvider;

    public AiProviderConfigService(AiProviderConfigRepository repository,
                                   HttpApiProvider httpApiProvider) {
        this.repository = repository;
        this.httpApiProvider = httpApiProvider;
    }

    // =========================================================================
    // 查询
    // =========================================================================

    @Transactional(readOnly = true)
    public PageResult<ProviderResponse> list(int page, int pageSize, String type, String keyword) {
        final String typeValue = resolveTypeFilter(type);
        final String like = (keyword == null || keyword.isBlank())
                ? null
                : "%" + keyword.trim().toLowerCase() + "%";

        Specification<AiProviderConfig> spec = (root, query, cb) ->
                cb.equal(root.get("deleted"), false);

        if (typeValue != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("type"), typeValue));
        }
        if (like != null) {
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(root.<String>get("name")), like),
                    cb.like(cb.lower(root.<String>get("vendor")), like),
                    cb.like(cb.lower(root.<String>get("channel")), like)
            ));
        }

        int safePage = Math.max(1, page);
        int safeSize = Math.min(Math.max(1, pageSize), 100);
        Page<AiProviderConfig> result = repository.findAll(spec,
                PageRequest.of(safePage - 1, safeSize,
                        Sort.by(Sort.Direction.ASC, "sortOrder")
                                .and(Sort.by(Sort.Direction.ASC, "id"))));
        return PageResult.from(result, ProviderResponse::from);
    }

    @Transactional(readOnly = true)
    public ProviderDetailResponse detail(Long id) {
        return ProviderDetailResponse.from(load(id));
    }

    // =========================================================================
    // 增改
    // =========================================================================

    @Transactional
    public ProviderResponse create(ProviderCreateRequest request) {
        ProviderType type = requireType(request.type());
        PriceUnit priceUnit = requirePriceUnit(request.priceUnit());
        String impl = requireProviderImpl(request.providerImpl(), ProviderNames.MOCK);

        AiProviderConfig config = AiProviderConfig.builder()
                .name(request.name().trim())
                .vendor(trimToNull(request.vendor()))
                .type(type.name())
                .channel(requireChannel(request.channel(), null))
                .modelName(trimToNull(request.modelName()))
                .baseUrl(trimToNull(request.baseUrl()))
                .providerImpl(impl)
                .inputPrice(request.inputPrice())
                .outputPrice(request.outputPrice())
                .priceUnit(priceUnit.name())
                .timeoutSeconds(normalizeTimeout(request.timeoutSeconds()))
                .sortOrder(request.sortOrder() == null ? 0 : request.sortOrder())
                .remark(trimToNull(request.remark()))
                .online(false)
                .deleted(false)
                .build();

        return ProviderResponse.from(repository.save(config));
    }

    @Transactional
    public ProviderResponse update(Long id, ProviderCreateRequest request) {
        AiProviderConfig config = load(id);
        ProviderType type = requireType(request.type());
        PriceUnit priceUnit = requirePriceUnit(request.priceUnit());
        String impl = requireProviderImpl(request.providerImpl(), config.getProviderImpl());

        String channel = requireChannel(request.channel(), id);
        if (channel != null && !channel.equals(config.getChannel())) {
            config.setChannel(channel);
        }

        config.setName(request.name().trim());
        config.setVendor(trimToNull(request.vendor()));
        config.setType(type.name());
        config.setModelName(trimToNull(request.modelName()));
        config.setBaseUrl(trimToNull(request.baseUrl()));
        config.setProviderImpl(impl);
        config.setInputPrice(request.inputPrice());
        config.setOutputPrice(request.outputPrice());
        config.setPriceUnit(priceUnit.name());
        config.setTimeoutSeconds(normalizeTimeout(request.timeoutSeconds()));
        if (request.sortOrder() != null) {
            config.setSortOrder(request.sortOrder());
        }
        config.setRemark(trimToNull(request.remark()));

        return ProviderResponse.from(repository.save(config));
    }

    @Transactional
    public ProviderDetailResponse updateAuth(Long id, ProviderAuthRequest request) {
        AiProviderConfig config = load(id);
        AuthType authType = AuthType.parse(request.authType());
        if (authType == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "authType 必须是 NONE / API_KEY / OAUTH / CUSTOM_HEADER");
        }

        config.setAuthType(authType.name());
        config.setHeaderName(trimToNull(request.headerName()));
        config.setHeaderValue(trimToNull(request.headerValue()));
        config.setOauthTokenUrl(trimToNull(request.oauthTokenUrl()));
        config.setOauthClientId(trimToNull(request.oauthClientId()));

        // 前端回传的是脱敏值（****1234）时，不能覆盖真实密钥
        if (hasNewSecret(request.apiKey())) {
            config.setApiKey(request.apiKey().trim());
        }
        if (hasNewSecret(request.oauthClientSecret())) {
            config.setOauthClientSecret(request.oauthClientSecret().trim());
        }

        return ProviderDetailResponse.from(repository.save(config));
    }

    @Transactional
    public ProviderDetailResponse updateRequestTemplate(Long id,
                                                        ProviderRequestTemplateRequest request) {
        AiProviderConfig config = load(id);
        String method = defaultIfBlank(request.method(), "POST").trim().toUpperCase();
        if (!ALLOWED_HTTP_METHODS.contains(method)) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "请求方法必须是 GET / POST / PUT / PATCH / DELETE");
        }

        config.setRequestMethod(method);
        config.setRequestPath(trimToNull(request.path()));
        config.setRequestContentType(
                defaultIfBlank(request.contentType(), "application/json"));
        config.setRequestQueryJson(trimToNull(request.queryJson()));
        config.setRequestHeadersJson(trimToNull(request.headersJson()));
        config.setRequestBodyJson(trimToNull(request.bodyJson()));

        return ProviderDetailResponse.from(repository.save(config));
    }

    @Transactional
    public ProviderDetailResponse updateResponseTemplate(Long id,
                                                         ProviderResponseTemplateRequest request) {
        AiProviderConfig config = load(id);
        config.setResponseSuccessPath(trimToNull(request.successPath()));
        config.setResponseResultUrlPath(trimToNull(request.resultUrlPath()));
        config.setResponseThumbPath(trimToNull(request.thumbPath()));
        config.setResponseErrorPath(trimToNull(request.errorPath()));
        config.setResponseTaskIdPath(trimToNull(request.taskIdPath()));
        return ProviderDetailResponse.from(repository.save(config));
    }

    @Transactional
    public ProviderResponse updatePricing(Long id, ProviderPricingRequest request) {
        AiProviderConfig config = load(id);
        PriceUnit priceUnit = requirePriceUnit(request.priceUnit());
        config.setInputPrice(request.inputPrice());
        config.setOutputPrice(request.outputPrice());
        config.setPriceUnit(priceUnit.name());
        return ProviderResponse.from(repository.save(config));
    }

    @Transactional
    public ProviderResponse setOnline(Long id, boolean online) {
        AiProviderConfig config = load(id);
        config.setOnline(online);
        return ProviderResponse.from(repository.save(config));
    }

    /** 逻辑删除（契约之外的补充能力，方便运营清理误接入的模型）。 */
    @Transactional
    public void delete(Long id) {
        AiProviderConfig config = load(id);
        config.setDeleted(true);
        config.setOnline(false);
        repository.save(config);
    }

    // =========================================================================
    // 连通性测试（需求 3.1 第 5 步）
    // =========================================================================

    @Transactional(readOnly = true)
    public ProviderTestResponse test(Long id, ProviderTestRequest request) {
        AiProviderConfig config = load(id);
        String impl = defaultIfBlank(config.getProviderImpl(), ProviderNames.MOCK);

        if (ProviderNames.MOCK.equalsIgnoreCase(impl)) {
            return ProviderTestResponse.of(true,
                    "Mock 通道可用（不会发起真实请求，适合答辩演示）");
        }
        if (ProviderNames.HTTP.equalsIgnoreCase(impl)) {
            ProviderTestResult result = httpApiProvider.test(
                    toRuntime(config), request == null ? null : request.prompt());
            return ProviderTestResponse.from(result);
        }
        if (ProviderNames.STABLE_DIFFUSION.equalsIgnoreCase(impl)) {
            return testReachable(config);
        }
        return ProviderTestResponse.of(false, "不支持的 providerImpl：" + impl);
    }

    /** Stable Diffusion：只做服务可达性探测，真正的生成仍由 StableDiffusionProvider 负责。 */
    private ProviderTestResponse testReachable(AiProviderConfig config) {
        if (config.getBaseUrl() == null || config.getBaseUrl().isBlank()) {
            return ProviderTestResponse.of(false, "未配置服务地址 baseUrl");
        }
        long start = System.currentTimeMillis();
        try {
            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(3))
                    .build();
            HttpRequest request = HttpRequest.newBuilder(URI.create(config.getBaseUrl()))
                    .timeout(Duration.ofSeconds(3))
                    .GET()
                    .build();
            HttpResponse<Void> response = client.send(request,
                    HttpResponse.BodyHandlers.discarding());
            long elapsed = System.currentTimeMillis() - start;
            boolean ok = response.statusCode() < 500;
            return new ProviderTestResponse(ok, response.statusCode(), elapsed,
                    null, ok ? null : "HTTP " + response.statusCode(),
                    null, false, ok ? "服务可访问" : "服务返回异常状态码");
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return new ProviderTestResponse(false, 0,
                    System.currentTimeMillis() - start, null, "请求被中断",
                    null, false, "请求被中断");
        } catch (Exception e) {
            return new ProviderTestResponse(false, 0,
                    System.currentTimeMillis() - start, null, e.getMessage(),
                    null, false, "无法连接：" + e.getMessage());
        }
    }

    // =========================================================================
    // 工具
    // =========================================================================

    private AiProviderConfig load(Long id) {
        return repository.findByIdAndDeletedFalse(id)
                .orElseThrow(() -> new BizException(ErrorCode.PROVIDER_CONFIG_NOT_FOUND));
    }

    private String resolveTypeFilter(String type) {
        if (type == null || type.isBlank()) {
            return null;
        }
        ProviderType providerType = ProviderType.parse(type);
        if (providerType == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "type 必须是 CHAT / IMAGE / VIDEO / AUDIO");
        }
        return providerType.name();
    }

    private ProviderType requireType(String type) {
        ProviderType value = ProviderType.parse(type);
        if (value == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "type 必须是 CHAT / IMAGE / VIDEO / AUDIO");
        }
        return value;
    }

    private PriceUnit requirePriceUnit(String priceUnit) {
        PriceUnit value = PriceUnit.parse(priceUnit);
        if (value == null) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID,
                    "priceUnit 必须是 TOKEN / SECOND / CALL");
        }
        return value;
    }

    private String requireProviderImpl(String impl, String fallback) {
        String value = (impl == null || impl.isBlank()) ? fallback : impl.trim();
        if (!ALLOWED_IMPLS.contains(value)) {
            throw new BizException(ErrorCode.PROVIDER_IMPL_UNSUPPORTED,
                    "providerImpl 必须是 mock / stable-diffusion / http");
        }
        return value;
    }

    /**
     * 渠道标识：新增时为空则自动生成；修改时为空表示保持原值。
     */
    private String requireChannel(String channel, Long selfId) {
        String value = channel == null ? "" : channel.trim();
        if (value.isEmpty()) {
            if (selfId != null) {
                return null;
            }
            value = "CH-" + UUID.randomUUID().toString()
                    .replace("-", "").substring(0, 8).toUpperCase();
        }
        boolean exists = selfId == null
                ? repository.existsByChannelAndDeletedFalse(value)
                : repository.existsByChannelAndDeletedFalseAndIdNot(value, selfId);
        if (exists) {
            throw new BizException(ErrorCode.PROVIDER_CHANNEL_EXISTS);
        }
        return value;
    }

    private ProviderRuntimeConfig toRuntime(AiProviderConfig config) {
        return new ProviderRuntimeConfig(
                config.getProviderImpl(),
                config.getName(),
                config.getModelName(),
                config.getType(),
                config.getBaseUrl(),
                config.getAuthType(),
                config.getApiKey(),
                config.getHeaderName(),
                config.getHeaderValue(),
                config.getRequestMethod(),
                config.getRequestPath(),
                config.getRequestContentType(),
                config.getRequestQueryJson(),
                config.getRequestHeadersJson(),
                config.getRequestBodyJson(),
                config.getResponseSuccessPath(),
                config.getResponseResultUrlPath(),
                config.getResponseThumbPath(),
                config.getResponseErrorPath(),
                config.getResponseTaskIdPath(),
                normalizeTimeout(config.getTimeoutSeconds())
        );
    }

    private static boolean hasNewSecret(String value) {
        return value != null && !value.isBlank() && !value.startsWith("****");
    }

    private static int normalizeTimeout(Integer seconds) {
        return seconds == null ? 180 : Math.max(5, Math.min(seconds, 600));
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static String defaultIfBlank(String value, String fallback) {
        return (value == null || value.isBlank()) ? fallback : value;
    }
}
