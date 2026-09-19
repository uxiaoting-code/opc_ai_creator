import 'package:dio/dio.dart';

/// 统一的业务异常。
///
/// 所有网络/后端错误都会被 [ApiClient] 归一成这个类型，
/// UI 层只需捕获 [ApiException] 并展示 [message] 即可，
/// 不用关心底层是 Dio 超时还是 HTTP 500。
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.cause,
  });

  /// 面向用户的错误提示（中文，可直接上屏）。
  final String message;

  /// 业务状态码（后端 Result.code），网络层错误时为 null。
  final int? code;

  /// HTTP 状态码。
  final int? statusCode;

  /// 原始异常，便于调试。
  final Object? cause;

  // --- 常见错误快捷构造 ---

  /// 401：登录态失效，会被 AuthInterceptor 拦截并踢回登录页。
  bool get isUnauthorized => statusCode == 401 || code == 401;

  /// 是否是网络不通（手机没连 WiFi / 后端没启动）。
  bool get isNetworkError => statusCode == null && code == null;

  factory ApiException.network([Object? cause]) => ApiException(
        message: '网络连接失败，请检查手机与电脑是否在同一 WiFi，以及后端是否已启动',
        cause: cause,
      );

  factory ApiException.timeout([Object? cause]) => ApiException(
        message: '请求超时，AI 生成耗时较长时可稍后在「我的任务」中查看结果',
        cause: cause,
      );

  factory ApiException.unauthorized() => const ApiException(
        message: '登录已过期，请重新登录',
        code: 401,
        statusCode: 401,
      );

  factory ApiException.canceled() => const ApiException(message: '请求已取消');

  /// 把 DioException 翻译成用户看得懂的中文提示。
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return ApiException.timeout(e);

      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: '等待响应超时，任务可能仍在后台生成，请稍后刷新任务列表',
        );

      case DioExceptionType.connectionError:
        return ApiException.network(e);

      case DioExceptionType.cancel:
        return ApiException.canceled();

      case DioExceptionType.badCertificate:
        return const ApiException(message: '证书校验失败');

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        // 后端即使出错也会返回统一响应体，优先取里面的 message
        final data = e.response?.data;
        String? serverMessage;
        int? bizCode;
        if (data is Map) {
          serverMessage = data['message'] as String?;
          bizCode = (data['code'] as num?)?.toInt();
        }
        if (status == 401) return ApiException.unauthorized();
        return ApiException(
          message: serverMessage ?? _httpMessage(status),
          code: bizCode,
          statusCode: status,
          cause: e,
        );

      case DioExceptionType.unknown:
        return ApiException(
          message: '请求失败：${e.message ?? '未知错误'}',
          cause: e,
        );
    }
  }

  static String _httpMessage(int? status) {
    switch (status) {
      case 400:
        return '请求参数有误';
      case 403:
        return '没有权限执行该操作';
      case 404:
        return '请求的接口不存在';
      case 500:
        return '服务器开小差了，请稍后重试';
      case 502:
      case 503:
        return '服务暂时不可用，请稍后重试';
      default:
        return '请求失败${status == null ? '' : '（HTTP $status）'}';
    }
  }

  @override
  String toString() =>
      'ApiException(code: $code, status: $statusCode, message: $message)';
}
