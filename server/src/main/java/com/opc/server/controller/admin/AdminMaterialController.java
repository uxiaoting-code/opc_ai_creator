package com.opc.server.controller.admin;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.MaterialAdminResponse;
import com.opc.server.dto.MaterialRestoreRequest;
import com.opc.server.dto.MaterialTaxonomyResponse;
import com.opc.server.dto.MaterialUpsertRequest;
import com.opc.server.dto.MaterialVersionResponse;
import com.opc.server.service.AdminMaterialService;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

/**
 * 管理端素材库接口。
 *
 * <p>{@code /api/admin/**} 的 ADMIN 校验由 AuthInterceptor 统一完成，
 * Service 内还会再次校验，形成纵深防御。
 */
@RestController
@RequestMapping("/api/admin")
public class AdminMaterialController {

    private final AdminMaterialService materialService;

    public AdminMaterialController(AdminMaterialService materialService) {
        this.materialService = materialService;
    }

    @GetMapping("/materials")
    public Result<PageResult<MaterialAdminResponse>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long tagId,
            @RequestParam(required = false) List<Long> tagIds,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "12") int pageSize) {
        List<Long> mergedTagIds = new ArrayList<>();
        if (tagId != null) {
            mergedTagIds.add(tagId);
        }
        if (tagIds != null) {
            mergedTagIds.addAll(tagIds);
        }
        return Result.success(materialService.list(
                keyword,
                categoryId,
                mergedTagIds,
                type,
                startDate,
                endDate,
                page,
                pageSize
        ));
    }

    @GetMapping("/materials/{id}")
    public Result<MaterialAdminResponse> get(@PathVariable Long id) {
        return Result.success(materialService.get(id));
    }

    @PostMapping("/materials")
    public Result<MaterialAdminResponse> create(
            @RequestBody(required = false) MaterialUpsertRequest request) {
        return Result.success(materialService.create(request), "素材已创建");
    }

    @PutMapping("/materials/{id}")
    public Result<MaterialAdminResponse> update(
            @PathVariable Long id,
            @RequestBody(required = false) MaterialUpsertRequest request) {
        return Result.success(materialService.update(id, request), "素材已更新");
    }

    @DeleteMapping("/materials/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        materialService.delete(id);
        return Result.success(null, "素材已下架");
    }

    @GetMapping("/material-categories")
    public Result<MaterialTaxonomyResponse> taxonomy() {
        return Result.success(materialService.getTaxonomy());
    }

    @GetMapping("/materials/{id}/versions")
    public Result<List<MaterialVersionResponse>> versions(
            @PathVariable Long id) {
        return Result.success(materialService.versions(id));
    }

    @PostMapping("/materials/{id}/versions/{versionNo}/restore")
    public Result<MaterialAdminResponse> restore(
            @PathVariable Long id,
            @PathVariable Integer versionNo,
            @RequestBody(required = false) MaterialRestoreRequest request) {
        return Result.success(
                materialService.restore(id, versionNo, request),
                "已恢复并生成新版本"
        );
    }
}
