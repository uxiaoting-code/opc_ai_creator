import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../datasources/mock_data.dart';
import '../models/skill_model.dart';

/// Skill 线路数据仓库。
///
/// 首页横滑列表与 Skill 市场页共用。
///
/// 数据来源由 [AppConfig.useMockData] 决定：
/// - true  → 返回 `MockData` 本地假数据（后端未就绪时）
/// - false → 调 `GET /api/skills`
///
/// 页面只依赖这个类的方法签名，**切换数据源不需要改任何页面代码**。
class SkillRepository {
  SkillRepository(this._api);

  final ApiClient _api;

  /// 查询线路列表。
  ///
  /// [type] 为空表示查全部；传 [SkillType.textToImage] 只查文生图线路。
  /// [limit] 用于首页只取前几条。
  Future<List<SkillModel>> fetchSkills({
    SkillType? type,
    int? limit,
  }) async {
    // ---- Mock 分支 ----
    if (AppConfig.useMockData) {
      await Future<void>.delayed(MockData.latency);
      var result = List<SkillModel>.from(MockData.skills);
      if (type != null) {
        result = result.where((s) => s.type == type).toList();
      }
      if (limit != null && result.length > limit) {
        result = result.take(limit).toList();
      }
      return result;
    }

    // ---- 真实接口分支 ----
    final list = await _api.get<List<Map<String, dynamic>>>(
      ApiEndpoints.skills,
      query: {
        'type': ?type?.value,
        'limit': ?limit,
      },
      parser: _parseList,
    );
    return (list ?? const []).map(SkillModel.fromJson).toList();
  }

  /// 查询单条线路详情（Skill 市场点开参数面板时用）。
  Future<SkillModel?> fetchSkillDetail(int id) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(MockData.latency);
      return MockData.skills.where((s) => s.id == id).firstOrNull;
    }

    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.skillDetail(id),
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    return json == null ? null : SkillModel.fromJson(json);
  }

  /// 把后端返回的 JSON 数组转成 Map 列表。
  ///
  /// `whereType<Map>()` 是为了跳过脏数据，避免一条异常记录让整个列表加载失败。
  static List<Map<String, dynamic>> _parseList(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
