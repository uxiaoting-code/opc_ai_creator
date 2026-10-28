import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/prompt_model.dart';

/// Prompt 知识库数据访问。
class PromptRepository {
  PromptRepository(this._api);

  final ApiClient _api;

  Future<PageResult<PromptModel>> fetchPrompts({
    String? category,
    String? keyword,
    int page = 1,
    int pageSize = 12,
  }) async {
    final json = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.prompts,
      query: {
        'category': ?_normalize(category),
        'keyword': ?_normalize(keyword),
        'page': page,
        'pageSize': pageSize,
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (json == null) return const PageResult.empty();
    return PageResult<PromptModel>.fromJson(
      json,
      itemParser: PromptModel.fromJson,
    );
  }

  Future<PromptModel> createPrompt({
    required String title,
    required String content,
    String? negativeContent,
    String? category,
    String? tags,
    String? coverUrl,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.prompts,
      body: {
        'title': title,
        'content': content,
        'negativeContent': ?_normalize(negativeContent),
        'category': ?_normalize(category),
        'tags': ?_normalize(tags),
        'coverUrl': ?_normalize(coverUrl),
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (json == null) {
      throw StateError('服务端未返回 Prompt 数据');
    }
    return PromptModel.fromJson(json);
  }

  Future<PromptFavoriteResult> toggleFavorite(int promptId) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.promptFavorite(promptId),
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (json == null) {
      throw StateError('服务端未返回收藏状态');
    }
    return PromptFavoriteResult(
      promptId: (json['promptId'] as num?)?.toInt() ?? promptId,
      favorited: json['favorited'] == true,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
    );
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class PromptFavoriteResult {
  const PromptFavoriteResult({
    required this.promptId,
    required this.favorited,
    required this.favoriteCount,
  });

  final int promptId;
  final bool favorited;
  final int favoriteCount;
}
