package com.opc.server.service;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.PageResult;
import com.opc.server.dto.KbBindAgentsRequest;
import com.opc.server.dto.KbDocumentRequest;
import com.opc.server.dto.KbDocumentResponse;
import com.opc.server.dto.KbSearchRequest;
import com.opc.server.dto.KbSearchResponse;
import com.opc.server.dto.KnowledgeBaseRequest;
import com.opc.server.dto.KnowledgeBaseResponse;
import com.opc.server.entity.Agent;
import com.opc.server.entity.KbChunk;
import com.opc.server.entity.KbDocument;
import com.opc.server.entity.KnowledgeBase;
import com.opc.server.repository.AgentRepository;
import com.opc.server.repository.KbChunkRepository;
import com.opc.server.repository.KbDocumentRepository;
import com.opc.server.repository.KnowledgeBaseRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 知识库服务（需求 3.4.1）。
 *
 * <p>第一版不接向量库：用「分段 + 关键词打分」跑通
 * 「录入 → 分段 → 检索 → 引用」链路；embeddingModel 字段先保留。
 *
 * <p>文件解析：TXT/MD/CSV/JSON/HTML 直接读文本；
 * PDF/Word/Excel 需要 PDFBox/POI，当前版本返回明确提示。
 */
@Service
public class KnowledgeBaseService {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeBaseService.class);
    private static final Set<String> PLAIN_TEXT_EXT =
            Set.of("txt", "md", "markdown", "csv", "json", "html", "htm", "xml", "log");
    private static final int CHUNK_SIZE = 500;
    private static final int CHUNK_OVERLAP = 50;

    private final KnowledgeBaseRepository kbRepository;
    private final KbDocumentRepository documentRepository;
    private final KbChunkRepository chunkRepository;
    private final AgentRepository agentRepository;
    private final HttpClient httpClient;

    public KnowledgeBaseService(KnowledgeBaseRepository kbRepository,
                                KbDocumentRepository documentRepository,
                                KbChunkRepository chunkRepository,
                                AgentRepository agentRepository) {
        this.kbRepository = kbRepository;
        this.documentRepository = documentRepository;
        this.chunkRepository = chunkRepository;
        this.agentRepository = agentRepository;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();
    }

    // =========================================================================
    // 知识库 CRUD
    // =========================================================================

    @Transactional(readOnly = true)
    public PageResult<KnowledgeBaseResponse> list(int page, int pageSize, String keyword) {
        Specification<KnowledgeBase> spec = (root, query, cb) ->
                cb.equal(root.get("deleted"), false);
        if (keyword != null && !keyword.isBlank()) {
            String like = "%" + keyword.trim().toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.like(
                    cb.lower(root.<String>get("name")), like));
        }
        int safePage = Math.max(1, page);
        int safeSize = Math.min(Math.max(1, pageSize), 100);
        Page<KnowledgeBase> result = kbRepository.findAll(spec,
                PageRequest.of(safePage - 1, safeSize, Sort.by(Sort.Direction.ASC, "id")));
        return PageResult.from(result, KnowledgeBaseResponse::from);
    }

    @Transactional
    public KnowledgeBaseResponse create(KnowledgeBaseRequest request) {
        KnowledgeBase kb = KnowledgeBase.builder()
                .name(request.name().trim())
                .description(trimToNull(request.description()))
                .embeddingModel(defaultIfBlank(request.embeddingModel(), "keyword-v1"))
                .status("ACTIVE")
                .documentCount(0)
                .chunkCount(0)
                .deleted(false)
                .build();
        return KnowledgeBaseResponse.from(kbRepository.save(kb));
    }

    @Transactional(readOnly = true)
    public KnowledgeBaseResponse detail(Long id) {
        return KnowledgeBaseResponse.from(loadKb(id));
    }

    @Transactional
    public KnowledgeBaseResponse update(Long id, KnowledgeBaseRequest request) {
        KnowledgeBase kb = loadKb(id);
        kb.setName(request.name().trim());
        kb.setDescription(trimToNull(request.description()));
        kb.setEmbeddingModel(defaultIfBlank(request.embeddingModel(), kb.getEmbeddingModel()));
        return KnowledgeBaseResponse.from(kbRepository.save(kb));
    }

    @Transactional
    public void delete(Long id) {
        KnowledgeBase kb = loadKb(id);
        kb.setDeleted(true);
        kbRepository.save(kb);
        for (KbDocument doc : documentRepository.findByKbIdAndDeletedFalseOrderByIdAsc(id)) {
            doc.setDeleted(true);
            documentRepository.save(doc);
        }
        chunkRepository.deleteByKbId(id);
    }

    // =========================================================================
    // 文档
    // =========================================================================

    @Transactional(readOnly = true)
    public PageResult<KbDocumentResponse> documents(Long kbId, int page, int pageSize) {
        loadKb(kbId);
        List<KbDocument> all = documentRepository.findByKbIdAndDeletedFalseOrderByIdAsc(kbId);
        int safePage = Math.max(1, page);
        int safeSize = Math.min(Math.max(1, pageSize), 100);
        int from = Math.min(all.size(), (safePage - 1) * safeSize);
        int to = Math.min(all.size(), from + safeSize);
        List<KbDocumentResponse> list = all.subList(from, to).stream()
                .map(KbDocumentResponse::from).toList();
        return PageResult.of(list, safePage, safeSize, all.size());
    }

    @Transactional
    public KbDocumentResponse addDocument(Long kbId, KbDocumentRequest request) {
        KnowledgeBase kb = loadKb(kbId);
        String type = defaultIfBlank(request.type(), "TEXT").trim().toUpperCase();
        String sourceUrl = null;
        String content;

        switch (type) {
            case "TEXT" -> content = requireText(request.content(), "content 不能为空");
            case "URL" -> {
                sourceUrl = requireText(request.url(), "url 不能为空");
                content = stripHtml(fetchUrl(sourceUrl));
            }
            case "API_SYNC" -> {
                sourceUrl = requireText(request.url(), "url 不能为空");
                content = fetchUrl(sourceUrl);
            }
            default -> throw new BizException(ErrorCode.KB_SOURCE_UNSUPPORTED,
                    "type 必须是 TEXT / URL / API_SYNC（文件请走上传接口）");
        }

        KbDocument doc = KbDocument.builder()
                .kbId(kbId)
                .name(defaultIfBlank(request.name(), type + " 文档"))
                .sourceType(type)
                .sourceUrl(sourceUrl)
                .content(content)
                .chunkCount(0)
                .status("READY")
                .deleted(false)
                .build();
        doc = documentRepository.save(doc);
        int chunks = saveChunks(kbId, doc.getId(), content);
        doc.setChunkCount(chunks);
        documentRepository.save(doc);
        refreshCounts(kb);
        return KbDocumentResponse.from(doc);
    }

    @Transactional
    public KbDocumentResponse uploadDocument(Long kbId, MultipartFile file) {
        KnowledgeBase kb = loadKb(kbId);
        if (file == null || file.isEmpty()) {
            throw new BizException(ErrorCode.FILE_EMPTY);
        }
        String filename = defaultIfBlank(file.getOriginalFilename(), "未命名文件");
        String ext = extensionOf(filename);
        if (!PLAIN_TEXT_EXT.contains(ext)) {
            throw new BizException(ErrorCode.KB_SOURCE_UNSUPPORTED,
                    "当前版本支持 TXT/MD/CSV/JSON/HTML；PDF/Word/Excel 需安装 PDFBox/POI 后再启用");
        }
        try {
            String content = new String(file.getBytes(), StandardCharsets.UTF_8);
            if ("html".equals(ext) || "htm".equals(ext)) {
                content = stripHtml(content);
            }
            KbDocument doc = KbDocument.builder()
                    .kbId(kbId)
                    .name(filename)
                    .sourceType("FILE")
                    .mimeType(file.getContentType())
                    .fileSize(file.getSize())
                    .content(content)
                    .chunkCount(0)
                    .status("READY")
                    .deleted(false)
                    .build();
            doc = documentRepository.save(doc);
            int chunks = saveChunks(kbId, doc.getId(), content);
            doc.setChunkCount(chunks);
            documentRepository.save(doc);
            refreshCounts(kb);
            return KbDocumentResponse.from(doc);
        } catch (BizException e) {
            throw e;
        } catch (Exception e) {
            throw new BizException(ErrorCode.KB_DOCUMENT_PARSE_FAILED,
                    "文件解析失败：" + e.getMessage());
        }
    }

    @Transactional
    public void deleteDocument(Long kbId, Long docId) {
        KnowledgeBase kb = loadKb(kbId);
        KbDocument doc = documentRepository.findByIdAndDeletedFalse(docId)
                .filter(d -> kbId.equals(d.getKbId()))
                .orElseThrow(() -> new BizException(ErrorCode.KB_DOCUMENT_NOT_FOUND));
        doc.setDeleted(true);
        documentRepository.save(doc);
        chunkRepository.deleteByDocumentId(docId);
        refreshCounts(kb);
    }

    @Transactional
    public KnowledgeBaseResponse reindex(Long kbId) {
        KnowledgeBase kb = loadKb(kbId);
        chunkRepository.deleteByKbId(kbId);
        int totalChunks = 0;
        for (KbDocument doc : documentRepository.findByKbIdAndDeletedFalseOrderByIdAsc(kbId)) {
            int chunks = saveChunks(kbId, doc.getId(), doc.getContent());
            doc.setChunkCount(chunks);
            documentRepository.save(doc);
            totalChunks += chunks;
        }
        kb.setChunkCount(totalChunks);
        kbRepository.save(kb);
        return KnowledgeBaseResponse.from(kb);
    }

    // =========================================================================
    // 检索（关键词打分，不依赖向量库）
    // =========================================================================

    @Transactional(readOnly = true)
    public KbSearchResponse search(Long kbId, KbSearchRequest request) {
        loadKb(kbId);
        long start = System.currentTimeMillis();
        String query = request == null || request.query() == null ? "" : request.query().trim();
        int topK = request == null || request.topK() == null
                ? 5 : Math.min(Math.max(1, request.topK()), 20);
        if (query.isEmpty()) {
            return new KbSearchResponse(query, 0L, List.of());
        }

        List<String> terms = tokenize(query);
        List<KbChunk> chunks = chunkRepository.findByKbIdAndDeletedFalseOrderByIdAsc(kbId);
        Map<Long, String> docNames = documentRepository.findByKbIdAndDeletedFalseOrderByIdAsc(kbId)
                .stream().collect(Collectors.toMap(KbDocument::getId, KbDocument::getName));

        List<KbSearchResponse.Item> items = new ArrayList<>();
        for (KbChunk chunk : chunks) {
            double score = score(query, terms, chunk.getContent());
            if (score <= 0) {
                continue;
            }
            items.add(new KbSearchResponse.Item(
                    chunk.getId(), chunk.getDocumentId(),
                    docNames.getOrDefault(chunk.getDocumentId(), "未知文档"),
                    snippet(chunk.getContent(), 220),
                    Math.round(score * 100.0) / 100.0
            ));
        }
        items.sort(Comparator.comparingDouble(KbSearchResponse.Item::score).reversed());
        if (items.size() > topK) {
            items = new ArrayList<>(items.subList(0, topK));
        }
        return new KbSearchResponse(query, System.currentTimeMillis() - start, items);
    }

    // =========================================================================
    // 绑定智能体
    // =========================================================================

    @Transactional
    public KnowledgeBaseResponse bindAgents(Long kbId, KbBindAgentsRequest request) {
        KnowledgeBase kb = loadKb(kbId);
        List<Long> ids = request == null || request.agentIds() == null
                ? List.of() : request.agentIds();
        for (Long agentId : ids) {
            Agent agent = agentRepository.findByIdAndDeletedFalse(agentId)
                    .orElseThrow(() -> new BizException(ErrorCode.KB_AGENT_NOT_FOUND,
                            "智能体不存在：" + agentId));
            log.debug("绑定知识库 {} 到智能体 {}", kbId, agent.getName());
        }
        kb.setBoundAgentIds(ids.isEmpty() ? null
                : ids.stream().distinct().map(String::valueOf)
                        .collect(Collectors.joining(",")));
        return KnowledgeBaseResponse.from(kbRepository.save(kb));
    }

    // =========================================================================
    // 内部分段 / 打分
    // =========================================================================

    private int saveChunks(Long kbId, Long documentId, String content) {
        List<String> parts = chunkContent(content);
        int index = 0;
        for (String part : parts) {
            chunkRepository.save(KbChunk.builder()
                    .kbId(kbId)
                    .documentId(documentId)
                    .chunkIndex(index++)
                    .content(part)
                    .keywords(keywordsOf(part))
                    .deleted(false)
                    .build());
        }
        return parts.size();
    }

    private List<String> chunkContent(String content) {
        if (content == null || content.isBlank()) {
            return List.of();
        }
        String normalized = content.replace("\r\n", "\n").trim();
        List<String> chunks = new ArrayList<>();
        int start = 0;
        while (start < normalized.length()) {
            int end = Math.min(normalized.length(), start + CHUNK_SIZE);
            if (end < normalized.length()) {
                int cut = Math.max(normalized.lastIndexOf('\n', end),
                        normalized.lastIndexOf('。', end));
                if (cut > start + CHUNK_SIZE / 2) {
                    end = cut + 1;
                }
            }
            String chunk = normalized.substring(start, end).trim();
            if (!chunk.isEmpty()) {
                chunks.add(chunk);
            }
            if (end >= normalized.length()) {
                break;
            }
            start = Math.max(end - CHUNK_OVERLAP, start + 1);
        }
        return chunks;
    }

    private List<String> tokenize(String query) {
        Set<String> terms = new LinkedHashSet<>();
        for (String part : query.toLowerCase(Locale.ROOT)
                .split("[\\s,，。；;、:：!！?？\\[\\]【】()（）]+")) {
            if (part.isBlank()) {
                continue;
            }
            terms.add(part);
            if (part.length() > 2) {
                for (int i = 0; i + 2 <= part.length(); i++) {
                    terms.add(part.substring(i, i + 2));
                }
            }
        }
        return new ArrayList<>(terms);
    }

    private double score(String query, List<String> terms, String content) {
        if (content == null) {
            return 0;
        }
        String lower = content.toLowerCase(Locale.ROOT);
        double score = 0;
        if (!query.isBlank() && lower.contains(query.toLowerCase(Locale.ROOT))) {
            score += Math.max(2.0, query.length() * 0.5);
        }
        for (String term : terms) {
            int count = countOccurrences(lower, term);
            score += count * Math.max(1.0, term.length() * 0.3);
        }
        return score;
    }

    private int countOccurrences(String text, String term) {
        if (term.isEmpty()) {
            return 0;
        }
        int count = 0;
        int index = 0;
        while ((index = text.indexOf(term, index)) >= 0) {
            count++;
            index += term.length();
        }
        return count;
    }

    private String keywordsOf(String content) {
        List<String> terms = tokenize(content.length() > 300 ? content.substring(0, 300) : content);
        return terms.stream().limit(12).collect(Collectors.joining(","));
    }

    private String snippet(String content, int max) {
        if (content == null) {
            return "";
        }
        return content.length() <= max ? content : content.substring(0, max) + "…";
    }

    // =========================================================================
    // 远程抓取 / 工具
    // =========================================================================

    private String fetchUrl(String url) {
        try {
            HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(15))
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request,
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new BizException(ErrorCode.KB_DOCUMENT_PARSE_FAILED,
                        "抓取失败：HTTP " + response.statusCode());
            }
            return response.body();
        } catch (BizException e) {
            throw e;
        } catch (Exception e) {
            throw new BizException(ErrorCode.KB_DOCUMENT_PARSE_FAILED,
                    "抓取失败：" + e.getMessage());
        }
    }

    private String stripHtml(String html) {
        return html.replaceAll("(?is)<script[^>]*>.*?</script>", " ")
                .replaceAll("(?is)<style[^>]*>.*?</style>", " ")
                .replaceAll("<[^>]+>", " ")
                .replace("&nbsp;", " ")
                .replace("&amp;", "&")
                .replaceAll("\\s+", " ")
                .trim();
    }

    private KnowledgeBase loadKb(Long id) {
        return kbRepository.findByIdAndDeletedFalse(id)
                .orElseThrow(() -> new BizException(ErrorCode.KB_NOT_FOUND));
    }

    private void refreshCounts(KnowledgeBase kb) {
        kb.setDocumentCount((int) documentRepository.countByKbIdAndDeletedFalse(kb.getId()));
        kb.setChunkCount((int) chunkRepository.countByKbIdAndDeletedFalse(kb.getId()));
        kbRepository.save(kb);
    }

    private static String extensionOf(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot < 0 ? "" : filename.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    private static String requireText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new BizException(ErrorCode.ADMIN_PARAM_INVALID, message);
        }
        return value.trim();
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static String defaultIfBlank(String value, String fallback) {
        return (value == null || value.isBlank()) ? fallback : value;
    }
}
