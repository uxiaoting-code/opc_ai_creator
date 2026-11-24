package com.opc.server.controller;

import com.opc.server.common.Result;
import com.opc.server.dto.CreationModelResponse;
import com.opc.server.service.CreationCatalogService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 用户端选择真实模型通道所需的只读目录。 */
@RestController
@RequestMapping("/api/creation")
public class CreationCatalogController {

    private final CreationCatalogService catalogService;

    public CreationCatalogController(CreationCatalogService catalogService) {
        this.catalogService = catalogService;
    }

    @GetMapping("/models")
    public Result<List<CreationModelResponse>> models(
            @RequestParam String mediaType) {
        return Result.success(catalogService.models(mediaType));
    }
}
