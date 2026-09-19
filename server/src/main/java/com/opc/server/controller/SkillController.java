package com.opc.server.controller;

import com.opc.server.common.Result;
import com.opc.server.dto.SkillResponse;
import com.opc.server.entity.enums.SkillType;
import com.opc.server.service.SkillService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Skill 线路接口 —— 前端首页横滑列表与 Skill 市场页用它。
 *
 * <p>返回纯数组而不是分页结构：线路是运营配置数据，量级很小（几条到几十条），
 * 前端 {@code SkillRepository} 也是按数组解析的。
 */
@RestController
@RequestMapping("/api/skills")
public class SkillController {

    private final SkillService skillService;

    public SkillController(SkillService skillService) {
        this.skillService = skillService;
    }

    /**
     * 线路列表。
     *
     * @param type  TEXT_TO_IMAGE / IMAGE_TO_VIDEO，不传表示全部
     * @param limit 首页只要前几条，市场页不传表示全部
     */
    @GetMapping
    public Result<List<SkillResponse>> list(
            @RequestParam(required = false) SkillType type,
            @RequestParam(required = false) Integer limit) {
        return Result.success(skillService.listSkills(type, limit));
    }

    /** 线路详情，市场页点开参数面板时用。 */
    @GetMapping("/{id}")
    public Result<SkillResponse> detail(@PathVariable Long id) {
        return Result.success(skillService.getSkill(id));
    }
}
