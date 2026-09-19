import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import 'api_exception.dart';

/// 认证拦截器。
///
/// 职责：
/// 1. 每个请求自动带上 `Authorization: Bearer <token>`；
/// 2. 收到 401 时触发 [onUnauthorized] 回调，由上层把用户踢回登录页。
///
/// token 的存取通过 [tokenGetter] 回调注入，避免拦截器直接依赖 AuthProvider
/// 造成循环依赖（AuthProvider 需要 ApiClient，ApiClient 又需要 AuthProvider）。
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenGetter,
    required this.onUnauthorized,
  });

  /// 读取当前 token，返回 null 表示未登录。
  final String? Function() tokenGetter;

  /// 登录态失效回调。
  final void Function() onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 登录/注册接口本身不需要带 token
    final isAuthApi = options.path.contains('/auth/login') ||
        options.path.contains('/auth/register');

    final token = tokenGetter();
    if (!isAuthApi && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 回调里只做状态清理，具体跳转由 GoRouter 的 redirect 完成
      onUnauthorized();
    }
    handler.next(err);
  }
}

/// 调试日志拦截器：只在 debug 模式打印，release 包自动关闭。
class LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.isDebug) {
      debugPrint('→ ${options.method} ${options.uri}');
      if (options.data != null) debugPrint('   body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (AppConfig.isDebug) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppConfig.isDebug) {
      debugPrint(
        '✗ ${err.requestOptions.method} ${err.requestOptions.uri} '
        '=> ${err.response?.statusCode ?? err.type.name} ${err.message ?? ''}',
      );
    }
    handler.next(err);
  }
}

/// 全局 HTTP 客户端。
///
/// 全项目只保留一个实例（在 main.dart 里创建并注入 Provider），
/// 好处是 token、拦截器、连接池都是共享的。
///
/// 后端地址来自 [AppConfig.baseUrl]，Web 走 localhost、Android 走局域网 IP，
/// 业务代码完全不用关心当前跑在哪端。
class ApiClient {
  ApiClient({required this.onUnauthorized}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        // 让 Dio 对 4xx/5xx 也抛异常，交给 ApiException.fromDio 统一翻译
        validateStatus: (status) => status != null && status >= 200 && status < 300,
        headers: {'Accept': 'application/json'},
        // 后端用 @RequestBody 接收中文时不会乱码
        contentType: Headers.jsonContentType,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        tokenGetter: () => authToken,
        onUnauthorized: onUnauthorized,
      ),
      LogInterceptor(),
    ]);
  }

  /// 登录态失效回调（由 main.dart 注入，通常是 authProvider.handleUnauthorized）。
  final void Function() onUnauthorized;

  late final Dio _dio;

  /// 当前登录 token。登录成功后写入，退出登录时置 null。
  ///
  /// 由 [AuthInterceptor] 在每次请求前读取，自动加到 Authorization 头。
  String? authToken;

  /// 底层 Dio 实例，特殊场景（如需要拿到 Response 头）可直接使用。
  Dio get dio => _dio;

  // ===========================================================================
  // 通用请求
  // ===========================================================================

  /// 发起请求并把响应解析成 [ApiResponse]。
  ///
  /// [parser] 负责把 `data` 字段转成业务模型，接口没有返回数据时传 null。
  /// 业务码非 200 时抛出 [ApiException]，调用方只需 try/catch 一种异常。
  Future<T?> request<T>({
    required String path,
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? data)? parser,
    CancelToken? cancelToken,
    Options? options,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(method: method),
        onSendProgress: onSendProgress,
      );

      final body = response.data;
      if (body == null) return null;

      final code = (body['code'] as num?)?.toInt() ?? -1;
      final message = body['message'] as String? ?? '';

      if (code != 200) {
        throw ApiException(
          message: message.isEmpty ? '请求失败' : message,
          code: code,
          statusCode: response.statusCode,
        );
      }

      final rawData = body['data'];
      if (rawData == null || parser == null) return null;
      return parser(rawData);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: '数据解析失败：$e', cause: e);
    }
  }

  Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(Object? data)? parser,
    CancelToken? cancelToken,
  }) =>
      request<T>(
        path: path,
        method: 'GET',
        queryParameters: query,
        parser: parser,
        cancelToken: cancelToken,
      );

  Future<T?> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    T Function(Object? data)? parser,
    CancelToken? cancelToken,
  }) =>
      request<T>(
        path: path,
        method: 'POST',
        data: body,
        queryParameters: query,
        parser: parser,
        cancelToken: cancelToken,
      );

  Future<T?> put<T>(
    String path, {
    Object? body,
    T Function(Object? data)? parser,
  }) =>
      request<T>(path: path, method: 'PUT', data: body, parser: parser);

  Future<T?> delete<T>(
    String path, {
    Object? body,
    T Function(Object? data)? parser,
  }) =>
      request<T>(path: path, method: 'DELETE', data: body, parser: parser);

  // ===========================================================================
  // 文件上传
  // ===========================================================================

  /// 上传文件（素材库 / 参考图）。
  ///
  /// **必须传字节流而不是文件路径**：Web 端 `XFile.path` 是 blob URL，
  /// 后端拿不到；只有字节流才能同时兼容 Android 与 Web。
  /// `image_picker` 取到的 XFile 用 `await file.readAsBytes()` 传进来即可。
  Future<T?> uploadBytes<T>({
    required String path,
    required List<int> bytes,
    required String filename,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
    T Function(Object? data)? parser,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?extraFields,
        fieldName: MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(_guessContentType(filename)),
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );

      final body = response.data;
      if (body == null) return null;

      final code = (body['code'] as num?)?.toInt() ?? -1;
      if (code != 200) {
        throw ApiException(
          message: (body['message'] as String?) ?? '上传失败',
          code: code,
          statusCode: response.statusCode,
        );
      }

      final rawData = body['data'];
      if (rawData == null || parser == null) return null;
      return parser(rawData);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: '上传失败：$e', cause: e);
    }
  }

  /// 根据扩展名粗略判断 MIME，后端做类型校验时会用到。
  static String _guessContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }
}
