package com.opc.server.controller.admin;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.ReviewRequest;
import com.opc.server.dto.SubmissionResponse;
import com.opc.server.dto.SubmissionResultResponse;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.entity.enums.ReviewStatus;
import com.opc.server.security.UserContext;
import com.opc.server.service.SubmissionService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** 后台作品审核接口（M2）。 */
@RestController
@RequestMapping("/api/admin/submissions")
public class AdminSubmissionController {

    private final SubmissionService submissionService;

    public AdminSubmissionController(SubmissionService submissionService) {
        this.submissionService = submissionService;
    }

    @GetMapping
    public Result<PageResult<SubmissionResponse>> list(
            @RequestParam(required = false) ReviewStatus status,
            @RequestParam(required = false) MediaType mediaType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        return Result.success(
                submissionService.listAdmin(status, mediaType, page, pageSize));
    }

    @GetMapping("/pending-count")
    public Result<Long> pendingCount() {
        return Result.success(submissionService.pendingCount());
    }

    @GetMapping("/{id}")
    public Result<SubmissionResponse> detail(@PathVariable Long id) {
        return Result.success(submissionService.getAdminDetail(id));
    }

    @GetMapping("/{id}/result")
    public Result<SubmissionResultResponse> result(@PathVariable Long id) {
        return Result.success(submissionService.getAdminResult(id));
    }

    @PutMapping("/{id}/review")
    public Result<SubmissionResponse> review(
            @PathVariable Long id,
            @Valid @RequestBody ReviewRequest request) {
        return Result.success(
                submissionService.review(UserContext.require(), id, request),
                "审核完成");
    }
}
