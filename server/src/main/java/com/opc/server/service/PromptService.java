package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.PromptCreateRequest;
import com.opc.server.dto.PromptFavoriteResponse;
import com.opc.server.dto.PromptResponse;
import com.opc.server.entity.Prompt;
import com.opc.server.entity.PromptFavorite;
import com.opc.server.repository.PromptFavoriteRepository;
import com.opc.server.repository.PromptRepository;
import com.opc.server.security.UserContext;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Prompt 知识库服务。
 */
@Service
public class PromptService {

    private static final int PUBLIC = 1;
    private static final int ENABLED = 1;
    private static final int DEFAULT_PAGE_SIZE = 12;
    private static final int MAX_PAGE_SIZE = 50;

    private final PromptRepository promptRepository;
    private final PromptFavoriteRepository favoriteRepository;

    public PromptService(
            PromptRepository promptRepository,
            PromptFavoriteRepository favoriteRepository) {
        this.promptRepository = promptRepository;
        this.favoriteRepository = favoriteRepository;
    }

    @Transactional(readOnly = true)
    public PageResult<PromptResponse> listPrompts(
            String category,
            String keyword,
            int page,
            int pageSize) {
        Long userId = UserContext.require();
        int safePage = Math.max(1, page);
        int safeSize = pageSize <= 0
                ? DEFAULT_PAGE_SIZE
                : Math.min(pageSize, MAX_PAGE_SIZE);

        Page<Prompt> result = promptRepository.search(
                normalize(keyword),
                normalize(category),
                PageRequest.of(safePage - 1, safeSize)
        );

        Set<Long> favoriteIds = new HashSet<>(
                promptRepository.findFavoritePromptIds(
                        userId,
                        result.getContent().stream().map(Prompt::getId).toList()
                )
        );
        return PageResult.from(
                result,
                prompt -> PromptResponse.from(prompt, favoriteIds.contains(prompt.getId()))
        );
    }

    @Transactional
    public PromptResponse createPrompt(PromptCreateRequest request) {
        Long userId = UserContext.require();
        if (request == null) {
            throw new BizException(ErrorCode.PROMPT_PARAMETER_INVALID);
        }

        String title = request.title() == null ? "" : request.title().trim();
        String content = request.content() == null ? "" : request.content().trim();
        if (title.isEmpty() || title.length() > 100) {
            throw new BizException(
                    ErrorCode.PROMPT_TITLE_INVALID,
                    "Prompt 标题必填且不能超过 100 个字符"
            );
        }
        if (content.isEmpty() || content.length() > 4000) {
            throw new BizException(
                    ErrorCode.PROMPT_CONTENT_INVALID,
                    "Prompt 正文必填且不能超过 4000 个字符"
            );
        }

        String negativeContent = trimToNull(request.negativeContent());
        String category = trimToNull(request.category());
        String tags = trimToNull(request.tags());
        String coverUrl = trimToNull(request.coverUrl());
        if (negativeContent != null && negativeContent.length() > 2000) {
            throw new BizException(ErrorCode.PROMPT_PARAMETER_INVALID, "反向提示词不能超过 2000 个字符");
        }
        if (category != null && category.length() > 50) {
            throw new BizException(ErrorCode.PROMPT_PARAMETER_INVALID, "分类不能超过 50 个字符");
        }
        if (tags != null && tags.length() > 255) {
            throw new BizException(ErrorCode.PROMPT_PARAMETER_INVALID, "标签不能超过 255 个字符");
        }
        if (coverUrl != null && coverUrl.length() > 255) {
            throw new BizException(ErrorCode.PROMPT_PARAMETER_INVALID, "封面地址不能超过 255 个字符");
        }

        Prompt prompt = Prompt.builder()
                .userId(userId)
                .title(title)
                .content(content)
                .negativeContent(negativeContent)
                .category(category == null ? "其他" : category)
                .tags(tags)
                .coverUrl(coverUrl)
                .favoriteCount(0)
                .useCount(0)
                .isPublic(PUBLIC)
                .status(ENABLED)
                .deleted(false)
                .build();
        return PromptResponse.from(promptRepository.save(prompt), false);
    }

    @Transactional
    public PromptFavoriteResponse toggleFavorite(Long promptId) {
        Long userId = UserContext.require();
        Prompt prompt = promptRepository.findByIdAndDeletedFalse(promptId)
                .filter(item -> item.getIsPublic() != null && item.getIsPublic() == PUBLIC)
                .filter(item -> item.getStatus() != null && item.getStatus() == ENABLED)
                .orElseThrow(() -> new BizException(ErrorCode.PROMPT_NOT_FOUND));

        boolean favorited;
        var existing = favoriteRepository.findByUserIdAndPromptId(userId, promptId);
        if (existing.isPresent()) {
            favoriteRepository.delete(existing.get());
            prompt.setFavoriteCount(Math.max(0, value(prompt.getFavoriteCount()) - 1));
            favorited = false;
        } else {
            favoriteRepository.save(
                    PromptFavorite.builder()
                            .userId(userId)
                            .promptId(promptId)
                            .build()
            );
            prompt.setFavoriteCount(value(prompt.getFavoriteCount()) + 1);
            favorited = true;
        }
        Prompt saved = promptRepository.save(prompt);
        return new PromptFavoriteResponse(
                promptId,
                favorited,
                value(saved.getFavoriteCount())
        );
    }

    private static String normalize(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private static String trimToNull(String value) {
        String normalized = normalize(value);
        return normalized == null ? null : normalized;
    }

    private static int value(Integer number) {
        return number == null ? 0 : number;
    }
}
