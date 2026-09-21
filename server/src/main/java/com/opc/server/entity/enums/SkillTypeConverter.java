package com.opc.server.entity.enums;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * {@link SkillType} ↔ 数据库字符串 的转换器。
 *
 * <p><b>它存在的唯一理由是「脏数据不能把接口搞挂」。</b>
 *
 * <p>{@code @Enumerated(EnumType.STRING)} 在读到无法识别的值时直接抛
 * {@code IllegalArgumentException}，后果是：{@code t_skill} 里只要有一行
 * {@code type} 写错，{@code GET /api/skills} 就 500，
 * 首页「创作线路」整块挂掉 —— 而前端对此毫无办法，因为它拿不到任何数据。
 *
 * <p>换成这个转换器之后，未知值降级成 {@code null} 并记一条 WARN 日志，
 * 接口照常返回其余线路，问题在日志里可见可查。
 * 具体的行由 {@link com.opc.server.service.SkillService} 跳过，不会展示给用户。
 *
 * <p><b>写入方向不变</b>：仍然写枚举的 {@code value}（{@code TEXT_TO_IMAGE} /
 * {@code IMAGE_TO_VIDEO}），与原来的 {@code name()} 完全一致，
 * 所以这次改动不会影响已有数据的格式。
 */
@Converter
public class SkillTypeConverter implements AttributeConverter<SkillType, String> {

    private static final Logger log = LoggerFactory.getLogger(SkillTypeConverter.class);

    @Override
    public String convertToDatabaseColumn(SkillType attribute) {
        return attribute == null ? null : attribute.getValue();
    }

    @Override
    public SkillType convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return null;
        }

        SkillType type = SkillType.fromValue(dbData);
        if (type == null) {
            log.warn("t_skill.type 出现无法识别的值「{}」，已按 null 处理（该行会被列表接口跳过）。"
                            + "合法取值：TEXT_TO_IMAGE / IMAGE_TO_VIDEO",
                    dbData);
        }
        return type;
    }
}
