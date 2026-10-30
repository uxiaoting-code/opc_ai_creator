package com.opc.server.common;

/**
 * 业务错误码。
 *
 * <p>与 HTTP 状态码解耦：HTTP 层一律返回 200，业务成败看响应体里的 {@code code}。
 * 但 401 是个例外 —— 前端 {@code AuthInterceptor} 专门靠 HTTP 401 来触发
 * 「登录失效 → 踢回登录页」，所以鉴权失败时必须同时把 HTTP 状态码也置为 401。
 */
public enum ErrorCode {

    // --- 通用 ---
    BAD_REQUEST(400, "请求参数有误"),
    UNAUTHORIZED(401, "登录已过期，请重新登录"),
    FORBIDDEN(403, "没有权限执行该操作"),
    NOT_FOUND(404, "请求的资源不存在"),
    INTERNAL_ERROR(500, "服务器开小差了，请稍后重试"),

    // --- 用户 / 鉴权 ---
    USERNAME_EXISTS(1001, "该账号已被注册"),
    USER_NOT_FOUND(1002, "用户不存在"),
    PASSWORD_ERROR(1003, "账号或密码错误"),
    ACCOUNT_DISABLED(1004, "账号已被禁用"),

    // --- Skill 线路 ---
    SKILL_NOT_FOUND(2001, "创作线路不存在"),
    SKILL_OFFLINE(2002, "该创作线路已下线"),

    // --- Harness 任务 ---
    TASK_NOT_FOUND(3001, "任务不存在"),
    TASK_STATUS_ILLEGAL(3002, "当前任务状态下不允许该操作"),
    TASK_RETRY_EXHAUSTED(3003, "重试次数已用尽"),
    NO_PROVIDER_AVAILABLE(3004, "没有可用的 AI 服务商"),

    // --- 文件 ---
    FILE_EMPTY(4001, "上传文件为空"),
    FILE_TYPE_NOT_ALLOWED(4002, "不支持的文件类型"),
    FILE_TOO_LARGE(4003, "文件体积超出限制"),
    FILE_SAVE_FAILED(4004, "文件保存失败"),

    // --- 作品 ---
    WORK_NOT_FOUND(5001, "作品不存在"),

    // --- 用户端：订单与接单（5500-5599）---
    ORDER_NOT_FOUND(5501, "订单不存在或已下架"),
    ORDER_NOT_OPEN(5502, "当前订单不可接取"),
    ORDER_ALREADY_ACCEPTED(5503, "你已经接过该订单"),
    ORDER_QUOTA_FULL(5504, "该订单名额已满"),
    ORDER_ACCESS_DENIED(5505, "无权访问该订单"),
    ORDER_STATUS_ILLEGAL(5506, "当前订单状态不允许该操作"),
    ORDER_DEADLINE_PASSED(5507, "订单已过截止时间"),
    ORDER_ACTIVE_EXISTS(5508, "你已有进行中的接单，请先完成或放弃"),

    // --- 用户端：作品提交与审核（5600-5699）---
    SUBMISSION_NOT_FOUND(5601, "作品提交记录不存在"),
    SUBMISSION_NOT_ALLOWED(5602, "当前订单状态不允许提交"),
    SUBMISSION_ALREADY_PENDING(5603, "该订单已有待审核作品"),
    REVIEW_NOT_FOUND(5604, "审核记录不存在"),
    REVIEW_NOT_PENDING(5605, "当前作品不在待审核状态"),
    REVIEW_ALREADY_FINALIZED(5606, "该作品已经审核完成"),
    SUBMISSION_MEDIA_INVALID(5607, "任务媒体类型与订单要求不匹配"),

    // --- 管理端：模型 / API 配置（6000-6099，后端线专用）---
    PROVIDER_CONFIG_NOT_FOUND(6001, "模型配置不存在"),
    PROVIDER_TEST_FAILED(6002, "连通性测试失败"),
    PROVIDER_CHANNEL_EXISTS(6003, "渠道标识已存在"),
    PROVIDER_OFFLINE(6004, "该模型未上架"),
    PROVIDER_IMPL_UNSUPPORTED(6005, "不支持的 providerImpl"),

    // --- 管理端：调试面板（6100-6199，后端线专用）---
    DEBUG_CASE_NOT_FOUND(6101, "回归用例不存在"),
    DEBUG_AGENT_NOT_FOUND(6102, "调试的智能体不存在"),
    DEBUG_NODE_NOT_FOUND(6103, "调试的节点不存在"),
    DEBUG_VERSION_NOT_FOUND(6104, "调试的版本不存在"),
    DEBUG_CASE_INVALID(6105, "回归用例参数不合法"),

    // --- 管理端：MCP 接入（6200-6299，后端线专用）---
    MCP_SERVER_NOT_FOUND(6201, "MCP 服务端不存在"),
    MCP_TOOL_NOT_FOUND(6202, "MCP 工具不存在"),
    MCP_DISCOVER_FAILED(6203, "MCP 工具发现失败"),
    MCP_INVOKE_FAILED(6204, "MCP 工具调用失败"),
    MCP_TRANSPORT_UNSUPPORTED(6205, "暂不支持的 MCP 传输方式"),

    // --- 管理端：知识库（6400-6499，前端线/知识库模块）---
    KB_NOT_FOUND(6401, "知识库不存在"),
    KB_DOCUMENT_NOT_FOUND(6402, "知识库文档不存在"),
    KB_DOCUMENT_PARSE_FAILED(6403, "文档解析失败"),
    KB_SOURCE_UNSUPPORTED(6404, "暂不支持该文档类型"),
    KB_SEARCH_FAILED(6405, "知识库检索失败"),
    KB_AGENT_NOT_FOUND(6406, "绑定的智能体不存在"),

    // --- 管理端：智能体工作台（6300-6399，后端线专用）---
    AGENT_NOT_FOUND(6301, "智能体不存在"),
    AGENT_CODE_EXISTS(6302, "智能体标识已存在"),
    AGENT_STATUS_ILLEGAL(6303, "当前智能体状态不允许该操作"),
    AGENT_NODE_NOT_FOUND(6304, "编排节点不存在"),
    AGENT_NODE_KEY_DUPLICATE(6305, "节点标识重复"),
    AGENT_VERSION_NOT_FOUND(6306, "智能体版本不存在"),
    AGENT_NO_NODES(6307, "智能体至少需要一个启用节点才能发布"),

    // --- Prompt 知识库（6500-6599）---
    PROMPT_NOT_FOUND(6501, "Prompt 不存在或已下线"),
    PROMPT_TITLE_INVALID(6502, "Prompt 标题不合法"),
    PROMPT_CONTENT_INVALID(6503, "Prompt 内容不合法"),
    PROMPT_PARAMETER_INVALID(6504, "Prompt 参数不合法"),

    // --- 管理端用户（6510-6519）---
    ADMIN_USER_NOT_FOUND(6510, "用户不存在或已被删除"),
    ADMIN_USER_CREDITS_INVALID(6511, "算力调整值不合法"),
    ADMIN_USER_STATUS_INVALID(6512, "用户状态不合法"),
    ADMIN_USER_PASSWORD_INVALID(6513, "重置密码不合法"),
    ADMIN_USER_PARAMETER_INVALID(6514, "用户管理参数不合法"),
    ADMIN_USER_FORBIDDEN(6515, "没有用户管理权限"),

    // --- 管理端系统设置（6520-6529）---
    ADMIN_SETTING_PARAMETER_INVALID(6520, "系统设置参数不合法"),
    ADMIN_SETTING_EMPTY_UPDATE(6521, "至少需要提交一个系统设置项"),
    ADMIN_SETTING_FORBIDDEN(6522, "没有系统设置修改权限"),

    // --- 管理端素材库（6530-6539）---
    MATERIAL_NOT_FOUND(6530, "素材不存在或已下架"),
    MATERIAL_PARAMETER_INVALID(6531, "素材参数不合法"),
    MATERIAL_TITLE_INVALID(6532, "素材名称不合法"),
    MATERIAL_FILE_INVALID(6533, "素材文件地址不合法"),
    MATERIAL_CATEGORY_NOT_FOUND(6534, "素材分类不存在"),
    MATERIAL_TAG_NOT_FOUND(6535, "素材标签不存在"),
    MATERIAL_VERSION_NOT_FOUND(6536, "素材版本不存在"),
    MATERIAL_FORBIDDEN(6537, "没有素材库管理权限"),

    // --- 管理端：API 网关（6780-6799，后端线专用）---
    GATEWAY_ENDPOINT_NOT_FOUND(6781, "网关接口不存在"),
    GATEWAY_ENDPOINT_EXISTS(6782, "相同方法和路径的接口已存在"),
    GATEWAY_EXPORT_FAILED(6783, "OpenAPI 导出失败"),

    // --- 管理端通用（9000-9099，公共段）---
    ADMIN_LOGIN_REQUIRED(9001, "请先以管理员身份登录"),
    ADMIN_FORBIDDEN(9002, "该账号不是管理员，无权访问后台"),
    ADMIN_PARAM_INVALID(9003, "参数不合法"),
    ADMIN_RESOURCE_NOT_FOUND(9004, "目标资源不存在或已被删除"),
    ADMIN_OPERATION_NOT_ALLOWED(9005, "当前状态不允许该操作");

    private final int code;
    private final String message;

    ErrorCode(int code, String message) {
        this.code = code;
        this.message = message;
    }

    public int getCode() {
        return code;
    }

    public String getMessage() {
        return message;
    }
}
