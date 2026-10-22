package com.opc.server.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 新建智能体（原型「新建智能体」弹窗的 5 个字段）。 */
public record AgentCreateRequest(
        @NotBlank(message = "请填写智能体名称")
        @Size(max = 100, message = "名称最多 100 字")
        String name,

        @NotBlank(message = "请填写智能体标识")
        @Size(max = 50, message = "标识最多 50 字")
        String code,

        @Size(max = 30, message = "分类最多 30 字")
        String category,

        @Size(max = 500, message = "描述最多 500 字")
        String description,

        @Size(max = 20, message = "图标最多 20 字")
        String icon
) {
}
