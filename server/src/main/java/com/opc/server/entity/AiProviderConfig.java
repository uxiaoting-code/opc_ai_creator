package com.opc.server.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * 模型 / API 配置，对应 {@code t_ai_provider_config}。
 *
 * <p>与 {@link Skill} 的区别：
 * <ul>
 *   <li>{@code Skill} 是面向 App 用户的「创作线路」（二次元插画、写实摄影…）；</li>
 *   <li>本表是面向运营人员的「可接入的模型通道」（TT Image 2、GEM 3.7…）。</li>
 * </ul>
 * 两者不是一回事，不要合并。
 *
 * <p>字段定义已冻结在 {@code docs/admin-freeze.md} 冻结项 ①。
 */
@Entity
@Table(name = "t_ai_provider_config")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiProviderConfig extends BaseEntity {

    /** 模型名称，如 TT Image 2 */
    @Column(name = "name", nullable = false, length = 100)
    private String name;

    /** 厂商，如 字节跳动 */
    @Column(name = "vendor", length = 50)
    private String vendor;

    /** CHAT / IMAGE / VIDEO / AUDIO */
    @Column(name = "type", nullable = false, length = 20)
    private String type;

    /** 渠道标识，如 DE-TT-oai-pro，唯一；为空时由 Service 自动生成 */
    @Column(name = "channel", length = 50, unique = true)
    private String channel;

    /** 传给服务商的模型名 */
    @Column(name = "model_name", length = 100)
    private String modelName;

    @Column(name = "base_url", length = 255)
    private String baseUrl;

    /** 走哪个 Java 实现：mock / stable-diffusion / http */
    @Column(name = "provider_impl", nullable = false, length = 50)
    @Builder.Default
    private String providerImpl = "mock";

    /** NONE / API_KEY / OAUTH / CUSTOM_HEADER */
    @Column(name = "auth_type", nullable = false, length = 20)
    @Builder.Default
    private String authType = "NONE";

    @Column(name = "api_key", length = 255)
    private String apiKey;

    @Column(name = "header_name", length = 100)
    private String headerName;

    @Column(name = "header_value", length = 255)
    private String headerValue;

    @Column(name = "oauth_token_url", length = 255)
    private String oauthTokenUrl;

    @Column(name = "oauth_client_id", length = 100)
    private String oauthClientId;

    @Column(name = "oauth_client_secret", length = 255)
    private String oauthClientSecret;

    // ---------------- 请求模板 ----------------

    @Column(name = "request_method", nullable = false, length = 10)
    @Builder.Default
    private String requestMethod = "POST";

    @Column(name = "request_path", length = 255)
    private String requestPath;

    @Column(name = "request_content_type", nullable = false, length = 100)
    @Builder.Default
    private String requestContentType = "application/json";

    @Column(name = "request_query_json", length = 2000)
    private String requestQueryJson;

    @Column(name = "request_headers_json", length = 2000)
    private String requestHeadersJson;

    @Column(name = "request_body_json", length = 4000)
    private String requestBodyJson;

    // ---------------- 响应模板 ----------------

    @Column(name = "response_success_path", length = 255)
    private String responseSuccessPath;

    @Column(name = "response_result_url_path", length = 255)
    private String responseResultUrlPath;

    @Column(name = "response_thumb_path", length = 255)
    private String responseThumbPath;

    @Column(name = "response_error_path", length = 255)
    private String responseErrorPath;

    @Column(name = "response_task_id_path", length = 255)
    private String responseTaskIdPath;

    // ---------------- 计价与状态 ----------------

    @Column(name = "input_price", precision = 10, scale = 4)
    private BigDecimal inputPrice;

    @Column(name = "output_price", precision = 10, scale = 4)
    private BigDecimal outputPrice;

    /** TOKEN / SECOND / CALL */
    @Column(name = "price_unit", nullable = false, length = 20)
    @Builder.Default
    private String priceUnit = "TOKEN";

    @Column(name = "timeout_seconds", nullable = false)
    @Builder.Default
    private Integer timeoutSeconds = 180;

    /** true 上架 / false 下线 */
    @Column(name = "online", nullable = false)
    @Builder.Default
    private Boolean online = false;

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;

    @Column(name = "remark", length = 500)
    private String remark;

    @Column(name = "deleted", nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    public boolean isOnline() {
        return Boolean.TRUE.equals(online);
    }
}
