package com.opc.server.init;

import com.opc.server.entity.MaterialCategory;
import com.opc.server.entity.MaterialTag;
import com.opc.server.repository.MaterialCategoryRepository;
import com.opc.server.repository.MaterialTagRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * 素材库默认分类与多级标签。只在字典为空时初始化，重复启动保持幂等。
 */
@Component
@Order(3)
@ConditionalOnProperty(prefix = "opc.seed", name = "enabled",
        havingValue = "true", matchIfMissing = true)
public class AdminMaterialSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminMaterialSeeder.class);

    private final MaterialCategoryRepository categoryRepository;
    private final MaterialTagRepository tagRepository;

    public AdminMaterialSeeder(
            MaterialCategoryRepository categoryRepository,
            MaterialTagRepository tagRepository) {
        this.categoryRepository = categoryRepository;
        this.tagRepository = tagRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        seedCategories();
        seedTags();
    }

    private void seedCategories() {
        if (categoryRepository.countByDeletedFalse() > 0) {
            log.info("素材分类已存在，跳过初始化");
            return;
        }

        MaterialCategory ecommerce = saveCategory("电商视觉", null, 1);
        MaterialCategory video = saveCategory("短视频", null, 2);
        MaterialCategory brand = saveCategory("品牌资产", null, 3);
        saveCategory("商品主图", ecommerce.getId(), 1);
        saveCategory("活动海报", ecommerce.getId(), 2);
        saveCategory("产品展示", video.getId(), 1);
        saveCategory("场景素材", video.getId(), 2);
        saveCategory("Logo", brand.getId(), 1);
        saveCategory("字体", brand.getId(), 2);
        log.info("已初始化 9 个素材分类节点");
    }

    private void seedTags() {
        if (tagRepository.countByDeletedFalse() > 0) {
            log.info("素材标签已存在，跳过初始化");
            return;
        }

        MaterialTag style = saveTag("风格", null, 1);
        MaterialTag scene = saveTag("场景", null, 2);
        MaterialTag state = saveTag("运营状态", null, 3);
        saveTag("极简", style.getId(), 1);
        saveTag("国风", style.getId(), 2);
        saveTag("赛博朋克", style.getId(), 3);
        saveTag("室内", scene.getId(), 1);
        saveTag("户外", scene.getId(), 2);
        saveTag("节庆", scene.getId(), 3);
        saveTag("新品", state.getId(), 1);
        saveTag("爆款", state.getId(), 2);
        log.info("已初始化 11 个素材标签节点");
    }

    private MaterialCategory saveCategory(
            String name,
            Long parentId,
            int sortOrder) {
        return categoryRepository.save(MaterialCategory.builder()
                .name(name)
                .parentId(parentId)
                .sortOrder(sortOrder)
                .deleted(false)
                .build());
    }

    private MaterialTag saveTag(String name, Long parentId, int sortOrder) {
        return tagRepository.save(MaterialTag.builder()
                .name(name)
                .parentId(parentId)
                .sortOrder(sortOrder)
                .deleted(false)
                .build());
    }
}
