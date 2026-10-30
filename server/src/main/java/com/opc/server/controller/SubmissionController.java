package com.opc.server.controller;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.SubmissionCreateRequest;
import com.opc.server.dto.SubmissionResponse;
import com.opc.server.dto.SubmissionResultResponse;
import com.opc.server.entity.enums.MediaType;
import com.opc.server.entity.enums.ReviewStatus;
import com.opc.server.security.UserContext;
import com.opc.server.service.SubmissionService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** 用户端作品提交与审核状态接口（M2）。 */
@RestController
@RequestMapping("/api/submissions")
public class SubmissionController {

    private final SubmissionService submissionService;

    public SubmissionController(SubmissionService submissionService) {
        this.submissionService = submissionService;
    }

    @PostMapping
    public Result<SubmissionResponse> submit(
            @Valid @RequestBody SubmissionCreateRequest request) {
        return Result.success(
                submissionService.submit(UserContext.require(), request),
                "作品已提交，等待审核");
    }

    @GetMapping("/my")
    public Result<PageResult<SubmissionResponse>> my(
            @RequestParam(required = false) ReviewStatus status,
            @RequestParam(required = false) MediaType mediaType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        return Result.success(submissionService.listMy(
                UserContext.require(), status, mediaType, page, pageSize));
    }

    @GetMapping("/{id}")
    public Result<SubmissionResponse> detail(@PathVariable Long id) {
        return Result.success(submissionService.getDetail(UserContext.require(), id));
    }

    @GetMapping("/{id}/result")
    public Result<SubmissionResultResponse> result(@PathVariable Long id) {
        return Result.success(submissionService.getResult(UserContext.require(), id));
    }
}