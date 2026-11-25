package com.opc.server;

import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.AiTaskResult;
import com.opc.server.ai.ProgressListener;
import com.opc.server.ai.ProviderNames;
import com.opc.server.ai.impl.VolcengineTtsProvider;
import com.opc.server.ai.impl.VolcengineVideoProvider;
import com.opc.server.config.StorageProperties;
import com.opc.server.config.VolcengineTtsProperties;
import com.opc.server.config.VolcengineVideoProperties;
import com.opc.server.entity.enums.TaskType;
import com.opc.server.storage.FileStorageService;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;

class VolcengineProviderTest {

    private HttpServer server;
    private int port;
    private final AtomicReference<String> lastBody = new AtomicReference<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void startServer() throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/create-video", exchange -> {
            lastBody.set(readBody(exchange));
            respond(exchange, "{\"data\":{\"task_id\":\"job-1\"}}");
        });
        server.createContext("/query-video/job-1", exchange ->
                respond(exchange, "{\"data\":{\"status\":\"succeeded\",\"video_url\":\"https://cdn.example/video.mp4\"}}"));
        server.createContext("/create-tts", exchange -> {
            lastBody.set(readBody(exchange));
            respond(exchange, "{\"audio\":{\"base64\":\"AQID\"}}");
        });
        server.start();
        port = server.getAddress().getPort();
    }

    @AfterEach
    void stopServer() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void videoProviderSubmitsThenQueriesAsyncResult() {
        VolcengineVideoProperties properties = new VolcengineVideoProperties();
        properties.setEnabled(true);
        properties.setBaseUrl("http://127.0.0.1:" + port);
        properties.setApiKey("test-key");
        properties.setModel("seedance-test");
        properties.setCreatePath("/create-video");
        properties.setQueryPath("/query-video/{{providerTaskId}}");
        properties.setRequestBodyJson("{\"model\":\"{{model}}\",\"prompt\":\"{{prompt}}\",\"image\":\"{{refImageUrl}}\",\"task_no\":\"{{taskNo}}\"}");
        properties.setResponseTaskIdPath("data.task_id");
        properties.setResponseStatusPath("data.status");
        properties.setResponseResultUrlPath("data.video_url");
        properties.setResponseErrorPath("data.error");

        VolcengineVideoProvider provider = new VolcengineVideoProvider(properties, objectMapper);
        AiTaskRequest request = new AiTaskRequest(
                "task-video-1", TaskType.IMAGE_TO_VIDEO, "camera move", null,
                "https://cdn.example/frame.png", "volcengine_video_v1", "seedance-test",
                20, 6.0, 1024, 576, null, 0, Map.of("durationSeconds", 5));

        AiTaskResult submitted = provider.submit(request, ProgressListener.NOOP);
        assertThat(submitted.success()).isTrue();
        assertThat(submitted.isAsync()).isTrue();
        assertThat(submitted.providerTaskId()).isEqualTo("job-1");
        assertThat(lastBody.get()).contains("camera move").contains("frame.png");

        AiTaskResult queried = provider.query("job-1");
        assertThat(queried.success()).isTrue();
        assertThat(queried.resultUrl()).isEqualTo("https://cdn.example/video.mp4");
        assertThat(provider.getName()).isEqualTo(ProviderNames.VOLCENGINE_VIDEO);
    }
    @Test
    void ttsProviderSavesBase64Audio(@TempDir Path tempDir) {
        StorageProperties storageProperties = new StorageProperties();
        storageProperties.setUploadDir(tempDir.toString());
        FileStorageService storage = new FileStorageService(storageProperties);

        VolcengineTtsProperties properties = new VolcengineTtsProperties();
        properties.setEnabled(true);
        properties.setBaseUrl("http://127.0.0.1:" + port);
        properties.setApiKey("test-key");
        properties.setModel("tts-test");
        properties.setCreatePath("/create-tts");
        properties.setRequestBodyJson("{\"model\":\"{{model}}\",\"text\":\"{{prompt}}\",\"voice\":\"{{voiceCode}}\",\"language\":\"{{language}}\"}");
        properties.setResponseAudioBase64Path("audio.base64");
        properties.setResponseErrorPath("error");

        VolcengineTtsProvider provider = new VolcengineTtsProvider(properties, storage, objectMapper);
        AiTaskRequest request = new AiTaskRequest(
                "task-tts-1", TaskType.TEXT_TO_AUDIO, "hello world", null,
                null, "volcengine_tts_v1", "tts-test", 0, 0.0, 0, 0,
                null, 0, Map.of("voiceCode", "warm_female", "language", "zh-CN", "format", "wav"));

        AiTaskResult result = provider.submit(request, ProgressListener.NOOP);

        assertThat(result.success()).isTrue();
        assertThat(result.resultUrl()).startsWith("/upload/");
        assertThat(tempDir.resolve(result.resultUrl().substring("/upload/".length()))).exists();
        assertThat(lastBody.get()).contains("hello world").contains("warm_female");
        assertThat(provider.getName()).isEqualTo(ProviderNames.VOLCENGINE_TTS);
    }

    private String readBody(HttpExchange exchange) throws IOException {
        return new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
    }

    private void respond(HttpExchange exchange, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().add("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}