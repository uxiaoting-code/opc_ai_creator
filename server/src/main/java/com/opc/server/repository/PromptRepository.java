package com.opc.server.repository;

import com.opc.server.entity.Prompt;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Prompt 知识库数据访问。
 *
 * <p>检索用 {@code like} 实现，够课设用。数据量上来之后可以改成
 * MySQL 的 ngram 全文索引（DDL 里已经建好 {@code ft_title_content}），
 * 届时把这里换成 {@code match ... against} 原生查询即可。
 */
@Repository
public interface PromptRepository extends JpaRepository<Prompt, Long> {

    /**
     * 关键词 + 分类组合检索。
     *
     * <p>{@code :keyword} / {@code :category} 传 null 表示不限制，
     * 这样一个方法覆盖「全部 / 只看分类 / 只搜关键词 / 两者都要」四种情况。
     */
    @Query("""
            select p from Prompt p
             where p.deleted = false
               and p.isPublic = 1
               and p.status = 1
               and (:keyword is null or p.title like %:keyword% or p.content like %:keyword%
                    or p.tags like %:keyword%)
               and (:category is null or p.category = :category)
             order by p.favoriteCount desc, p.useCount desc
            """)
    Page<Prompt> search(
            @Param("keyword") String keyword,
            @Param("category") String category,
            Pageable pageable);

    Optional<Prompt> findByIdAndDeletedFalse(Long id);
}
