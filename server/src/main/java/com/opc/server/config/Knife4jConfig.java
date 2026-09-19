package com.opc.server.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 接口文档配置（Knife4j + OpenAPI 3）。
 *
 * <p>启动后打开 <a href="http://localhost:8080/doc.html">http://localhost:8080/doc.html</a>
 * 就是可视化的接口调试页 —— 按 Controller 分组的接口列表、参数说明、
 * 直接在页面上发请求都能做，答辩演示不用再手写 curl。
 *
 * <p><b>包名说明</b>：放在 {@code com.opc.server.config}，不是 {@code com.opc.ai.config}。
 * 本项目的包根就是 {@code com.opc.server}，70 多个类全在它下面。
 * 另起一棵 {@code com.opc.ai} 包树会多出两套互不相干的 {@code Result}
 * 和全局异常处理器，只会给自己添乱。
 *
 * <p><b>依赖说明</b>：本项目是 Spring Boot 4.1.1，必须用 boot4 专用 starter
 * （见 pom.xml 里的注释），官方那个基于 springdoc-openapi 2.x 的 starter 不兼容。
 *
 * <p>这个类只管「文档页面顶部显示什么」——标题、版本、联系方式。
 * 接口内容是从各个 Controller 的注解自动扫描出来的，不用在这里登记。
 */
@Configuration
public class Knife4jConfig {

    /**
     * 文档元信息。
     *
     * <p>Knife4j 会自动读取这个 Bean 渲染页面顶部的信息区。
     * 不提供也能跑，只是标题会变成默认的 "OpenAPI definition"。
     *
     * <p>这里定义自己的 {@code OpenAPI} Bean 会覆盖 springdoc 的默认实现，
     * 是官方推荐的定制方式，不会产生两个 Bean 冲突。
     */
    @Bean
    public OpenAPI opcOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("OPC AI 创作平台 · 后端接口文档")
                        .description("""
                                多模态 AI 创作平台后端 API。

                                统一返回体：{code, message, data, timestamp}。
                                code = 200 表示业务成功，其余为业务错误码，message 可直接展示给用户。

                                鉴权：除 /api/auth/login 与 /api/auth/register 外，
                                其余接口都需要请求头 Authorization: Bearer <token>。
                                开发期可用固定令牌 mock-token-for-scaffold 免登录调试
                                （由 opc.security.dev-token-enabled 控制，交付前请关掉）。""")
                        .version("1.0.0")
                        .contact(new Contact().name("OPC AI 创作平台 · 课程设计")));
    }
}
