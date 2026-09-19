package com.opc.server.controller;

import com.opc.server.common.Result;
import com.opc.server.dto.NotificationResponse;
import com.opc.server.security.UserContext;
import com.opc.server.service.NotificationService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 消息通知接口 —— 前端首页顶部「消息入口」的红点与弹层用它。
 *
 * <p>对应前端 {@code NotificationRepository}：
 * {@code fetchNotifications()} 和 {@code fetchUnreadCount()}。
 *
 * <p>返回纯数组 / 纯数字而不是包装对象，与前端现有解析方式一致。
 */
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    /** 消息列表（由最近的任务动态派生）。 */
    @GetMapping
    public Result<List<NotificationResponse>> list(
            @RequestParam(defaultValue = "20") int limit) {
        return Result.success(notificationService.list(UserContext.require(), limit));
    }

    /**
     * 未读数，首页红点用。
     *
     * <p>单独一个轻量接口：首页启动时只关心这个数字，
     * 走列表接口会把整批消息都传过来，浪费带宽。
     */
    @GetMapping("/unread")
    public Result<Integer> unread() {
        return Result.success(notificationService.unreadCount(UserContext.require()));
    }
}
