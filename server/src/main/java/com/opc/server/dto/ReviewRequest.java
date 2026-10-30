package com.opc.server.dto;

import com.opc.server.entity.enums.ReviewStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** 后台审核作品请求。 */
public record ReviewRequest(
        @NotNull ReviewStatus decision,
        @Size(max = 1000) String comment
) {
}