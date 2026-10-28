package com.opc.server.controller;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.PromptCreateRequest;
import com.opc.server.dto.PromptFavoriteResponse;
import com.opc.server.dto.PromptResponse;
import com.opc.server.service.PromptService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * C 端 Prompt 知识库接口。
 */
@RestController
@RequestMapping("/api/prompts")
public class PromptController {

    private final PromptService promptService;

    public PromptController(PromptService promptService) {
        this.promptService = promptService;
    }

    @GetMapping
    public Result<PageResult<PromptResponse>> list(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "12") int pageSize) {
        return Result.success(
                promptService.listPrompts(category, keyword, page, pageSize)
        );
    }

    @PostMapping
    public Result<PromptResponse> create(
            @RequestBody(required = false) PromptCreateRequest request) {
        return Result.success(promptService.createPrompt(request));
    }

    @PostMapping("/{id}/favorite")
    public Result<PromptFavoriteResponse> toggleFavorite(@PathVariable Long id) {
        return Result.success(promptService.toggleFavorite(id));
    }
}
