package com.opc.server.ai.impl;

import com.opc.server.ai.AiProvider;
import com.opc.server.ai.AiTaskRequest;
import com.opc.server.ai.AiTaskResult;
import com.opc.server.ai.ProgressListener;
import com.opc.server.ai.ProviderNames;
import com.opc.server.entity.enums.TaskType;
import com.opc.server.storage.FileStorageService;
import org.jcodec.api.awt.AWTSequenceEncoder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.GradientPaint;
import java.awt.Graphics2D;
import java.awt.GraphicsEnvironment;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 模拟 AI 服务商 —— 课设默认走这条线路。
 *
 * <p><b>它不调用任何外部接口、不需要任何密钥</b>，而是用 Java2D 在本地
 * 画一张带提示词的渐变图，并逐段 {@code sleep} 模拟生成耗时。
 *
 * <p>为什么值得认真做这个 Mock：
 * <ol>
 *   <li><b>链路可跑通</b>：没有密钥也能完整演示「提交 → 排队 → 生成中 → 成功 → 出图」；</li>
 *   <li><b>状态流转肉眼可见</b>：默认每次生成耗时 2~6 秒，答辩时能清楚看到
 *       进度条推进、状态从「生成中」跳到「成功」，比瞬间返回有说服力得多；</li>
 *   <li><b>可复现失败</b>：提示词里带 {@code #fail} 时首次必失败、重试必成功，
 *       用来演示 Harness 的失败重试闭环（见 {@code opc.mock.failure-marker}）。</li>
 * </ol>
 *
 * <p>要接真实模型时，<b>不用改这个类</b>，而是新增一个实现类并把
 * {@code t_skill.provider} 指过去，见 {@link RemoteAiProviderTemplate}。
 */
@Component
public class MockAiProvider implements AiProvider {

    private static final Logger log = LoggerFactory.getLogger(MockAiProvider.class);

    /** 进度分几段上报，段数越多进度条越顺滑。 */
    private static final int PROGRESS_STEPS = 10;

    /** 模拟失败的提示语。文生图与图生视频共用一份，避免两处文案漂移。 */
    private static final String SIMULATED_FAILURE_MESSAGE =
            "（模拟失败）服务商返回错误：内容审核未通过，请调整提示词后重试";

    // --- 图生视频的产出规格 ---
    //
    // 15fps / 3 秒：帧数（45）够看出运动，文件又只有几百 KB，编码也快。
    // 尺寸必须是偶数 —— H.264 按 16x16 宏块 + 2x2 色度块编码，
    // 奇数宽高会让编码器直接抛异常。640x360 同时满足 16:9 与偶数要求。

    /** 视频帧率。 */
    private static final int VIDEO_FPS = 15;

    /** 视频时长（秒）。 */
    private static final int VIDEO_SECONDS = 3;

    /** 视频宽度（16:9，偶数）。 */
    private static final int VIDEO_WIDTH = 640;

    /** 视频高度（16:9，偶数）。 */
    private static final int VIDEO_HEIGHT = 360;

    private final FileStorageService storage;

    /** 每段模拟耗时下限（毫秒）。 */
    @Value("${opc.mock.min-delay-ms:2000}")
    private long minDelayMs;

    /** 每段模拟耗时上限（毫秒）。 */
    @Value("${opc.mock.max-delay-ms:6000}")
    private long maxDelayMs;

    /**
     * 失败触发标记。提示词里出现它就模拟一次失败。
     *
     * <p>配合「首次失败、重试成功」的规则，用来演示 Harness 的重试闭环。
     */
    @Value("${opc.mock.failure-marker:#fail}")
    private String failureMarker;

    public MockAiProvider(FileStorageService storage) {
        this.storage = storage;
    }

    @Override
    public String getName() {
        return ProviderNames.MOCK;
    }

    @Override
    public boolean isAvailable() {
        return true;
    }

    @Override
    public AiTaskResult submit(AiTaskRequest request, ProgressListener listener) {
        long start = System.currentTimeMillis();
        log.info("Mock 开始生成 taskNo={} type={} size={}x{} retry={}",
                request.taskNo(), request.taskType(),
                request.safeWidth(), request.safeHeight(), request.retryCount());

        try {
            // ---- 0. 图生视频走独立分支：产出的是 MP4，不是 PNG ----
            // 放在最前面分流，文生图那条链路一个字符都不受影响。
            if (request.taskType() == TaskType.IMAGE_TO_VIDEO) {
                return renderVideo(request, listener, start);
            }

            // ---- 1. 分段模拟生成耗时，每段上报一次进度 ----
            long totalDelay = ThreadLocalRandom.current().nextLong(minDelayMs, maxDelayMs + 1);
            long perStep = Math.max(1, totalDelay / PROGRESS_STEPS);

            for (int step = 1; step <= PROGRESS_STEPS; step++) {
                Thread.sleep(perStep);
                listener.onProgress(step * 100 / PROGRESS_STEPS);
            }

            // ---- 2. 可复现的失败：首次必失败，重试必成功 ----
            if (shouldSimulateFailure(request)) {
                String message = SIMULATED_FAILURE_MESSAGE;
                log.info("Mock 触发模拟失败 taskNo={}", request.taskNo());
                return AiTaskResult.fail(message, System.currentTimeMillis() - start);
            }

            // ---- 3. 本地画一张图并落盘 ----
            BufferedImage image = renderImage(request);
            String url = storage.saveImage(image, "task_" + request.taskNo());

            long elapsed = System.currentTimeMillis() - start;
            log.info("Mock 生成完成 taskNo={} 耗时={}ms url={}", request.taskNo(), elapsed, url);

            return AiTaskResult.ok(
                    url,
                    url,                       // Mock 不做缩略图，前端会回退用原图
                    buildResultJson(request),
                    elapsed);

        } catch (InterruptedException e) {
            // 恢复中断标记，否则上层感知不到线程被中断
            Thread.currentThread().interrupt();
            log.warn("Mock 生成被中断 taskNo={}", request.taskNo());
            return AiTaskResult.fail("任务被中断");
        } catch (Exception e) {
            // 兜底：任何意外都转成业务失败，让它走 Harness 的失败/重试流程，
            // 而不是变成一个未捕获异常把调度线程搞挂
            log.error("Mock 生成异常 taskNo={}", request.taskNo(), e);
            return AiTaskResult.fail("生成失败：" + e.getMessage(),
                    System.currentTimeMillis() - start);
        }
    }

    /**
     * 是否需要模拟失败。
     *
     * <p>规则：提示词含失败标记 <b>且是首次尝试</b>。
     * 这样用户点「重试」时一定会成功，能完整演示
     * 「失败 → 重试 → 成功」这条链路。
     */
    private boolean shouldSimulateFailure(AiTaskRequest request) {
        if (failureMarker == null || failureMarker.isBlank()) {
            return false;
        }
        String prompt = request.prompt();
        boolean hasMarker = prompt != null && prompt.contains(failureMarker);
        int retryCount = request.retryCount() == null ? 0 : request.retryCount();
        return hasMarker && retryCount == 0;
    }

    private String buildResultJson(AiTaskRequest request) {
        return """
                {"mock":true,"provider":"mock","model":"%s","width":%d,"height":%d,"steps":%s,"cfgScale":%s}"""
                .formatted(
                        request.modelName() == null ? "mock-local" : request.modelName(),
                        request.safeWidth(),
                        request.safeHeight(),
                        String.valueOf(request.steps()),
                        String.valueOf(request.cfgScale()));
    }

    // =========================================================================
    // 图生视频：逐帧绘制 + JCodec 编码成真实可播放的 MP4
    // =========================================================================

    /**
     * 模拟图生视频。
     *
     * <p>用 Java2D 逐帧画出一段动画，再用 JCodec 编码成 H.264 MP4。
     * 画面内容随提示词变化（配色由提示词哈希决定），动画由三部分构成：
     * 背景色相匀速转满一圈、光斑横向漂移、底部进度条推进。
     * 色相转满 360° 是为了让<b>首尾帧自然衔接</b>，播放器开循环也不跳变。
     *
     * <p>首帧另外存一张 PNG 当缩略图：画廊和首页「最近作品」只需要封面，
     * 不该为了显示一格缩略图去下载整个 MP4。
     */
    private AiTaskResult renderVideo(AiTaskRequest request, ProgressListener listener, long start)
            throws Exception {

        // 模拟失败优先判断：提示词与重试次数此刻都已确定，
        // 没必要先老老实实编码完 45 帧再把结果丢掉
        if (shouldSimulateFailure(request)) {
            log.info("Mock 触发模拟失败（视频）taskNo={}", request.taskNo());
            sleepWithProgress(listener);
            return AiTaskResult.fail(
                    SIMULATED_FAILURE_MESSAGE, System.currentTimeMillis() - start);
        }

        int totalFrames = VIDEO_FPS * VIDEO_SECONDS;
        Path target = storage.allocateFile("task_" + request.taskNo(), "mp4");

        BufferedImage cover = null;
        AWTSequenceEncoder encoder =
                AWTSequenceEncoder.createSequenceEncoder(target.toFile(), VIDEO_FPS);
        try {
            // 编码本身是主要耗时，再按段 sleep 把总时长拉到「演示时看得见进度推进」的量级
            long totalDelay = ThreadLocalRandom.current().nextLong(minDelayMs, maxDelayMs + 1);
            long perStep = Math.max(1, totalDelay / PROGRESS_STEPS);
            int framesPerStep = Math.max(1, totalFrames / PROGRESS_STEPS);

            int frame = 0;
            for (int step = 1; step <= PROGRESS_STEPS; step++) {
                for (int i = 0; i < framesPerStep && frame < totalFrames; i++, frame++) {
                    BufferedImage img = renderVideoFrame(request, frame, totalFrames);
                    if (frame == 0) {
                        cover = img;
                    }
                    encoder.encodeImage(img);
                }
                Thread.sleep(perStep);
                listener.onProgress(step * 100 / PROGRESS_STEPS);
            }
        } finally {
            // 必须 finish()：它负责回填 MP4 的 moov box。
            // 漏掉这一步产出的文件是坏的，播放器会直接报错。
            encoder.finish();
        }

        String url = storage.publicUrlOf(target);
        // 封面存成 PNG；万一没截到首帧就退回视频地址本身
        // （前端 CoverImage 对加载失败有渐变兜底，不会出现破图）
        String coverUrl = cover == null
                ? url
                : storage.saveImage(cover, "cover_" + request.taskNo());

        long elapsed = System.currentTimeMillis() - start;
        log.info("Mock 视频生成完成 taskNo={} 帧数={} 耗时={}ms url={}",
                request.taskNo(), totalFrames, elapsed, url);

        return AiTaskResult.ok(url, coverUrl, buildVideoResultJson(request), elapsed);
    }

    /**
     * 只推进进度不产出结果，供「模拟失败」分支使用。
     *
     * <p>失败也要走一遍进度条：否则前端会看到进度一直是 0 然后突然失败，
     * 像是页面卡住了。
     */
    private void sleepWithProgress(ProgressListener listener) throws InterruptedException {
        long totalDelay = ThreadLocalRandom.current().nextLong(minDelayMs, maxDelayMs + 1);
        long perStep = Math.max(1, totalDelay / PROGRESS_STEPS);
        for (int step = 1; step <= PROGRESS_STEPS; step++) {
            Thread.sleep(perStep);
            listener.onProgress(step * 100 / PROGRESS_STEPS);
        }
    }

    private String buildVideoResultJson(AiTaskRequest request) {
        return """
                {"mock":true,"provider":"mock","kind":"video","model":"%s","width":%d,"height":%d,"fps":%d,"durationSec":%d}"""
                .formatted(
                        request.modelName() == null ? "mock-local" : request.modelName(),
                        VIDEO_WIDTH,
                        VIDEO_HEIGHT,
                        VIDEO_FPS,
                        VIDEO_SECONDS);
    }

    private BufferedImage renderVideoFrame(AiTaskRequest request, int frame, int totalFrames) {
        BufferedImage image =
                new BufferedImage(VIDEO_WIDTH, VIDEO_HEIGHT, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
        try {
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                    RenderingHints.VALUE_ANTIALIAS_ON);
            g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                    RenderingHints.VALUE_TEXT_ANTIALIAS_ON);

            int seed = Math.abs(String.valueOf(request.prompt()).hashCode());
            drawVideoBackground(g, seed, frame, totalFrames);
            drawVideoSweep(g, seed, frame, totalFrames);
            // 复用文生图那套文字排版：顶部类型+线路、中间提示词、底部模型信息与水印
            drawContent(g, request, VIDEO_WIDTH, VIDEO_HEIGHT);
            drawVideoProgressBar(g, frame, totalFrames);
        } finally {
            g.dispose();
        }
        return image;
    }

    /**
     * 背景：色相在整段视频里匀速转满 360°。
     *
     * <p>转满一圈而不是任意漂移，是为了让最后一帧的颜色回到第一帧 ——
     * 播放器循环播放时不会出现颜色突变。
     */
    private void drawVideoBackground(Graphics2D g, int seed, int frame, int totalFrames) {
        float baseHue = seed % 360;
        float hue = (baseHue + 360f * frame / totalFrames) % 360f;

        Color from = Color.getHSBColor(hue / 360f, 0.72f, 0.80f);
        Color to = Color.getHSBColor(((hue + 150f) % 360f) / 360f, 0.68f, 0.40f);
        g.setPaint(new GradientPaint(0, 0, from, VIDEO_WIDTH, VIDEO_HEIGHT, to));
        g.fillRect(0, 0, VIDEO_WIDTH, VIDEO_HEIGHT);
    }

    /**
     * 横向漂移的光斑 —— 视频里「肉眼可见的运动」全靠它。
     *
     * <p>位置由帧号算出，所以依然可复现：同一句提示词跑两次，画面完全一致，
     * 调试时不会因为画面乱跳而怀疑人生。每个光斑速度不同，避免看起来像整块平移。
     */
    private void drawVideoSweep(Graphics2D g, int seed, int frame, int totalFrames) {
        g.setColor(new Color(255, 255, 255, 30));
        for (int i = 0; i < 4; i++) {
            int r = 70 + ((seed >> (i * 3)) & 0x7F);
            int phase = (seed >> (i * 4)) & 0xFF;
            int span = VIDEO_WIDTH + 2 * r;
            int x = (phase + frame * (3 + i)) % span - r;
            int y = (VIDEO_HEIGHT / 5) * i - r / 2;
            g.fillOval(x, y, r, r);
        }

        g.setColor(new Color(255, 255, 255, 40));
        g.setStroke(new BasicStroke(2f));
        g.drawRect(20, 20, VIDEO_WIDTH - 40, VIDEO_HEIGHT - 40);
    }

    /** 底部进度条：让「这是一段正在生成的视频」在画面上也成立。 */
    private void drawVideoProgressBar(Graphics2D g, int frame, int totalFrames) {
        int barWidth = VIDEO_WIDTH - 96;
        int x = 48;
        // 贴着画面下沿，避开 drawContent 画在 height-30 处的水印文字
        int y = VIDEO_HEIGHT - 14;

        g.setColor(new Color(255, 255, 255, 60));
        g.fillRect(x, y, barWidth, 5);

        g.setColor(new Color(255, 255, 255, 215));
        g.fillRect(x, y, (int) (barWidth * (frame + 1L) / totalFrames), 5);
    }

    // =========================================================================
    // 图像渲染
    // =========================================================================

    /**
     * 用 Java2D 画一张「作品」。
     *
     * <p>配色由提示词的哈希决定，所以同一条提示词每次生成的图是稳定的
     * —— 调试时不会因为颜色乱跳而怀疑人生。
     */
    private BufferedImage renderImage(AiTaskRequest request) {
        // 渲染尺寸封顶 1024，避免生成超大 PNG 拖慢响应
        int width = Math.min(request.safeWidth(), 1024);
        int height = Math.min(request.safeHeight(), 1024);

        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();

        try {
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                    RenderingHints.VALUE_ANTIALIAS_ON);
            g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                    RenderingHints.VALUE_TEXT_ANTIALIAS_ON);

            int seed = Math.abs(String.valueOf(request.prompt()).hashCode());
            drawBackground(g, width, height, seed);
            drawDecorations(g, width, height, seed);
            drawContent(g, request, width, height);

        } finally {
            // Graphics2D 持有原生资源，必须释放
            g.dispose();
        }

        return image;
    }

    private void drawBackground(Graphics2D g, int width, int height, int seed) {
        Color from = Color.getHSBColor((seed % 360) / 360f, 0.72f, 0.78f);
        Color to = Color.getHSBColor(((seed / 7) % 360) / 360f, 0.68f, 0.42f);
        g.setPaint(new GradientPaint(0, 0, from, width, height, to));
        g.fillRect(0, 0, width, height);
    }

    /** 画几个半透明圆形做装饰，让图看起来不那么像占位图。 */
    private void drawDecorations(Graphics2D g, int width, int height, int seed) {
        g.setColor(new Color(255, 255, 255, 28));
        for (int i = 0; i < 5; i++) {
            int r = 80 + (seed >> (i * 3)) % 220;
            int x = (seed >> (i * 2)) % width - r / 2;
            int y = (seed >> (i * 5)) % height - r / 2;
            g.fillOval(x, y, r, r);
        }

        g.setColor(new Color(255, 255, 255, 46));
        g.setStroke(new BasicStroke(2f));
        g.drawRect(24, 24, width - 48, height - 48);
    }

    private void drawContent(Graphics2D g, AiTaskRequest request, int width, int height) {
        Font titleFont = resolveFont(Font.BOLD, Math.max(20, width / 22));
        Font bodyFont = resolveFont(Font.PLAIN, Math.max(15, width / 30));
        Font smallFont = resolveFont(Font.PLAIN, Math.max(12, width / 46));

        // ---- 顶部：任务类型 + 线路 ----
        g.setFont(smallFont);
        g.setColor(new Color(255, 255, 255, 205));
        String header = "%s · %s".formatted(
                request.taskType().getLabel(),
                request.skillCode() == null ? "默认线路" : request.skillCode());
        g.drawString(header, 44, 62);

        // ---- 中部：提示词 ----
        g.setFont(titleFont);
        g.setColor(Color.WHITE);

        String prompt = request.prompt() == null ? "" : request.prompt().trim();
        List<String> lines = wrapText(prompt, g.getFontMetrics(), width - 96);

        int lineHeight = g.getFontMetrics().getHeight();
        int maxLines = Math.max(1, (height - 260) / lineHeight);
        int startY = height / 2 - (Math.min(lines.size(), maxLines) * lineHeight) / 2;

        for (int i = 0; i < Math.min(lines.size(), maxLines); i++) {
            String line = lines.get(i);
            // 超出可显示行数时，最后一行用省略号收尾
            if (i == maxLines - 1 && lines.size() > maxLines) {
                line = line + " …";
            }
            g.drawString(line, 48, startY + i * lineHeight);
        }

        // ---- 底部：模型信息 + 水印 ----
        g.setFont(smallFont);
        g.setColor(new Color(255, 255, 255, 190));
        String footer = "model=%s  steps=%s  cfg=%s  %dx%d".formatted(
                request.modelName() == null ? "mock-local" : request.modelName(),
                String.valueOf(request.steps()),
                String.valueOf(request.cfgScale()),
                width, height);
        g.drawString(footer, 48, height - 58);

        g.setColor(new Color(255, 255, 255, 150));
        g.setFont(bodyFont);
        g.drawString("MOCK 模拟生成 · 非真实模型输出", 48, height - 30);
    }

    /** 按像素宽度折行。中文没有空格，只能逐字测量。 */
    private List<String> wrapText(String text, FontMetrics metrics, int maxWidth) {
        List<String> lines = new ArrayList<>();
        if (text == null || text.isEmpty()) {
            lines.add("(无提示词)");
            return lines;
        }

        StringBuilder current = new StringBuilder();
        for (char c : text.toCharArray()) {
            if (c == '\n') {
                lines.add(current.toString());
                current.setLength(0);
                continue;
            }
            current.append(c);
            if (metrics.stringWidth(current.toString()) > maxWidth) {
                // 超宽就把最后一个字符挪到下一行
                current.deleteCharAt(current.length() - 1);
                lines.add(current.toString());
                current.setLength(0);
                current.append(c);
            }
        }
        if (!current.isEmpty()) {
            lines.add(current.toString());
        }
        return lines;
    }

    /**
     * 挑一个能显示中文的字体。
     *
     * <p>headless 环境下如果字体不支持中文，画出来会是一排方框。
     * 这里按候选列表逐个用 {@code canDisplay('中')} 试探，
     * 保证在 Windows / Linux 上都能正常渲染，最后兜底用逻辑字体 SansSerif。
     */
    private Font resolveFont(int style, int size) {
        String[] candidates = {"Microsoft YaHei", "微软雅黑", "SimHei", "黑体",
                "Noto Sans CJK SC", "Source Han Sans SC", "WenQuanYi Micro Hei"};

        try {
            List<String> available = List.of(
                    GraphicsEnvironment.getLocalGraphicsEnvironment()
                            .getAvailableFontFamilyNames());
            for (String name : candidates) {
                if (available.contains(name) && new Font(name, style, size).canDisplay('中')) {
                    return new Font(name, style, size);
                }
            }
        } catch (Exception e) {
            // headless 环境下拿不到字体列表是可能的，忽略即可
            log.debug("获取系统字体列表失败，回退到逻辑字体: {}", e.getMessage());
        }

        Font fallback = new Font(Font.SANS_SERIF, style, size);
        if (!fallback.canDisplay('中')) {
            log.warn("当前环境缺少中文字体，生成的图片里中文可能显示为方框");
        }
        return fallback;
    }
}
