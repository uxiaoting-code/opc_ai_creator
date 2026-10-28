package com.opc.server;

import com.opc.server.entity.Prompt;
import com.opc.server.repository.PromptRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.data.domain.PageRequest;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 验证 Prompt 分类/关键词查询，不启动 Web 和 AI Provider。
 */
@DataJpaTest(properties = {
        "spring.datasource.url=jdbc:h2:mem:prompt_repo_test;DB_CLOSE_DELAY=-1",
        "spring.jpa.hibernate.ddl-auto=create-drop"
})
class PromptRepositoryTest {

    @Autowired
    private PromptRepository promptRepository;

    @Test
    void searchesPublicPromptByCategoryAndKeyword() {
        promptRepository.save(Prompt.builder()
                .title("极简商品主图")
                .content("white background, product photography")
                .category("电商")
                .tags("商品,极简")
                .favoriteCount(0)
                .useCount(0)
                .isPublic(1)
                .status(1)
                .deleted(false)
                .build());
        promptRepository.save(Prompt.builder()
                .title("电影感人像")
                .content("portrait, cinematic lighting")
                .category("人物")
                .tags("人像,电影感")
                .favoriteCount(0)
                .useCount(0)
                .isPublic(1)
                .status(1)
                .deleted(false)
                .build());
        promptRepository.flush();

        var page = promptRepository.search(
                "商品",
                "电商",
                PageRequest.of(0, 12)
        );

        assertThat(page.getTotalElements()).isEqualTo(1);
        assertThat(page.getContent().getFirst().getTitle()).isEqualTo("极简商品主图");
    }
}
