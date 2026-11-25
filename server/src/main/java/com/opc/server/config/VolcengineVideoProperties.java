package com.opc.server.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;

/**
 * Volcengine Ark/Seedance video provider configuration.
 * Values are supplied through environment variables in deployment.
 */
@Component
@ConfigurationProperties(prefix = "opc.provider.volcengine-video")
@Getter
@Setter
public class VolcengineVideoProperties {

    private boolean enabled = false;
    private String baseUrl;
    private String apiKey;
    private String region;
    private String model;

    private String requestMethod = "POST";
    private String createPath;
    private String queryMethod = "GET";
    private String queryPath;
    private String cancelMethod = "POST";
    private String cancelPath;
    private String headersJson;
    private String requestBodyJson;
    private String queryBodyJson;

    private String authHeaderName = "Authorization";
    private String authHeaderPrefix = "Bearer ";
    private String requestContentType = "application/json";
    private int timeoutSeconds = 600;

    private String responseTaskIdPath;
    private String responseStatusPath;
    private String responseProgressPath;
    private String responseResultUrlPath;
    private String responseThumbPath;
    private String responseErrorPath;

    private String processingStatuses = "queued,submitted,running,processing";
    private String successStatuses = "succeeded,success,completed";
    private String failureStatuses = "failed,error,cancelled,canceled";
}