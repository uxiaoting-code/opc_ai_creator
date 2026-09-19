import 'dart:typed_data';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/material_model.dart';

/// 素材数据仓库：上传、查询、删除。
///
/// 图生视频必须带首帧参考图，而后端 `CreationRequest.refImageUrl` 要的是一个
/// **已经落盘的 URL**，所以提交流程天然是两步：先传图拿 url，再拿 url 去建任务。
///
/// 为什么不做成「图片和任务参数塞进同一个 multipart 接口」：
/// 图片和任务的生命周期不一样。上传成功但创建任务失败（比如算力点不足）时，
/// 那张图在素材库里依然是可用资产，用户重试不用重新选图。
///
/// **没有 Mock 分支**，和 [TaskRepository] 同理：上传是真实的服务端行为，
/// 本地造假数据只会掩盖链路到底通没通。
class MaterialRepository {
  MaterialRepository(this._api);

  final ApiClient _api;

  /// 上传一张图片，返回可直接填进 `refImageUrl` 的地址。
  ///
  /// [bytes] 必须是字节流而不是文件路径：Web 端 `XFile.path` 是 `blob:` 开头的
  /// 临时 URL，后端根本拿不到；只有字节流能同时兼容 Android 与 Web。
  /// 用 `MediaUtils.readBytes(xfile)` 拿字节流即可。
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final json = await _api.uploadBytes<Map<String, dynamic>>(
      // 注意：uploadBytes 的 path 是**具名**参数（get/post 才是位置参数），
      // 和其他方法不一样，这里必须写 path:
      path: ApiEndpoints.materialUpload,
      bytes: bytes,
      filename: filename,
      // 与后端 MaterialController 的 @RequestParam("file") 对齐
      fieldName: 'file',
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    // 走到这里说明 HTTP 200、业务码 200，但没有可用地址 ——
    // 属于后端契约异常，给一句能看懂的提示而不是让页面拿到空字符串去建任务
    final url = json?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const ApiException(message: '图片已上传，但服务端未返回可访问地址');
    }
    return url;
  }

  // ===========================================================================
  // 查询 / 删除
  // ===========================================================================

  /// 查询我上传的素材（分页）。
  ///
  /// 后端 `GET /api/materials/my` 返回的是 `Result<Page<MaterialResponse>>`，
  /// 也就是 `data` 里面是 Spring Data 的 **Page 结构**，素材列表在其
  /// `content` 字段里 —— 不是直接一个数组，别按数组解析。
  Future<List<MaterialModel>> fetchMyMaterials({
    int page = 0,
    int size = 20,
  }) async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.materialMine,
      query: {'page': page, 'size': size},
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    final content = json?['content'];
    if (content is! List) return const [];

    // whereType<Map> 跳过脏数据，避免一条异常记录让整个列表加载失败
    return content
        .whereType<Map>()
        .map((e) => MaterialModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 逻辑删除一条素材。
  ///
  /// 后端返回的 `data` 是 null，所以用 `delete<void>` 不传 parser。
  /// 删除失败（素材不存在 / 无权限）会抛 [ApiException]，由调用方提示用户 ——
  /// 不能静默吞掉，否则用户会以为删成功了，刷新一下东西又回来。
  Future<void> deleteMaterial(int id) async {
    await _api.delete<void>(ApiEndpoints.materialDetail(id));
  }
}
