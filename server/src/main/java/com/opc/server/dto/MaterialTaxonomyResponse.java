package com.opc.server.dto;

import java.util.List;

/**
 * 素材分类树与多级标签字典。
 */
public record MaterialTaxonomyResponse(
        List<TaxonomyNode> categories,
        List<TaxonomyNode> tags
) {

    public record TaxonomyNode(
            Long id,
            String name,
            Long parentId,
            Integer sortOrder,
            List<TaxonomyNode> children
    ) {
    }
}
