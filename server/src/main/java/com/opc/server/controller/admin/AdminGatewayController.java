package com.opc.server.controller.admin;

import com.opc.server.common.Result;
import com.opc.server.dto.GatewayEndpointRequest;
import com.opc.server.dto.GatewayEndpointResponse;
import com.opc.server.service.GatewayEndpointService;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;
import java.util.List;

/** 管理端「API 网关」接口（原型 pg-gateway）。 */
@RestController
@RequestMapping("/api/admin/gateway")
public class AdminGatewayController {

    private final GatewayEndpointService service;

    public AdminGatewayController(GatewayEndpointService service) {
        this.service = service;
    }

    @GetMapping("/endpoints")
    public Result<List<GatewayEndpointResponse>> list() {
        return Result.success(service.list());
    }

    @PostMapping("/endpoints")
    public Result<GatewayEndpointResponse> create(
            @Valid @RequestBody GatewayEndpointRequest request) {
        return Result.success(service.create(request));
    }

    @PutMapping("/endpoints/{id}")
    public Result<GatewayEndpointResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody GatewayEndpointRequest request) {
        return Result.success(service.update(id, request));
    }

    @DeleteMapping("/endpoints/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return Result.success();
    }

    @GetMapping("/export/openapi")
    public ResponseEntity<byte[]> exportOpenApi() {
        String json = service.exportOpenApi();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=openapi.json")
                .contentType(new MediaType("application", "json", StandardCharsets.UTF_8))
                .body(json.getBytes(StandardCharsets.UTF_8));
    }
}
