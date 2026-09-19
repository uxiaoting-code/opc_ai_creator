package com.opc.server.config;

import com.opc.server.security.AuthInterceptor;
import com.opc.server.storage.FileStorageService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web 层配置：跨域、静态资源、登录拦截器。
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    private static final Logger log = LoggerFactory.getLogger(WebConfig.class);

    private final AuthInterceptor authInterceptor;
    private final StorageProperties storageProperties;
    private final FileStorageService fileStorageService;

    public WebConfig(AuthInterceptor authInterceptor,
                     StorageProperties storageProperties,
                     FileStorageService fileStorageService) {
        this.authInterceptor = authInterceptor;
        this.storageProperties = storageProperties;
        this.fileStorageService = fileStorageService;
    }

    // =========================================================================
    // 一、跨域
    // =========================================================================

    /**
     * 允许跨域。
     *
     * <p><b>这是 Chrome 调试能跑通的前提。</b>
     * Flutter Web 跑在 {@code http://localhost:port}，后端在 {@code http://localhost:8080}，
     * 端口不同即构成跨域。浏览器会先发 OPTIONS 预检请求，
     * 后端不返回 CORS 响应头的话，真实请求根本发不出去。
     *
     * <p>Android 端不受影响（原生 HTTP 客户端没有同源策略），
     * 所以配了跨域只是让 Web 调试可用，不会影响 APK 行为。
     *
     * <p>开发期放开全部来源是为了省事（Flutter Web 的调试端口每次可能不同）。
     * 真要上线，把 {@code allowedOriginPatterns} 收窄成具体的域名白名单。
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS")
                .allowedHeaders("*")
                // 视频播放要暴露这几个头：Web 端 <video> 拖动进度条时会发 Range 请求，
                // 并靠 Content-Range / Accept-Ranges 判断服务端是否支持分段下载。
                // 不暴露的话浏览器拿不到这些头，进度条会退化成不可拖动。
                .exposedHeaders("Content-Range", "Accept-Ranges", "Content-Length")
                // 接口用 Bearer Token 鉴权，不依赖 Cookie，
                // 所以不需要 allowCredentials —— 少开一个口子
                .allowCredentials(false)
                .maxAge(3600);
    }

    // =========================================================================
    // 二、静态资源：把上传目录暴露成 /upload/** 供前端加载
    // =========================================================================

    /**
     * 映射生成结果的访问路径。
     *
     * <p>Mock 生成的图片、用户上传的素材都存在磁盘上，
     * 前端拿到的 URL 形如 {@code /upload/task_xxx.png}，
     * 这里把它指到实际的磁盘目录。
     *
     * <p>用 {@link FileStorageService#getRoot()}（已解析的绝对路径）而不是
     * 直接拼配置里的相对路径：{@code file:./data/uploads/} 这种写法
     * 在不同启动目录下解析结果不一致，是排查起来很痛苦的坑。
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String publicPath = storageProperties.getPublicPath();
        String location = fileStorageService.getRoot().toUri().toString();

        registry.addResourceHandler(publicPath + "/**")
                .addResourceLocations(location)
                // 生成的图片内容不会变，缓存 1 小时减少重复传输
                .setCachePeriod(3600);

        log.info("静态资源映射: {}/** -> {}", publicPath, location);
    }

    // =========================================================================
    // 三、登录拦截器
    // =========================================================================

    /**
     * 注册登录拦截器。
     *
     * <p>只拦 {@code /api/**}，放行登录与注册 —— 没登录的人正是要去调这两个接口。
     * 静态资源 {@code /upload/**} 也不拦：图片要能被 {@code <img>} 直接加载，
     * 而 img 标签是不会带 Authorization 头的。
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(authInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns(
                        "/api/auth/login",
                        "/api/auth/register",
                        "/api/health"
                );
    }
}
