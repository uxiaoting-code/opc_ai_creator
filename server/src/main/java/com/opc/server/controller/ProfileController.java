package com.opc.server.controller;

import com.opc.server.common.Result;
import com.opc.server.dto.ProfileStatsResponse;
import com.opc.server.security.UserContext;
import com.opc.server.service.ProfileStatsService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 用户个人中心统一统计接口。 */
@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    private final ProfileStatsService profileStatsService;

    public ProfileController(ProfileStatsService profileStatsService) {
        this.profileStatsService = profileStatsService;
    }

    @GetMapping("/stats")
    public Result<ProfileStatsResponse> stats() {
        return Result.success(profileStatsService.stats(UserContext.require()));
    }
}