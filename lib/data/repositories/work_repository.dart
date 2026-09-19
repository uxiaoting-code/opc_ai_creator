import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../datasources/mock_data.dart';
import '../models/work_model.dart';

/// 作品数据仓库。
///
/// 首页「最近生成作品」横滑区与作品画廊页共用。
class WorkRepository {
  WorkRepository(this._api);

  final ApiClient _api;

  /// 查询当前用户的作品，按创建时间倒序。
  ///
  /// [limit] 首页只要最近几条，画廊页则配合 [page] 分页拉取。
  Future<List<WorkModel>> fetchMyWorks({
    int? limit,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(MockData.latency);
      final all = MockData.works;
      final take = limit ?? pageSize;
      // 简单分页，保证 Mock 与真实分页接口的行为一致
      final start = (page - 1) * pageSize;
      if (start >= all.length) return const [];
      return all.skip(start).take(take).toList();
    }

    final list = await _api.get<List<Map<String, dynamic>>>(
      ApiEndpoints.works,
      query: {'page': page, 'pageSize': pageSize, 'limit': ?limit},
      parser: _parseList,
    );
    return (list ?? const []).map(WorkModel.fromJson).toList();
  }

  /// 作品详情（作品详情页用）。本轮首页暂未使用，先按同一套模式备好。
  Future<WorkModel?> fetchWorkDetail(int id) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(MockData.latency);
      return MockData.works.where((w) => w.id == id).firstOrNull;
    }

    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.workDetail(id),
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    return json == null ? null : WorkModel.fromJson(json);
  }

  static List<Map<String, dynamic>> _parseList(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
