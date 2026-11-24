import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../models/creator_model.dart';

/// 用户端模型目录数据源，对应 `GET /api/creation/models`。
class CreatorModelRepository {
  CreatorModelRepository(this._api);

  final ApiClient _api;

  Future<List<CreatorModel>> fetchModels(String mediaType) async {
    final list = await _api.get<List<CreatorModel>>(
      ApiEndpoints.creationModels,
      query: {'mediaType': mediaType},
      parser: (data) {
        if (data is! List) return const [];
        return data
            .whereType<Map>()
            .map(
              (item) => CreatorModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      },
    );
    return list ?? const [];
  }
}
