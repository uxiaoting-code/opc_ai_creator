package com.opc.server;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.dto.MaterialRestoreRequest;
import com.opc.server.dto.MaterialUpsertRequest;
import com.opc.server.entity.MaterialCategory;
import com.opc.server.entity.MaterialTag;
import com.opc.server.entity.User;
import com.opc.server.repository.MaterialCategoryRepository;
import com.opc.server.repository.MaterialRepository;
import com.opc.server.repository.MaterialTagRepository;
import com.opc.server.repository.MaterialVersionRepository;
import com.opc.server.repository.UserRepository;
import com.opc.server.security.PasswordEncoder;
import com.opc.server.security.UserContext;
import com.opc.server.service.AdminMaterialService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.http.HttpStatus;
import tools.jackson.databind.ObjectMapper;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@DataJpaTest
class AdminMaterialServiceDataTest {

    @Autowired
    private MaterialRepository materialRepository;

    @Autowired
    private MaterialCategoryRepository categoryRepository;

    @Autowired
    private MaterialTagRepository tagRepository;

    @Autowired
    private MaterialVersionRepository versionRepository;

    @Autowired
    private UserRepository userRepository;

    private final PasswordEncoder passwordEncoder = new PasswordEncoder();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @AfterEach
    void clearUserContext() {
        UserContext.clear();
    }

    @Test
    void createsSearchesVersionsRestoresAndDeletesMaterial() {
        User admin = saveUser("material_admin", "ADMIN");
        MaterialCategory rootCategory = saveCategory("电商视觉", null);
        MaterialCategory childCategory = saveCategory("商品主图", rootCategory.getId());
        MaterialTag rootTag = saveTag("风格", null);
        MaterialTag childTag = saveTag("极简", rootTag.getId());
        AdminMaterialService service = service();

        UserContext.set(admin.getId());
        var created = service.create(new MaterialUpsertRequest(
                "春季新品主图",
                childCategory.getId(),
                List.of(childTag.getId()),
                "/upload/spring-main.png",
                null,
                "image/png",
                1024L,
                1080,
                1080,
                null,
                "初始版本"
        ));
        assertThat(created.version()).isEqualTo(1);
        assertThat(created.categoryPath()).isEqualTo("电商视觉 / 商品主图");
        assertThat(created.tags()).extracting("name").containsExactly("极简");
        assertThat(versionRepository.findAllByMaterialIdOrderByVersionNoDesc(created.id()))
                .hasSize(1);

        var page = service.list(
                "新品",
                rootCategory.getId(),
                List.of(rootTag.getId()),
                "IMAGE",
                null,
                null,
                1,
                10
        );
        assertThat(page.total()).isEqualTo(1);
        assertThat(page.list().getFirst().id()).isEqualTo(created.id());

        var updated = service.update(created.id(), new MaterialUpsertRequest(
                "春季新品主图 v2",
                childCategory.getId(),
                List.of(childTag.getId()),
                "/upload/spring-main-v2.png",
                null,
                "image/png",
                2048L,
                1080,
                1080,
                true,
                "替换高清图"
        ));
        assertThat(updated.version()).isEqualTo(2);
        assertThat(versionRepository.findAllByMaterialIdOrderByVersionNoDesc(created.id()))
                .hasSize(2);

        var restored = service.restore(
                created.id(),
                1,
                new MaterialRestoreRequest("回退首版")
        );
        assertThat(restored.version()).isEqualTo(3);
        assertThat(restored.fileUrl()).isEqualTo("/upload/spring-main.png");

        service.delete(created.id());
        assertThat(materialRepository.findByIdAndDeletedFalse(created.id())).isEmpty();
        assertThatThrownBy(() -> service.get(created.id()))
                .isInstanceOfSatisfying(BizException.class, error ->
                        assertThat(error.getErrorCode())
                                .isEqualTo(ErrorCode.MATERIAL_NOT_FOUND));
    }

    @Test
    void rejectsNonAdminAndInvalidTaxonomyIds() {
        User user = saveUser("material_user", "USER");
        User admin = saveUser("material_admin_2", "ADMIN");
        AdminMaterialService service = service();

        UserContext.set(user.getId());
        assertThatThrownBy(() -> service.list(null, null, null, null, null, null, 1, 10))
                .isInstanceOfSatisfying(BizException.class, error -> {
                    assertThat(error.getErrorCode())
                            .isEqualTo(ErrorCode.MATERIAL_FORBIDDEN);
                    assertThat(error.getHttpStatus()).isEqualTo(HttpStatus.FORBIDDEN);
                });

        UserContext.set(admin.getId());
        assertThatThrownBy(() -> service.list(null, 9999L, null, null, null, null, 1, 10))
                .isInstanceOfSatisfying(BizException.class, error ->
                        assertThat(error.getErrorCode())
                                .isEqualTo(ErrorCode.MATERIAL_CATEGORY_NOT_FOUND));

        assertThatThrownBy(() -> service.create(new MaterialUpsertRequest(
                "非法地址",
                null,
                List.of(),
                "javascript:alert(1)",
                null,
                "image/png",
                1L,
                1,
                1,
                null,
                null
        )))
                .isInstanceOfSatisfying(BizException.class, error ->
                        assertThat(error.getErrorCode())
                                .isEqualTo(ErrorCode.MATERIAL_FILE_INVALID));
    }

    private AdminMaterialService service() {
        return new AdminMaterialService(
                materialRepository,
                categoryRepository,
                tagRepository,
                versionRepository,
                userRepository,
                objectMapper
        );
    }

    private User saveUser(String username, String role) {
        return userRepository.save(User.builder()
                .username(username)
                .password(passwordEncoder.encode("test123"))
                .nickname(username)
                .role(role)
                .credits(100)
                .status(1)
                .deleted(false)
                .build());
    }

    private MaterialCategory saveCategory(String name, Long parentId) {
        return categoryRepository.save(MaterialCategory.builder()
                .name(name)
                .parentId(parentId)
                .sortOrder(1)
                .deleted(false)
                .build());
    }

    private MaterialTag saveTag(String name, Long parentId) {
        return tagRepository.save(MaterialTag.builder()
                .name(name)
                .parentId(parentId)
                .sortOrder(1)
                .deleted(false)
                .build());
    }
}
