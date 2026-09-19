package com.opc.server.init;

import com.opc.server.entity.Prompt;
import com.opc.server.entity.Skill;
import com.opc.server.entity.User;
import com.opc.server.entity.enums.SkillType;
import com.opc.server.repository.PromptRepository;
import com.opc.server.repository.SkillRepository;
import com.opc.server.repository.UserRepository;
import com.opc.server.security.PasswordEncoder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/**
 * 初始化数据。
 *
 * <p>只在表为空时插入，重复启动不会产生重复数据（幂等）。
 *
 * <p><b>线路的数据与前端 {@code MockData} 完全一致</b>（同样的 id、code、参数），
 * 这样把前端 {@code AppConfig.useMockData} 切成 {@code false} 之后，
 * 首页看到的还是同样的六条线路，不会出现「切了数据源页面就变了」的困惑。
 *
 * <p>刻意<b>不</b>初始化假的任务和作品：那些应该由真实的 Harness 链路跑出来
 * （提交任务 → 排队 → 生成 → 落作品），预置假数据反而会掩盖链路是否真的通了。
 */
@Component
@Order(1)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled",
        havingValue = "true", matchIfMissing = true)
public class DataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private final UserRepository userRepository;
    private final SkillRepository skillRepository;
    private final PromptRepository promptRepository;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(UserRepository userRepository,
                      SkillRepository skillRepository,
                      PromptRepository promptRepository,
                      PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.skillRepository = skillRepository;
        this.promptRepository = promptRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        seedUsers();
        seedSkills();
        seedPrompts();
    }

    // =========================================================================
    // 用户
    // =========================================================================

    private void seedUsers() {
        if (userRepository.countByDeletedFalse() > 0) {
            log.info("用户数据已存在，跳过初始化");
            return;
        }

        User demo = User.builder()
                .username("demo")
                .password(passwordEncoder.encode("demo123"))
                .nickname("课设演示账号")
                .role("USER")
                .credits(200)
                .status(1)
                .deleted(false)
                .build();

        User admin = User.builder()
                .username("admin")
                .password(passwordEncoder.encode("admin123"))
                .nickname("管理员")
                .role("ADMIN")
                .credits(9999)
                .status(1)
                .deleted(false)
                .build();

        userRepository.saveAll(List.of(demo, admin));
        log.info("已初始化演示账号：demo / demo123（普通用户）、admin / admin123（管理员）");
    }

    // =========================================================================
    // Skill 线路
    // =========================================================================

    private void seedSkills() {
        if (skillRepository.count() > 0) {
            log.info("Skill 线路已存在，跳过初始化");
            return;
        }

        List<Skill> skills = List.of(
                Skill.builder()
                        .code("anime_v1")
                        .name("二次元插画")
                        .type(SkillType.TEXT_TO_IMAGE)
                        .scene("头像 / 立绘 / 同人")
                        .description("日系赛璐璐画风，线条干净、色彩通透，适合角色立绘与头像")
                        .provider("mock")
                        .modelName("sd-xl-anime")
                        .sampler("DPM++ 2M Karras")
                        .steps(28)
                        .cfgScale(new BigDecimal("7.5"))
                        .width(1024).height(1024)
                        .promptPrefix("masterpiece, best quality, anime style, cel shading")
                        .negativePrompt("lowres, bad anatomy, extra fingers, watermark")
                        .usageCount(12840).favoriteCount(326).sortOrder(1).status(1)
                        .build(),

                Skill.builder()
                        .code("realistic_v1")
                        .name("写实摄影")
                        .type(SkillType.TEXT_TO_IMAGE)
                        .scene("人像 / 风景 / 产品")
                        .description("照片级真实感，光影层次丰富，适合商业人像与风光")
                        .provider("mock")
                        .modelName("sd-xl-real")
                        .sampler("Euler a")
                        .steps(30)
                        .cfgScale(new BigDecimal("6.5"))
                        .width(1024).height(1536)
                        .promptPrefix("photorealistic, 8k uhd, sharp focus, natural lighting")
                        .negativePrompt("cartoon, anime, painting, lowres, blurry")
                        .usageCount(9260).favoriteCount(251).sortOrder(2).status(1)
                        .build(),

                Skill.builder()
                        .code("ecommerce_v1")
                        .name("电商海报")
                        .type(SkillType.TEXT_TO_IMAGE)
                        .scene("商品主图 / 促销 Banner")
                        .description("干净的纯色背景 + 商业布光，直接可用于商品主图")
                        .provider("mock")
                        .modelName("sd-xl-product")
                        .sampler("DPM++ SDE Karras")
                        .steps(25)
                        .cfgScale(new BigDecimal("7.0"))
                        .width(1024).height(1024)
                        .promptPrefix("product photography, clean background, studio lighting, commercial")
                        .negativePrompt("cluttered, messy, text, watermark, low quality")
                        .usageCount(6180).favoriteCount(178).sortOrder(3).status(1)
                        .build(),

                Skill.builder()
                        .code("guofeng_v1")
                        .name("国风水墨")
                        .type(SkillType.TEXT_TO_IMAGE)
                        .scene("国潮 / 文创 / 插画")
                        .description("水墨晕染 + 留白构图，适合国潮文创与东方美学题材")
                        .provider("mock")
                        .modelName("sd-xl-ink")
                        .sampler("Euler a")
                        .steps(26)
                        .cfgScale(new BigDecimal("7.0"))
                        .width(1024).height(1024)
                        .promptPrefix("chinese ink painting, traditional, rice paper texture")
                        .negativePrompt("western, oil painting, 3d render, lowres")
                        .usageCount(3470).favoriteCount(96).sortOrder(4).status(1)
                        .build(),

                Skill.builder()
                        .code("motion_v1")
                        .name("短视频运镜")
                        .type(SkillType.IMAGE_TO_VIDEO)
                        .scene("产品展示 / 场景转场")
                        .description("稳定的推拉摇移运镜，画面不崩坏，适合产品短视频")
                        .provider("mock")
                        .modelName("svd-xt")
                        .steps(20)
                        .cfgScale(new BigDecimal("6.0"))
                        .width(1024).height(576)
                        .promptPrefix("smooth camera movement, stable, cinematic")
                        .negativePrompt("shaky, distorted, flickering")
                        .usageCount(2150).favoriteCount(84).sortOrder(5).status(1)
                        .build(),

                Skill.builder()
                        .code("anime_motion_v1")
                        .name("动漫动态漫")
                        .type(SkillType.IMAGE_TO_VIDEO)
                        .scene("二次元短视频 / 动态壁纸")
                        .description("让静态二次元插画动起来，适合动态壁纸与短视频")
                        .provider("mock")
                        .modelName("svd-anime")
                        .steps(22)
                        .cfgScale(new BigDecimal("6.5"))
                        .width(768).height(768)
                        .promptPrefix("anime style, subtle motion, loop friendly")
                        .negativePrompt("realistic, distorted face")
                        .usageCount(1890).favoriteCount(132).sortOrder(6).status(1)
                        .build()
        );

        skillRepository.saveAll(skills);
        log.info("已初始化 {} 条 Skill 创作线路", skills.size());
    }

    // =========================================================================
    // Prompt 知识库
    // =========================================================================

    private void seedPrompts() {
        if (promptRepository.count() > 0) {
            log.info("Prompt 知识库已存在，跳过初始化");
            return;
        }

        List<Prompt> prompts = List.of(
                Prompt.builder()
                        .title("赛博朋克城市夜景")
                        .content("cyberpunk city at night, neon lights, rainy street, "
                                + "reflections on wet asphalt, flying cars, cinematic lighting")
                        .negativeContent("daytime, bright, low quality")
                        .category("风景")
                        .tags("赛博朋克,夜景,城市")
                        .favoriteCount(128).useCount(430).isPublic(1).status(1).deleted(false)
                        .build(),

                Prompt.builder()
                        .title("日系少女立绘")
                        .content("1girl, solo, long hair, school uniform, cherry blossom, "
                                + "soft lighting, detailed eyes, cel shading")
                        .negativeContent("lowres, bad anatomy, extra fingers")
                        .category("二次元")
                        .tags("二次元,人物,立绘")
                        .favoriteCount(256).useCount(890).isPublic(1).status(1).deleted(false)
                        .build(),

                Prompt.builder()
                        .title("极简商品主图")
                        .content("product photography, single object, pastel background, "
                                + "soft shadow, studio lighting, centered, 8k")
                        .negativeContent("cluttered, text, watermark")
                        .category("电商")
                        .tags("电商,产品,极简")
                        .favoriteCount(94).useCount(312).isPublic(1).status(1).deleted(false)
                        .build(),

                Prompt.builder()
                        .title("水墨远山")
                        .content("misty mountains, chinese ink wash painting, minimal composition, "
                                + "large blank space, rice paper texture")
                        .negativeContent("western style, oil painting, colorful")
                        .category("风景")
                        .tags("国风,水墨,山水")
                        .favoriteCount(76).useCount(204).isPublic(1).status(1).deleted(false)
                        .build(),

                Prompt.builder()
                        .title("电影感人像特写")
                        .content("close-up portrait, cinematic lighting, shallow depth of field, "
                                + "35mm film grain, natural skin texture, rim light")
                        .negativeContent("overexposed, plastic skin, lowres")
                        .category("人物")
                        .tags("写实,人像,电影感")
                        .favoriteCount(143).useCount(521).isPublic(1).status(1).deleted(false)
                        .build()
        );

        promptRepository.saveAll(prompts);
        log.info("已初始化 {} 条 Prompt 知识库数据", prompts.size());
    }
}
