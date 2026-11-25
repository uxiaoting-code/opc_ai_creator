package com.opc.server.init;

import com.opc.server.ai.ProviderNames;
import com.opc.server.config.VolcengineTtsProperties;
import com.opc.server.config.VolcengineVideoProperties;
import com.opc.server.entity.Skill;
import com.opc.server.entity.enums.SkillType;
import com.opc.server.repository.SkillRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/** Adds real Volcengine skill routes without changing existing Mock skills. */
@Component
@Order(9)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled", havingValue = "true", matchIfMissing = true)
public class VolcengineSkillSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(VolcengineSkillSeeder.class);

    private final SkillRepository skillRepository;
    private final VolcengineVideoProperties videoProperties;
    private final VolcengineTtsProperties ttsProperties;

    public VolcengineSkillSeeder(SkillRepository skillRepository,
                                 VolcengineVideoProperties videoProperties,
                                 VolcengineTtsProperties ttsProperties) {
        this.skillRepository = skillRepository;
        this.videoProperties = videoProperties;
        this.ttsProperties = ttsProperties;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (videoProperties.isEnabled() && !skillRepository.existsByCode("volcengine_video_v1")) {
            skillRepository.save(Skill.builder()
                    .code("volcengine_video_v1")
                    .name("Volcengine Video")
                    .type(SkillType.IMAGE_TO_VIDEO)
                    .scene("product video / image to video")
                    .description("Volcengine Ark/Seedance real video route")
                    .provider(ProviderNames.VOLCENGINE_VIDEO)
                    .modelName(videoProperties.getModel())
                    .sampler("default")
                    .steps(20)
                    .cfgScale(new BigDecimal("6.0"))
                    .width(1024)
                    .height(576)
                    .promptPrefix("stable camera movement, cinematic")
                    .negativePrompt("shaky, distorted, flickering")
                    .paramsJson("{\"durationSeconds\":5,\"ratio\":\"16:9\",\"resolution\":\"720p\",\"fps\":24}")
                    .usageCount(0)
                    .favoriteCount(0)
                    .sortOrder(20)
                    .status(1)
                    .build());
            log.info("Added Volcengine video skill route");
        }

        if (ttsProperties.isEnabled() && !skillRepository.existsByCode("volcengine_tts_v1")) {
            skillRepository.save(Skill.builder()
                    .code("volcengine_tts_v1")
                    .name("Volcengine TTS")
                    .type(SkillType.TEXT_TO_AUDIO)
                    .scene("voice over / narration")
                    .description("Volcengine real TTS route")
                    .provider(ProviderNames.VOLCENGINE_TTS)
                    .modelName(ttsProperties.getModel())
                    .sampler("default")
                    .steps(0)
                    .cfgScale(BigDecimal.ZERO)
                    .width(0)
                    .height(0)
                    .promptPrefix("")
                    .negativePrompt("")
                    .paramsJson("{\"voiceCode\":\"warm_female\",\"language\":\"zh-CN\",\"speed\":1.0,\"format\":\"wav\"}")
                    .usageCount(0)
                    .favoriteCount(0)
                    .sortOrder(21)
                    .status(1)
                    .build());
            log.info("Added Volcengine TTS skill route");
        }
    }
}