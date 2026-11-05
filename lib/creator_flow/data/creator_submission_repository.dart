import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../models/creator_order.dart';
import '../models/creator_submission.dart';

/// 作品提交与审核仓库，对应后端 `/api/submissions/**`。
class CreatorSubmissionRepository {
  CreatorSubmissionRepository(this._api);

  final ApiClient _api;

  Future<CreatorSubmission> submit({
    required int orderId,
    required int taskId,
    required String title,
    String note = '',
  }) async {
    final raw = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.submissions,
      body: {
        'orderId': orderId,
        'taskId': taskId,
        'title': title,
        'note': note,
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (raw == null) {
      throw const ApiException(message: '提交失败，服务端未返回提交记录');
    }
    return CreatorSubmission.fromJson(raw);
  }

  Future<PageResult<CreatorSubmission>> fetchMy({
    SubmissionReviewStatus? status,
    OrderMediaType? mediaType,
    int page = 1,
    int pageSize = 50,
  }) async {
    final raw = await _api.get<Map<String, dynamic>>(
      '${ApiEndpoints.submissions}/my',
      query: {
        'status': ?status?.value,
        'mediaType': ?mediaType?.value,
        'page': page,
        'pageSize': pageSize,
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (raw == null) return const PageResult.empty();
    return PageResult<CreatorSubmission>.fromJson(
      raw,
      itemParser: CreatorSubmission.fromJson,
    );
  }

  Future<CreatorSubmission> fetchDetail(int submissionId) async {
    final raw = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.submissionDetail(submissionId),
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (raw == null) {
      throw const ApiException(message: '提交记录不存在或已被删除');
    }
    return CreatorSubmission.fromJson(raw);
  }
}
