package com.opc.server.controller.admin;

import com.opc.server.common.PageResult;
import com.opc.server.common.Result;
import com.opc.server.dto.KbBindAgentsRequest;
import com.opc.server.dto.KbDocumentRequest;
import com.opc.server.dto.KbDocumentResponse;
import com.opc.server.dto.KbSearchRequest;
import com.opc.server.dto.KbSearchResponse;
import com.opc.server.dto.KnowledgeBaseRequest;
import com.opc.server.dto.KnowledgeBaseResponse;
import com.opc.server.service.KnowledgeBaseService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/** 管理端「知识库」接口（需求 3.4.1）。 */
@RestController
@RequestMapping("/api/admin/kbs")
public class AdminKnowledgeBaseController {

    private final KnowledgeBaseService service;

    public AdminKnowledgeBaseController(KnowledgeBaseService service) {
        this.service = service;
    }

    @GetMapping
    public Result<PageResult<KnowledgeBaseResponse>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) String keyword) {
        return Result.success(service.list(page, pageSize, keyword));
    }

    @PostMapping
    public Result<KnowledgeBaseResponse> create(@Valid @RequestBody KnowledgeBaseRequest request) {
        return Result.success(service.create(request));
    }

    @GetMapping("/{id}")
    public Result<KnowledgeBaseResponse> detail(@PathVariable Long id) {
        return Result.success(service.detail(id));
    }

    @PutMapping("/{id}")
    public Result<KnowledgeBaseResponse> update(@PathVariable Long id,
                                                @Valid @RequestBody KnowledgeBaseRequest request) {
        return Result.success(service.update(id, request));
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return Result.success();
    }

    /** 文本 / URL / API 同步三种录入方式。 */
    @PostMapping("/{id}/documents")
    public Result<KbDocumentResponse> addDocument(@PathVariable Long id,
                                                  @RequestBody KbDocumentRequest request) {
        return Result.success(service.addDocument(id, request));
    }

    /** 文件上传：当前支持 TXT/MD/CSV/JSON/HTML。 */
    @PostMapping("/{id}/documents/upload")
    public Result<KbDocumentResponse> upload(@PathVariable Long id,
                                             @RequestPart("file") MultipartFile file) {
        return Result.success(service.uploadDocument(id, file));
    }

    @GetMapping("/{id}/documents")
    public Result<PageResult<KbDocumentResponse>> documents(
            @PathVariable Long id,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        return Result.success(service.documents(id, page, pageSize));
    }

    @DeleteMapping("/{id}/documents/{docId}")
    public Result<Void> deleteDocument(@PathVariable Long id, @PathVariable Long docId) {
        service.deleteDocument(id, docId);
        return Result.success();
    }

    @PostMapping("/{id}/reindex")
    public Result<KnowledgeBaseResponse> reindex(@PathVariable Long id) {
        return Result.success(service.reindex(id));
    }

    @PostMapping("/{id}/search")
    public Result<KbSearchResponse> search(@PathVariable Long id,
                                           @RequestBody KbSearchRequest request) {
        return Result.success(service.search(id, request));
    }

    @PutMapping("/{id}/bind-agents")
    public Result<KnowledgeBaseResponse> bindAgents(@PathVariable Long id,
                                                    @RequestBody KbBindAgentsRequest request) {
        return Result.success(service.bindAgents(id, request));
    }
}
