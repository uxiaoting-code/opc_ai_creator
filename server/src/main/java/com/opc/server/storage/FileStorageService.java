package com.opc.server.storage;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.config.StorageProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

/**
 * 文件存储服务。
 *
 * <p>负责把字节流落到磁盘，并返回一个前端可直接加载的 URL。
 * 生成的 AI 图片和用户上传的素材都走这里。
 *
 * <p>存本地磁盘是课设的合理选择；要换成对象存储（OSS / S3），
 * 只需替换本类的实现，调用方不受影响。
 */
@Service
public class FileStorageService {

    private static final Logger log = LoggerFactory.getLogger(FileStorageService.class);

    private final StorageProperties properties;

    /** 上传根目录的绝对路径，启动时就解析好。 */
    private final Path root;

    public FileStorageService(StorageProperties properties) {
        this.properties = properties;
        this.root = Paths.get(properties.getUploadDir()).toAbsolutePath().normalize();
        try {
            Files.createDirectories(root);
            log.info("文件存储目录: {}", root);
        } catch (IOException e) {
            // 目录建不出来说明配置有问题，直接启动失败比运行时报错好排查
            throw new IllegalStateException("无法创建上传目录: " + root, e);
        }
    }

    /**
     * 保存图片。
     *
     * @param image  图片对象
     * @param prefix 文件名前缀，一般用任务号或 {@code material}，便于排查
     * @return 可直接给前端加载的 URL，形如 {@code /upload/task_xxx_ab12cd.png}
     */
    public String saveImage(BufferedImage image, String prefix) {
        String filename = buildFilename(prefix, "png");
        Path target = root.resolve(filename);
        try {
            // 显式指定 png：不写格式名时 ImageIO 会去找 ImageWriter，
            // 在部分 headless 环境下有坑
            boolean written = ImageIO.write(image, "png", target.toFile());
            if (!written) {
                throw new IOException("没有可用的 PNG 编码器");
            }
            return toPublicUrl(filename);
        } catch (IOException e) {
            log.error("保存图片失败: {}", target, e);
            throw new BizException(ErrorCode.FILE_SAVE_FAILED);
        }
    }

    /**
     * 保存任意字节流（用户上传的素材）。
     *
     * @param data      文件内容
     * @param extension 扩展名（不含点）
     * @param prefix    文件名前缀
     */
    public String saveBytes(byte[] data, String extension, String prefix) {
        if (data == null || data.length == 0) {
            throw new BizException(ErrorCode.FILE_EMPTY);
        }
        String filename = buildFilename(prefix, extension);
        Path target = root.resolve(filename);
        try {
            Files.write(target, data);
            return toPublicUrl(filename);
        } catch (IOException e) {
            log.error("保存文件失败: {}", target, e);
            throw new BizException(ErrorCode.FILE_SAVE_FAILED);
        }
    }

    /**
     * 分配一个待写入的文件路径，交给调用方自己写。
     *
     * <p>为什么不能复用 {@link #saveBytes}：视频编码器（JCodec）需要一个可随机
     * 读写的 {@code SeekableByteChannel} 直接写文件 —— MP4 的 moov box 要在
     * 全部帧编码完之后回填，必须能回头改文件头。先写进内存再落盘的话，
     * 一段 3 秒视频就要在堆里多压几十 MB，没必要。
     *
     * <p>写完后用 {@link #publicUrlOf(Path)} 换回可访问的 URL。
     *
     * @return 磁盘上的目标路径（目录已确保存在）
     */
    public Path allocateFile(String prefix, String extension) {
        return root.resolve(buildFilename(prefix, extension));
    }

    /**
     * 把 {@link #allocateFile} 分配并写入完成的文件转成公开 URL。
     *
     * <p>只做「路径 → URL」的换算，不校验文件是否存在：
     * 调用方刚写完自己清楚，多一次 stat 没有意义。
     */
    public String publicUrlOf(Path file) {
        return toPublicUrl(file.getFileName().toString());
    }

    /** 读取文件内容（下载接口用）。 */
    public byte[] read(String filename) {
        try {
            return Files.readAllBytes(resolveSafely(filename));
        } catch (IOException e) {
            throw new BizException(ErrorCode.NOT_FOUND, "文件不存在");
        }
    }

    public InputStream openStream(String filename) throws IOException {
        return new ByteArrayInputStream(read(filename));
    }

    /** 取文件大小。 */
    public long sizeOf(String filename) {
        try {
            return Files.size(resolveSafely(filename));
        } catch (IOException e) {
            return 0L;
        }
    }

    /**
     * 把文件名解析成磁盘路径。
     *
     * <p><b>安全要点</b>：必须校验解析后的路径仍在 root 之内。
     * 否则 {@code ?filename=../../application.yml} 这种请求
     * 就能读到项目里的任意文件（路径穿越漏洞）。
     */
    public Path resolveSafely(String filename) {
        Path target = root.resolve(filename).normalize();
        if (!target.startsWith(root)) {
            log.warn("检测到路径穿越尝试: {}", filename);
            throw new BizException(ErrorCode.FORBIDDEN, "非法的文件名");
        }
        return target;
    }

    /** 删除文件，失败只记日志不抛异常（删除不是关键路径）。 */
    public void deleteQuietly(Path path) {
        try {
            Files.deleteIfExists(path);
        } catch (IOException e) {
            log.warn("删除文件失败: {}", path, e);
        }
    }

    /** 上传目录的绝对路径。 */
    public Path getRoot() {
        return root;
    }

    private String buildFilename(String prefix, String extension) {
        String safePrefix = (prefix == null || prefix.isBlank()) ? "file" : prefix;
        // 只保留字母数字下划线短横，防止前缀里混进路径分隔符
        safePrefix = safePrefix.replaceAll("[^a-zA-Z0-9_-]", "");
        if (safePrefix.isEmpty()) {
            safePrefix = "file";
        }
        String random = UUID.randomUUID().toString().replace("-", "").substring(0, 8);
        return "%s_%d_%s.%s".formatted(
                safePrefix, System.currentTimeMillis(), random, extension);
    }

    private String toPublicUrl(String filename) {
        String base = properties.getPublicPath();
        if (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        return base + "/" + filename;
    }
}
