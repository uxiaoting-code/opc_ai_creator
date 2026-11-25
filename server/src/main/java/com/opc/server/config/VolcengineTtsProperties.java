package com.opc.server.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;

/**
 * Volcengine TTS provider configuration.
 */
@Component
@ConfigurationProperties(prefix = "opc.provider.volcengine-tts")
@Getter
@Setter
public class VolcengineTtsProperties {

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
    private int timeoutSeconds = 180;

    private String responseTaskIdPath;
    private String responseStatusPath;
    private String responseProgressPath;
    private String responseAudioUrlPath;
    private String responseAudioBase64Path;
    private String responseErrorPath;

    private String processingStatuses = "queued,submitted,running,processing";
    private String successStatuses = "succeeded,success,completed";
    private String failureStatuses = "failed,error,cancelled,canceled";

    private String defaultVoiceCode = "warm_female";
    private String defaultLanguage = "zh-CN";
    private String defaultFormat = "wav";
}