package com.opc.server.controller;

import com.opc.server.common.BizException;
import com.opc.server.common.ErrorCode;
import com.opc.server.common.Result;
import com.opc.server.config.StorageProperties;
import com.opc.server.dto.MaterialResponse;
import com.opc.server.entity.Material;
import com.opc.server.repository.MaterialRepository;
import com.opc.server.security.UserContext;
import com.opc.server.storage.FileStorageService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Locale;
import java.util.Optional;

/**
 * 素材接口 —— 前端上传首帧参考图（图生视频）与垫图时用它。
 *
 * <p>路径与前端 {@code ApiEndpoints.materials} / {@code materialUpload} 对应。
 *
 * <p><b>关于"上传"这件事的设计取舍</b>：接口直接在响应里返回图片的访问 URL，
 * 而不返回一段一次性的上传凭证。课设里图片就存在本机磁盘、由本服务自己
 * 通过 {@code /upload/**} 提供访问，两步走没有收益。真接了对象存储（OSS/S3）
 * 才需要改成「前端直传 + 后端只发凭证」的形态，那时换的是这个 Controller，
 * 调用方拿到的仍然是一个 URL，契约不变。
 */
@RestController
@RequestMapping("/api/materials")
public class MaterialController {

    private static final Logger log = LoggerFactory.getLogger(MaterialController.class);

    /** 素材名长度上限，与 t_material.name 的 VARCHAR(100) 对齐。 */
    private static final int MAX_NAME_LENGTH = 100;

    private final FileStorageService storage;
    private final MaterialRepository materialRepository;
    private final StorageProperties storageProperties;

    public MaterialController(FileStorageService storage,
                              MaterialRepository materialRepository,
                              StorageProperties storageProperties) {
        this.storage = storage;
        this.materialRepository = materialRepository;
        this.storageProperties = storageProperties;
    }

    /**
     * 上传一张图片素材。
     *
     * <p>三重校验的顺序是有意为之：**先看有没有、再看是不是图片、最后看大不大**。
     * 顺序反过来的话，一个 200MB 的 .exe 会先被读进内存做大小判断，
     * 白白吃一次内存 —— 而它其实在第二步就该被类型拦掉。
     *
     * @return 含访问 URL 的素材记录，前端拿 {@code url} 去创建任务
     */
    @PostMapping("/upload")
    public Result<MaterialResponse> upload(@RequestParam("file") MultipartFile file) {
        // ---- 1. 空文件 ----
        if (file == null || file.isEmpty()) {
            throw new BizException(ErrorCode.FILE_EMPTY);
        }

        // ---- 2. 类型：必须是图片 ----
        // 注意这里只信 Content-Type。要防住伪造需要读文件头做 magic number 校验，
        // 课设场景下前端已经用 image_picker 限制过，风险可接受。
        String contentType = file.getContentType();
        if (contentType == null
                || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
            throw new BizException(ErrorCode.FILE_TYPE_NOT_ALLOWED,
                    "只支持上传图片，当前类型：" + contentType);
        }

        // ---- 3. 体积 ----
        long maxSize = storageProperties.getMaxImageSize();
        if (file.getSize() > maxSize) {
            throw new BizException(ErrorCode.FILE_TOO_LARGE,
                    "图片体积超出限制（最大 %d MB）".formatted(maxSize / 1024 / 1024));
        }

        // ---- 4. 落盘 ----
        String originalName = file.getOriginalFilename();
        byte[] bytes;
        try {
            bytes = file.getBytes();
        } catch (IOException e) {
            log.error("读取上传文件失败 name={}", originalName, e);
            throw new BizException(ErrorCode.FILE_SAVE_FAILED);
        }

        String url = storage.saveBytes(bytes, extensionOf(originalName), "material");

        // ---- 5. 落库 ----
        // 上传记录留一份：素材库页面之后直接查这张表，
        // 而且任务表里的 ref_image_url 指向的文件到底是谁传的，也查得回源头。
        Material material = Material.builder()
                .userId(UserContext.require())
                .name(truncateName(originalName))
                .url(url)
                .fileSize(file.getSize())
                .mimeType(contentType)
                .source("UPLOAD")
                .deleted(false)
                .build();

        Material saved = materialRepository.save(material);
        log.info("素材上传成功 id={} url={} size={}B", saved.getId(), url, file.getSize());

        return Result.success(MaterialResponse.from(saved), "上传成功");
    }

    /**
     * 从原始文件名里取扩展名。
     *
     * <p><b>安全要点</b>：扩展名会被拼进磁盘文件名，所以必须过滤掉
     * 一切非字母数字的字符。否则 {@code a.png/../../evil} 这种文件名
     * 能把文件写到上传目录之外。
     */
    private static String extensionOf(String filename) {
        if (filename == null) {
            return "png";
        }
        int dot = filename.lastIndexOf('.');
        if (dot < 0 || dot == filename.length() - 1) {
            return "png";
        }
        String ext = filename.substring(dot + 1)
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]", "");
        return ext.isEmpty() ? "png" : ext;
    }

    /** 素材名截断到列宽以内，避免超长文件名把插入语句打挂。 */
    private static String truncateName(String filename) {
        if (filename == null || filename.isBlank()) {
            return "未命名素材";
        }
        String name = filename.trim();
        return name.length() > MAX_NAME_LENGTH ? name.substring(0, MAX_NAME_LENGTH) : name;
    }
    /**
     * 查询我上传的素材列表，分页
     */
    @GetMapping("/my")
    public Result<Page<MaterialResponse>> getMyMaterials(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size){
        Long userId = UserContext.require();
        Pageable pageable = PageRequest.of(page, size);
        Page<Material> pageData = materialRepository.findByUserIdAndDeletedFalseOrderByCreatedAtDesc(userId,pageable);
        Page<MaterialResponse> respPage = pageData.map(MaterialResponse::from);
        return Result.success(respPage);
    }

    /**
     * 删除素材，逻辑删除
     */
    @DeleteMapping("/{id}")
    public Result<Void> deleteMaterial(@PathVariable Long id){
        Long userId = UserContext.require();
        Optional<Material> opt = materialRepository.findByIdAndUserIdAndDeletedFalse(id,userId);
        if(opt.isEmpty()){
            throw new BizException(ErrorCode.NOT_FOUND,"素材不存在或无权限");
        }
        Material material = opt.get();
        material.setDeleted(true);
        materialRepository.save(material);
        return Result.success(null,"删除成功");
    }

}
