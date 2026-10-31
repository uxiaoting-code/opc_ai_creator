package com.opc.server;

import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.impl.MockAiProvider;
import com.opc.server.config.StorageProperties;
import com.opc.server.entity.enums.TaskType;
import com.opc.server.storage.FileStorageService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import javax.sound.sampled.AudioSystem;
import java.io.ByteArrayInputStream;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class MockAiProviderAudioTest {

    @TempDir
    Path tempDir;

    @Test
    void generatesPlayableWavForTextToAudio() throws Exception {
        StorageProperties properties = new StorageProperties();
        properties.setUploadDir(tempDir.toString());
        properties.setPublicPath("/upload");
        FileStorageService storage = new FileStorageService(properties);
        MockAiProvider provider = new MockAiProvider(storage);
        AiTaskRequest request = new AiTaskRequest(
                "audio-test-001",
                TaskType.TEXT_TO_AUDIO,
                "欢迎来到直播间",
                null,
                null,
                "audio_v1",
                "mock-tts",
                0,
                null,
                null,
                null,
                null,
                0,
                Map.of("voiceCode", "warm_female", "language", "zh-CN", "format", "WAV"));
        ArrayList<Integer> progress = new ArrayList<>();

        var result = provider.submit(request, progress::add);

        assertThat(result.success()).isTrue();
        assertThat(result.resultUrl()).startsWith("/upload/").endsWith(".wav");
        assertThat(result.resultJson()).contains("\"kind\":\"audio\"");
        assertThat(progress).isNotEmpty();
        String filename = result.resultUrl().substring("/upload/".length());
        byte[] bytes = storage.read(filename);
        assertThat(bytes.length).isGreaterThan(1000);
        assertThat(AudioSystem.getAudioFileFormat(new ByteArrayInputStream(bytes))).isNotNull();
    }
}