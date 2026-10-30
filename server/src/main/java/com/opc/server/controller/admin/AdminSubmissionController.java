package com.opc.server.controller.admin;

import com.opc.server.common.Result;
import com.opc.server.dto.ReviewRequest;
import com.opc.server.dto.SubmissionResponse;
import com.opc.server.security.UserContext;
import com.opc.server.service.SubmissionService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 后台作品审核接口（M2）。 */
@RestController
@RequestMapping("/api/admin/submissions")
public class AdminSubmissionController {

    private final SubmissionService submissionService;

    public AdminSubmissionController(SubmissionService submissionService) {
        this.submissionService = submissionService;
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