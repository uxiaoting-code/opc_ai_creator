package com.opc.server.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 文件存储配置。
 *
 * <p>对应 {@code application.yml} 里的 {@code opc.storage.*}。
 */
@Component
@ConfigurationProperties(prefix = "opc.storage")
public class StorageProperties {

    /** 上传根目录。生成的图片、用户上传的素材都落在这里。 */
    private String uploadDir = "./data/uploads";

    /** 对外暴露的 URL 前缀，必须与 {@code WebMvcConfig} 的静态资源映射一致。 */
    private String publicPath = "/upload";

    /** 单张图片体积上限（字节），默认 10MB，与前端 MediaUtils 的限制保持一致。 */
    private long maxImageSize = 10L * 1024 * 1024;

    /** 单个视频体积上限（字节），默认 100MB。 */
    private long maxVideoSize = 100L * 1024 * 1024;

    public String getUploadDir() {
        return uploadDir;
    }

    public void setUploadDir(String uploadDir) {
        this.uploadDir = uploadDir;
    }

    public String getPublicPath() {
        return publicPath;
    }

    public void setPublicPath(String publicPath) {
        this.publicPath = publicPath;
    }

    public long getMaxImageSize() {
        return maxImageSize;
    }

    public void setMaxImageSize(long maxImageSize) {
        this.maxImageSize = maxImageSize;
    }

    public long getMaxVideoSize() {
        return maxVideoSize;
    }

    public void setMaxVideoSize(long maxVideoSize) {
        this.maxVideoSize = maxVideoSize;
    }
}
