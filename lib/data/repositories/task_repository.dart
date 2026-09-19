import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/task_model.dart';

/// AI 任务数据仓库（Harness 链路）。
///
/// **这个仓库没有 Mock 分支，和 SkillRepository / WorkRepository 不一样。**
///
/// 原因：任务不是「数据」而是「一次真实的服务端执行」——
/// 排队、调度、调用服务商、落作品全在后端的 Harness 里完成，
/// 前端本地造一个假任务既没有状态流转也没有结果图，
/// 演示时反而会掩盖链路到底通没通。
/// 所以任务相关的接口一律走真实后端（后端默认的 `mock` 服务商就是那个"假"，
/// 它负责在没有真实模型的情况下把链路跑通）。
class TaskRepository {
  TaskRepository(this._api);

  final ApiClient _api;

  // ===========================================================================
  // 创建任务
  // ===========================================================================

  /// 提交文生图任务。
  ///
  /// 后端**立刻返回一个排队中的任务**，不会阻塞等图片生成完
  /// （AI 生成是异步的，HTTP 请求不能挂几十秒）。
  /// 拿到返回值后用 `task.id` 跳任务详情页轮询进度。
  ///
  /// [skillId] 为空时后端用默认参数生成；
  /// [prompt] 会在后端被套进线路模板（拼上风格前缀 / 后缀）。
  Future<TaskModel> createTextToImage({
    int? skillId,
    required String prompt,
    String? negativePrompt,
  }) {
    return _create(
      ApiEndpoints.textToImage,
      skillId: skillId,
      prompt: prompt,
      negativePrompt: negativePrompt,
    );
  }

  /// 提交图生视频任务（首帧参考图必填）。
  ///
  /// 目前「图生视频创作页」还没实现（页面 4），这里先把接口备好 ——
  /// 后端 `POST /api/creation/image-to-video` 已经能用，
  /// 等页面开发时直接调，不用再动仓库层。
  Future<TaskModel> createImageToVideo({
    int? skillId,
    required String prompt,
    String? negativePrompt,
    required String refImageUrl,
  }) {
    return _create(
      ApiEndpoints.imageToVideo,
      skillId: skillId,
      prompt: prompt,
      negativePrompt: negativePrompt,
      refImageUrl: refImageUrl,
    );
  }

  /// 两个创作接口的请求体结构完全一样，差异只在路径，
  /// 所以共用这一个实现。
  ///
  /// 注意 body 里**不能有 type 字段**：类型由后端接口路径决定
  /// （见 `CreationRequest` 的注释），传了也是多余的。
  Future<TaskModel> _create(
    String path, {
    int? skillId,
    required String prompt,
    String? negativePrompt,
    String? refImageUrl,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      path,
      body: {
        'skillId': ?skillId,
        'prompt': prompt,
        'negativePrompt': ?negativePrompt,
        'refImageUrl': ?refImageUrl,
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    if (json == null) {
      // 走到这里说明 HTTP 200、业务码 200，但 data 是空的。
      // 属于后端契约异常，给一句能看懂的提示而不是让页面空指针。
      throw const ApiException(message: '服务端未返回任务信息，请稍后重试');
    }
    return TaskModel.fromJson(json);
  }

  // ===========================================================================
  // 查询
  // ===========================================================================

  /// 查询单个任务详情。任务详情页靠它做轮询。
  ///
  /// 后端会顺带把 `statusLabel` / `canRetry` / `canCancel` / `finished` 一起返回，
  /// 所以前端不需要自己再实现一遍状态机规则。
  Future<TaskModel> fetchDetail(int taskId) async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.taskDetail(taskId),
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    if (json == null) {
      throw const ApiException(message: '任务不存在或已被删除');
    }
    return TaskModel.fromJson(json);
  }

  // ===========================================================================
  // 列表 / 重试 / 取消
  // ===========================================================================

  /// 分页查询我的任务。
  ///
  /// [status] 为空表示查全部。**筛选走后端而不是前端** ——
  /// `GET /api/tasks` 本身支持 status 参数，如果在本地过滤，
  /// "只看失败任务"就得先把所有任务都拉下来才行。
  ///
  /// 后端返回的是 `PageResult`（`list / page / pageSize / total`），
  /// 不是纯数组，别按数组解析。
  Future<PageResult<TaskModel>> fetchTasks({
    TaskStatus? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final raw = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.tasks,
      query: {
        'status': ?status?.value,
        'page': page,
        'pageSize': pageSize,
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    if (raw == null) return const PageResult.empty();
    return PageResult<TaskModel>.fromJson(raw, itemParser: TaskModel.fromJson);
  }

  /// 失败重试。后端把任务重新丢回队列（状态回到 QUEUED）并返回更新后的任务。
  ///
  /// 只有 FAILED 且没耗尽重试次数的任务能重试，否则后端返回业务错误。
  Future<TaskModel> retryTask(int taskId) =>
      _taskAction(ApiEndpoints.taskRetry(taskId));

  /// 取消排队中的任务。只有 QUEUED 状态可以取消。
  Future<TaskModel> cancelTask(int taskId) =>
      _taskAction(ApiEndpoints.taskCancel(taskId));

  /// 重试 / 取消两个接口的返回结构一致，共用这一个实现。
  Future<TaskModel> _taskAction(String path) async {
    final json = await _api.post<Map<String, dynamic>>(
      path,
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    if (json == null) {
      throw const ApiException(message: '服务端未返回任务信息，请刷新后重试');
    }
    return TaskModel.fromJson(json);
  }

  /// 各状态的任务数量，个人中心的数据统计用它。
  ///
  /// 后端返回 `Result<Map<String, Long>>`，键是状态名（SUCCESS / FAILED …），
  /// 值是数量。**数量为 0 的状态不会出现在这个 map 里**，
  /// 所以取值一律 `?? 0`，不能假设 key 一定存在。
  Future<Map<String, int>> fetchTaskStats() async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.taskStats,
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (json == null) return const {};

    return {
      for (final entry in json.entries)
        entry.key: (entry.value as num?)?.toInt() ?? 0,
    };
  }
}
