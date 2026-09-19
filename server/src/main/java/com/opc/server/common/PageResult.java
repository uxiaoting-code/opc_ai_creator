package com.opc.server.common;

import org.springframework.data.domain.Page;

import java.util.List;
import java.util.function.Function;

/**
 * 分页结果包装。
 *
 * <p>与前端 {@code lib/core/network/api_response.dart} 的 {@code PageResult<T>}
 * 字段一一对应：{@code list / page / pageSize / total}。
 *
 * <p>注意前端同时兼容 {@code list} 和 {@code records} 两种字段名，
 * 这里统一用 {@code list}。
 *
 * @param <T> 列表元素类型
 */
public record PageResult<T>(
        List<T> list,
        int page,
        int pageSize,
        long total
) {

    public static <T> PageResult<T> of(List<T> list, int page, int pageSize, long total) {
        return new PageResult<>(list, page, pageSize, total);
    }

    /**
     * 从 Spring Data 的 {@link Page} 转换而来。
     *
     * <p>前端分页页码从 1 开始，而 Spring Data 的 {@code page} 从 0 开始，
     * 所以在 Service 层调用时要记得 {@code PageRequest.of(page - 1, size)}，
     * 这里回填时再 +1 换回前端的语义。
     */
    public static <E, T> PageResult<T> from(Page<E> source, Function<E, T> mapper) {
        return new PageResult<>(
                source.getContent().stream().map(mapper).toList(),
                source.getNumber() + 1,
                source.getSize(),
                source.getTotalElements()
        );
    }

    public static <T> PageResult<T> empty(int page, int pageSize) {
        return new PageResult<>(List.of(), page, pageSize, 0L);
    }
}
