package com.opc.server.controller;

import com.opc.server.common.Result;
import com.opc.server.dto.WorkResponse;
import com.opc.server.security.UserContext;
import com.opc.server.service.WorkService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 作品接口 —— 前端首页「最近作品」横滑区与作品画廊 / 作品详情页用它。
 */
@RestController
@RequestMapping("/api/works")
public class WorkController {

    private final WorkService workService;

    public WorkController(WorkService workService) {
        this.workService = workService;
    }

    /**
     * 我的作品。
     *
     * @param limit 首页只要最近几条；画廊页用 page/pageSize 翻页
     * @param scope 传 {@code public} 时返回公开画廊（所有人可见的作品）
     */
    @GetMapping
    public Result<List<WorkResponse>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) Integer limit,
            @RequestParam(required = false) String scope) {

        if ("public".equalsIgnoreCase(scope)) {
            return Result.success(workService.listPublicWorks(page, pageSize));
        }
        return Result.success(
                workService.listMyWorks(UserContext.require(), page, pageSize, limit));
    }

    /** 作品详情。 */
    @GetMapping("/{id}")
    public Result<WorkResponse> detail(@PathVariable Long id) {
        return Result.success(workService.getWork(UserContext.require(), id));
    }

    /** 发布 / 取消发布到公开画廊。前端作品详情页的「发布」开关用它。 */
    @PostMapping("/{id}/publish")
    public Result<WorkResponse> publish(
            @PathVariable Long id,
            @RequestParam(defaultValue = "true") boolean isPublic) {

        WorkResponse work = workService.publish(UserContext.require(), id, isPublic);
        return Result.success(work, isPublic ? "已发布到画廊" : "已取消发布");
    }
}
