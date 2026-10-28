package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.MaterialAdminResponse;
import com.opc.server.dto.MaterialRestoreRequest;
import com.opc.server.dto.MaterialTaxonomyResponse;
import com.opc.server.dto.MaterialUpsertRequest;
import com.opc.server.dto.MaterialVersionResponse;
import com.opc.server.entity.Material;
import com.opc.server.entity.MaterialCategory;
import com.opc.server.entity.MaterialTag;
import com.opc.server.entity.MaterialVersion;
import com.opc.server.entity.User;
import com.opc.server.repository.MaterialCategoryRepository;
import com.opc.server.repository.MaterialRepository;
import com.opc.server.repository.MaterialTagRepository;
import com.opc.server.repository.MaterialVersionRepository;
import com.opc.server.repository.UserRepository;
import com.opc.server.security.UserContext;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;

/**
 * 管理端素材库服务。
 *
 * <p>素材主表复用 C 端已有的 {@code t_material}，管理端新增分类、标签关联和版本快照。
 * 所有公开入口都会再次校验当前账号，避免未来调整路由时绕过管理端权限。
 */
@Service
public class AdminMaterialService {

    private static final int DEFAULT_PAGE_SIZE = 12;
    private static final int MAX_PAGE_SIZE = 100;
    private static final int MAX_TITLE_LENGTH = 100;
    private static final int MAX_URL_LENGTH = 255;
    private static final int MAX_MIME_LENGTH = 50;
    private static final int MAX_TAG_COUNT = 20;
    private static final int MAX_CHANGE_NOTE_LENGTH = 500;
    private static final Set<String> MEDIA_TYPES =
            Set.of("IMAGE", "VIDEO", "AUDIO", "OTHER");

    private final MaterialRepository materialRepository;
    private final MaterialCategoryRepository categoryRepository;
    private final MaterialTagRepository tagRepository;
    private final MaterialVersionRepository versionRepository;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper;

    public AdminMaterialService(
            MaterialRepository materialRepository,
            MaterialCategoryRepository categoryRepository,
            MaterialTagRepository tagRepository,
            MaterialVersionRepository versionRepository,
            UserRepository userRepository,
            ObjectMapper objectMapper) {
        this.materialRepository = materialRepository;
        this.categoryRepository = categoryRepository;
        this.tagRepository = tagRepository;
        this.versionRepository = versionRepository;
        this.userRepository = userRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public PageResult<MaterialAdminResponse> list(
            String keyword,
            Long categoryId,
            List<Long> tagIds,
            String type,
            String startDate,
            String endDate,
            int page,
            int pageSize) {
        requireAdmin();

        List<MaterialCategory> categories =
                categoryRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc();
        List<MaterialTag> allTags =
                tagRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc();

        Set<Long> categoryFilter = expandCategoryFilter(categoryId, categories);
        Set<Long> tagFilter = expandTagFilter(tagIds, allTags);
        String mediaType = normalizeMediaType(type);
        LocalDate start = parseOptionalDate(startDate, "startDate");
        LocalDate end = parseOptionalDate(endDate, "endDate");
        if (start != null && end != null && start.isAfter(end)) {
            throw invalid("开始日期不能晚于结束日期");
        }

        Specification<Material> spec = (root, query, cb) ->
                cb.equal(root.get("deleted"), false);

        if (keyword != null && !keyword.isBlank()) {
            String like = "%" + keyword.trim().toLowerCase(Locale.ROOT) + "%";
            spec = spec.and((root, query, cb) -> {
                query.distinct(true);
                Join<Material, MaterialTag> tags =
                        root.join("tags", JoinType.LEFT);
                return cb.or(
                        cb.like(cb.lower(root.<String>get("title")), like),
                        cb.like(cb.lower(root.<String>get("name")), like),
                        cb.like(cb.lower(root.<String>get("url")), like),
                        cb.like(cb.lower(root.<String>get("legacyTags")), like),
                        cb.like(cb.lower(tags.<String>get("name")), like)
                );
            });
        }
        if (!categoryFilter.isEmpty()) {
            spec = spec.and((root, query, cb) ->
                    root.get("categoryId").in(categoryFilter));
        }
        if (!tagFilter.isEmpty()) {
            spec = spec.and((root, query, cb) -> {
                query.distinct(true);
                Join<Material, MaterialTag> tags = root.join("tags");
                return tags.get("id").in(tagFilter);
            });
        }
        if (mediaType != null) {
            String prefix = mediaType.toLowerCase(Locale.ROOT) + "/";
            spec = spec.and((root, query, cb) ->
                    cb.like(cb.lower(root.<String>get("mimeType")), prefix + "%"));
        }
        if (start != null) {
            spec = spec.and((root, query, cb) ->
                    cb.greaterThanOrEqualTo(
                            root.<LocalDateTime>get("createdAt"),
                            start.atStartOfDay()));
        }
        if (end != null) {
            spec = spec.and((root, query, cb) ->
                    cb.lessThan(
                            root.<LocalDateTime>get("createdAt"),
                            end.plusDays(1).atStartOfDay()));
        }

        int safePage = Math.max(1, page);
        int safeSize = pageSize <= 0
                ? DEFAULT_PAGE_SIZE
                : Math.min(pageSize, MAX_PAGE_SIZE);
        Page<Material> result = materialRepository.findAll(
                spec,
                PageRequest.of(
                        safePage - 1,
                        safeSize,
                        Sort.by(Sort.Direction.DESC, "createdAt")
                                .and(Sort.by(Sort.Direction.DESC, "id"))
                )
        );

        Map<Long, MaterialCategory> categoryMap = toMap(
                categories, MaterialCategory::getId);
        return PageResult.from(
                result,
                material -> toResponse(material, categoryMap)
        );
    }

    @Transactional(readOnly = true)
    public MaterialAdminResponse get(Long id) {
        requireAdmin();
        Material material = requireMaterial(id);
        Map<Long, MaterialCategory> categories = toMap(
                categoryRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc(),
                MaterialCategory::getId
        );
        return toResponse(material, categories);
    }

    @Transactional(readOnly = true)
    public MaterialTaxonomyResponse getTaxonomy() {
        requireAdmin();
        List<MaterialCategory> categories =
                categoryRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc();
        List<MaterialTag> tags =
                tagRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc();
        return new MaterialTaxonomyResponse(
                buildTree(categories,
                        MaterialCategory::getId,
                        MaterialCategory::getName,
                        MaterialCategory::getParentId,
                        MaterialCategory::getSortOrder),
                buildTree(tags,
                        MaterialTag::getId,
                        MaterialTag::getName,
                        MaterialTag::getParentId,
                        MaterialTag::getSortOrder)
        );
    }

    @Transactional
    public MaterialAdminResponse create(MaterialUpsertRequest request) {
        requireAdmin();
        if (request == null) {
            throw invalid("请求体不能为空");
        }
        String title = requireTitle(request.title());
        String fileUrl = requireFileUrl(request.fileUrl());
        Long categoryId = request.categoryId() == null || request.categoryId() == 0
                ? null
                : requireCategory(request.categoryId()).getId();
        Set<MaterialTag> tags = resolveTags(request.tagIds());
        validateMetadata(request);

        Material material = Material.builder()
                .userId(UserContext.require())
                .name(title)
                .title(title)
                .url(fileUrl)
                .thumbUrl(trimToNull(request.thumbUrl()))
                .fileSize(request.fileSize())
                .width(request.width())
                .height(request.height())
                .mimeType(normalizeMimeType(request.mimeType()))
                .source("ADMIN")
                .categoryId(categoryId)
                .legacyTags(legacyTags(tags))
                .tags(new LinkedHashSet<>(tags))
                .version(1)
                .deleted(false)
                .build();

        Material saved = materialRepository.save(material);
        saveVersion(saved, true, firstNonBlank(request.changeNote(), "创建素材"));
        return toResponse(
                saved,
                toMap(
                        categoryRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc(),
                        MaterialCategory::getId)
        );
    }

    @Transactional
    public MaterialAdminResponse update(Long id, MaterialUpsertRequest request) {
        requireAdmin();
        if (request == null) {
            throw invalid("请求体不能为空");
        }
        validateMetadata(request);
        Material material = requireMaterial(id);

        if (request.title() != null) {
            String title = requireTitle(request.title());
            material.setTitle(title);
            // C 端列表展示 name，保持两边一致。
            material.setName(title);
        }
        if (request.fileUrl() != null) {
            material.setUrl(requireFileUrl(request.fileUrl()));
        }
        if (request.thumbUrl() != null) {
            material.setThumbUrl(emptyToNull(request.thumbUrl()));
        }
        if (request.mimeType() != null) {
            material.setMimeType(normalizeMimeType(request.mimeType()));
        }
        if (request.fileSize() != null) {
            material.setFileSize(request.fileSize());
        }
        if (request.width() != null) {
            material.setWidth(request.width());
        }
        if (request.height() != null) {
            material.setHeight(request.height());
        }
        if (request.categoryId() != null) {
            material.setCategoryId(request.categoryId() == 0
                    ? null
                    : requireCategory(request.categoryId()).getId());
        }
        if (request.tagIds() != null) {
            Set<MaterialTag> tags = resolveTags(request.tagIds());
            material.getTags().clear();
            material.getTags().addAll(tags);
            material.setLegacyTags(legacyTags(tags));
        }

        boolean createNewVersion = Boolean.TRUE.equals(request.newVersion());
        if (createNewVersion) {
            material.setVersion(currentVersion(material) + 1);
        }
        Material saved = materialRepository.save(material);
        saveVersion(
                saved,
                createNewVersion,
                firstNonBlank(
                        request.changeNote(),
                        createNewVersion ? "更新素材" : "同步当前版本")
        );

        return toResponse(
                saved,
                toMap(
                        categoryRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc(),
                        MaterialCategory::getId)
        );
    }

    @Transactional
    public void delete(Long id) {
        requireAdmin();
        Material material = requireMaterial(id);
        material.setDeleted(true);
        materialRepository.save(material);
    }

    @Transactional(readOnly = true)
    public List<MaterialVersionResponse> versions(Long id) {
        requireAdmin();
        requireMaterial(id);
        Map<Long, MaterialCategory> categories = toMap(
                categoryRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc(),
                MaterialCategory::getId
        );
        Map<Long, MaterialTag> tags = toMap(
                tagRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc(),
                MaterialTag::getId
        );
        return versionRepository.findAllByMaterialIdOrderByVersionNoDesc(id)
                .stream()
                .map(version -> toVersionResponse(version, categories, tags))
                .toList();
    }

    @Transactional
    public MaterialAdminResponse restore(
            Long id,
            Integer versionNo,
            MaterialRestoreRequest request) {
        requireAdmin();
        Material material = requireMaterial(id);
        if (versionNo == null) {
            throw new BizException(ErrorCode.MATERIAL_VERSION_NOT_FOUND);
        }
        MaterialVersion version = versionRepository
                .findByMaterialIdAndVersionNo(id, versionNo)
                .orElseThrow(() ->
                        new BizException(ErrorCode.MATERIAL_VERSION_NOT_FOUND));

        material.setTitle(version.getTitle());
        material.setName(version.getTitle());
        material.setUrl(requireFileUrl(version.getFileUrl()));
        material.setThumbUrl(version.getThumbUrl());
        material.setFileSize(version.getFileSize());
        material.setMimeType(version.getMimeType());
        material.setWidth(version.getWidth());
        material.setHeight(version.getHeight());
        material.setCategoryId(version.getCategoryId() == null
                ? null
                : categoryRepository.findByIdAndDeletedFalse(version.getCategoryId())
                        .map(MaterialCategory::getId)
                        .orElse(null));

        Set<MaterialTag> restoredTags = new LinkedHashSet<>(
                tagRepository.findAllByIdInAndDeletedFalse(parseTagIds(version.getTagIdsJson()))
        );
        material.getTags().clear();
        material.getTags().addAll(restoredTags);
        material.setLegacyTags(legacyTags(restoredTags));
        material.setVersion(currentVersion(material) + 1);
        Material saved = materialRepository.save(material);

        String note = request == null ? null : request.changeNote();
        saveVersion(
                saved,
                true,
                firstNonBlank(note, "恢复到版本 v" + versionNo)
        );
        return toResponse(
                saved,
                toMap(
                        categoryRepository.findAllByDeletedFalseOrderBySortOrderAscIdAsc(),
                        MaterialCategory::getId)
        );
    }

    private void saveVersion(
            Material material,
            boolean createNewVersion,
            String changeNote) {
        int versionNo = currentVersion(material);
        MaterialVersion version = createNewVersion
                ? null
                : versionRepository
                        .findByMaterialIdAndVersionNo(material.getId(), versionNo)
                        .orElse(null);
        if (version == null) {
            version = MaterialVersion.builder()
                    .materialId(material.getId())
                    .versionNo(versionNo)
                    .createdBy(UserContext.require())
                    .build();
        }
        version.setTitle(MaterialAdminResponse.titleOf(material));
        version.setCategoryId(material.getCategoryId());
        version.setTagIdsJson(writeTagIds(material.getTags()));
        version.setFileUrl(material.getUrl());
        version.setThumbUrl(material.getThumbUrl());
        version.setFileSize(material.getFileSize());
        version.setMimeType(material.getMimeType());
        version.setWidth(material.getWidth());
        version.setHeight(material.getHeight());
        version.setChangeNote(validateChangeNote(changeNote));
        versionRepository.save(version);
    }

    private MaterialAdminResponse toResponse(
            Material material,
            Map<Long, MaterialCategory> categories) {
        MaterialCategory category = material.getCategoryId() == null
                ? null
                : categories.get(material.getCategoryId());
        return MaterialAdminResponse.from(
                material,
                category == null ? null : category.getName(),
                category == null
                        ? null
                        : buildCategoryPath(category.getId(), categories)
        );
    }

    private MaterialVersionResponse toVersionResponse(
            MaterialVersion version,
            Map<Long, MaterialCategory> categories,
            Map<Long, MaterialTag> tags) {
        List<Long> tagIds = parseTagIds(version.getTagIdsJson());
        MaterialCategory category = version.getCategoryId() == null
                ? null
                : categories.get(version.getCategoryId());
        return new MaterialVersionResponse(
                version.getId(),
                version.getMaterialId(),
                version.getVersionNo(),
                version.getTitle(),
                version.getCategoryId(),
                category == null ? null : category.getName(),
                tagIds,
                tagIds.stream()
                        .map(tags::get)
                        .filter(Objects::nonNull)
                        .map(MaterialTag::getName)
                        .toList(),
                version.getFileUrl(),
                version.getThumbUrl(),
                version.getMimeType(),
                MaterialAdminResponse.mediaTypeOf(version.getMimeType()),
                version.getFileSize(),
                version.getWidth(),
                version.getHeight(),
                version.getChangeNote(),
                version.getCreatedAt()
        );
    }

    private Material requireMaterial(Long id) {
        if (id == null) {
            throw new BizException(ErrorCode.MATERIAL_NOT_FOUND);
        }
        return materialRepository.findByIdAndDeletedFalse(id)
                .orElseThrow(() ->
                        new BizException(ErrorCode.MATERIAL_NOT_FOUND));
    }

    private MaterialCategory requireCategory(Long id) {
        if (id == null || id <= 0) {
            throw new BizException(ErrorCode.MATERIAL_CATEGORY_NOT_FOUND);
        }
        return categoryRepository.findByIdAndDeletedFalse(id)
                .orElseThrow(() ->
                        new BizException(ErrorCode.MATERIAL_CATEGORY_NOT_FOUND));
    }

    private Set<MaterialTag> resolveTags(List<Long> rawIds) {
        LinkedHashSet<Long> ids = new LinkedHashSet<>();
        if (rawIds != null) {
            for (Long id : rawIds) {
                if (id != null) {
                    ids.add(id);
                }
            }
        }
        if (ids.size() > MAX_TAG_COUNT) {
            throw invalid("单个素材最多选择 " + MAX_TAG_COUNT + " 个标签");
        }
        if (ids.isEmpty()) {
            return new LinkedHashSet<>();
        }
        List<MaterialTag> tags = tagRepository.findAllByIdInAndDeletedFalse(ids);
        if (tags.size() != ids.size()) {
            throw new BizException(ErrorCode.MATERIAL_TAG_NOT_FOUND);
        }
        return new LinkedHashSet<>(tags);
    }

    private Set<Long> expandCategoryFilter(
            Long selectedId,
            List<MaterialCategory> categories) {
        if (selectedId == null) {
            return Set.of();
        }
        boolean exists = categories.stream()
                .anyMatch(category -> selectedId.equals(category.getId()));
        if (!exists) {
            throw new BizException(ErrorCode.MATERIAL_CATEGORY_NOT_FOUND);
        }
        return expandTreeIds(
                Set.of(selectedId),
                categories,
                MaterialCategory::getId,
                MaterialCategory::getParentId
        );
    }

    private Set<Long> expandTagFilter(
            List<Long> selectedIds,
            List<MaterialTag> tags) {
        if (selectedIds == null || selectedIds.isEmpty()) {
            return Set.of();
        }
        Set<Long> selected = new LinkedHashSet<>();
        for (Long id : selectedIds) {
            if (id != null) {
                selected.add(id);
            }
        }
        Set<Long> existing = tags.stream()
                .map(MaterialTag::getId)
                .collect(java.util.stream.Collectors.toSet());
        if (!existing.containsAll(selected)) {
            throw new BizException(ErrorCode.MATERIAL_TAG_NOT_FOUND);
        }
        return expandTreeIds(
                selected,
                tags,
                MaterialTag::getId,
                MaterialTag::getParentId
        );
    }

    private static <T> Set<Long> expandTreeIds(
            Set<Long> selected,
            List<T> rows,
            Function<T, Long> idFn,
            Function<T, Long> parentFn) {
        Set<Long> expanded = new LinkedHashSet<>(selected);
        boolean changed;
        do {
            changed = false;
            for (T row : rows) {
                if (expanded.contains(parentFn.apply(row))
                        && expanded.add(idFn.apply(row))) {
                    changed = true;
                }
            }
        } while (changed);
        return expanded;
    }

    private static <T> List<MaterialTaxonomyResponse.TaxonomyNode> buildTree(
            List<T> rows,
            Function<T, Long> idFn,
            Function<T, String> nameFn,
            Function<T, Long> parentFn,
            Function<T, Integer> sortFn) {
        Set<Long> allIds = rows.stream().map(idFn).collect(java.util.stream.Collectors.toSet());
        Map<Long, List<T>> byParent = new HashMap<>();
        List<T> roots = new ArrayList<>();
        for (T row : rows) {
            Long parentId = parentFn.apply(row);
            if (parentId == null || !allIds.contains(parentId)) {
                roots.add(row);
            } else {
                byParent.computeIfAbsent(parentId, ignored -> new ArrayList<>()).add(row);
            }
        }
        return buildNodes(roots, byParent, idFn, nameFn, parentFn, sortFn, 0);
    }

    private static <T> List<MaterialTaxonomyResponse.TaxonomyNode> buildNodes(
            List<T> rows,
            Map<Long, List<T>> byParent,
            Function<T, Long> idFn,
            Function<T, String> nameFn,
            Function<T, Long> parentFn,
            Function<T, Integer> sortFn,
            int depth) {
        if (rows == null || rows.isEmpty() || depth > 30) {
            return List.of();
        }
        return rows.stream()
                .sorted(Comparator
                        .comparing((T row) -> sortFn.apply(row) == null
                                ? 0
                                : sortFn.apply(row))
                        .thenComparing(idFn))
                .map(row -> new MaterialTaxonomyResponse.TaxonomyNode(
                        idFn.apply(row),
                        nameFn.apply(row),
                        parentFn.apply(row),
                        sortFn.apply(row),
                        buildNodes(
                                byParent.get(idFn.apply(row)),
                                byParent,
                                idFn,
                                nameFn,
                                parentFn,
                                sortFn,
                                depth + 1
                        )
                ))
                .toList();
    }

    private static String buildCategoryPath(
            Long categoryId,
            Map<Long, MaterialCategory> categories) {
        Deque<String> names = new ArrayDeque<>();
        Set<Long> visited = new HashSet<>();
        Long current = categoryId;
        while (current != null && visited.add(current)) {
            MaterialCategory category = categories.get(current);
            if (category == null) {
                break;
            }
            names.addFirst(category.getName());
            current = category.getParentId();
        }
        return String.join(" / ", names);
    }

    private String writeTagIds(Collection<MaterialTag> tags) {
        List<Long> ids = tags == null
                ? List.of()
                : tags.stream()
                        .map(MaterialTag::getId)
                        .sorted()
                        .toList();
        try {
            return objectMapper.writeValueAsString(ids);
        } catch (Exception e) {
            throw new IllegalStateException("素材标签快照序列化失败", e);
        }
    }

    private List<Long> parseTagIds(String json) {
        if (json == null || json.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(
                    json,
                    new TypeReference<List<Long>>() {
                    }
            );
        } catch (Exception e) {
            return List.of();
        }
    }

    private static String legacyTags(Collection<MaterialTag> tags) {
        if (tags == null || tags.isEmpty()) {
            return null;
        }
        String value = tags.stream()
                .map(MaterialTag::getName)
                .distinct()
                .collect(java.util.stream.Collectors.joining(","));
        return value.length() > 255 ? value.substring(0, 255) : value;
    }

    private static int currentVersion(Material material) {
        return material.getVersion() == null ? 1 : material.getVersion();
    }

    private void validateMetadata(MaterialUpsertRequest request) {
        if (request.fileSize() != null && request.fileSize() < 0) {
            throw invalid("文件大小不能为负数");
        }
        if (request.width() != null && request.width() < 0) {
            throw invalid("宽度不能为负数");
        }
        if (request.height() != null && request.height() < 0) {
            throw invalid("高度不能为负数");
        }
        if (request.thumbUrl() != null
                && request.thumbUrl().trim().length() > MAX_URL_LENGTH) {
            throw invalid("缩略图地址不能超过 " + MAX_URL_LENGTH + " 个字符");
        }
        if (request.mimeType() != null
                && request.mimeType().trim().length() > MAX_MIME_LENGTH) {
            throw invalid("MIME 类型不能超过 " + MAX_MIME_LENGTH + " 个字符");
        }
        validateChangeNote(request.changeNote());
    }

    private static String requireTitle(String title) {
        String value = trimToNull(title);
        if (value == null || value.length() > MAX_TITLE_LENGTH) {
            throw new BizException(ErrorCode.MATERIAL_TITLE_INVALID);
        }
        return value;
    }

    private static String requireFileUrl(String fileUrl) {
        String value = trimToNull(fileUrl);
        if (value == null
                || value.length() > MAX_URL_LENGTH
                || !(value.startsWith("/upload/")
                || value.startsWith("http://")
                || value.startsWith("https://"))) {
            throw new BizException(ErrorCode.MATERIAL_FILE_INVALID);
        }
        return value;
    }

    private static String normalizeMimeType(String mimeType) {
        String value = trimToNull(mimeType);
        if (value == null) {
            return "application/octet-stream";
        }
        if (value.length() > MAX_MIME_LENGTH) {
            throw invalid("MIME 类型不能超过 " + MAX_MIME_LENGTH + " 个字符");
        }
        return value.toLowerCase(Locale.ROOT);
    }

    private static String normalizeMediaType(String type) {
        String value = trimToNull(type);
        if (value == null) {
            return null;
        }
        value = value.toUpperCase(Locale.ROOT);
        if (!MEDIA_TYPES.contains(value) || "OTHER".equals(value)) {
            throw invalid("素材类型不合法");
        }
        return value;
    }

    private static LocalDate parseOptionalDate(String value, String field) {
        String normalized = trimToNull(value);
        if (normalized == null) {
            return null;
        }
        try {
            return LocalDate.parse(normalized);
        } catch (DateTimeParseException e) {
            throw invalid(field + " 必须使用 yyyy-MM-dd 格式");
        }
    }

    private static String validateChangeNote(String note) {
        String value = trimToNull(note);
        if (value != null && value.length() > MAX_CHANGE_NOTE_LENGTH) {
            throw invalid("版本说明不能超过 " + MAX_CHANGE_NOTE_LENGTH + " 个字符");
        }
        return value;
    }

    private void requireAdmin() {
        Long userId = UserContext.require();
        User user = userRepository.findByIdAndDeletedFalse(userId)
                .orElseThrow(() ->
                        new BizException(ErrorCode.MATERIAL_FORBIDDEN));
        if (!"ADMIN".equalsIgnoreCase(user.getRole())) {
            throw BizException.forbidden(ErrorCode.MATERIAL_FORBIDDEN);
        }
    }

    private static String firstNonBlank(String first, String fallback) {
        String value = trimToNull(first);
        return value == null ? fallback : value;
    }

    private static String emptyToNull(String value) {
        return trimToNull(value);
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static <T> Map<Long, T> toMap(
            Collection<T> rows,
            Function<T, Long> idFn) {
        Map<Long, T> map = new HashMap<>();
        for (T row : rows) {
            map.put(idFn.apply(row), row);
        }
        return map;
    }

    private static BizException invalid(String message) {
        return new BizException(ErrorCode.MATERIAL_PARAMETER_INVALID, message);
    }
}
