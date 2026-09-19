import 'package:flutter/foundation.dart';

/// 后端统一响应体，与 SpringBoot 的 `Result<T>` 一一对应。
///
/// 后端返回格式约定：
/// ```json
/// { "code": 200, "message": "success", "data": { ... }, "timestamp": 1737000000000 }
/// ```
///
/// 泛型 [T] 是 `data` 字段反序列化后的类型。
@immutable
class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.timestamp,
  });

  /// 业务状态码，200 表示成功。
  final int code;

  /// 提示信息，失败时直接展示给用户。
  final String message;

  /// 业务数据，可能为 null（例如删除接口）。
  final T? data;

  /// 服务端时间戳（毫秒）。
  final int? timestamp;

  /// 业务是否成功。
  bool get isSuccess => code == 200;

  /// 从 JSON 构造，[fromJsonT] 负责把 `data` 转成业务模型。
  ///
  /// 用法：
  /// ```dart
  /// ApiResponse.fromJson(json, (d) => UserModel.fromJson(d as Map<String, dynamic>))
  /// ```
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? data)? fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      code: (json['code'] as num?)?.toInt() ?? -1,
      message: json['message'] as String? ?? '',
      data: (rawData == null || fromJsonT == null) ? null : fromJsonT(rawData),
      timestamp: (json['timestamp'] as num?)?.toInt(),
    );
  }

  /// 列表接口的便捷构造：`data` 是数组时用这个。
  static ApiResponse<List<Map<String, dynamic>>> listFromJson(
    Map<String, dynamic> json,
  ) {
    return ApiResponse.fromJson(json, (data) {
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }

  /// 分页响应。
  static ApiResponse<PageResult<Map<String, dynamic>>> pageFromJson(
    Map<String, dynamic> json,
  ) {
    return ApiResponse.fromJson(json, (data) {
      if (data is! Map) return const PageResult.empty();
      return PageResult.fromJson(Map<String, dynamic>.from(data));
    });
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'data': data,
        'timestamp': timestamp,
      };

  @override
  String toString() => 'ApiResponse(code: $code, message: $message, data: $data)';
}

/// 分页结果包装，对应后端 `PageResult<T>`。
@immutable
class PageResult<T> {
  const PageResult({
    required this.list,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  const PageResult.empty()
      : list = const [],
        page = 1,
        pageSize = 10,
        total = 0;

  final List<T> list;
  final int page;
  final int pageSize;
  final int total;

  /// 是否还有下一页，滚动加载时判断。
  bool get hasMore => page * pageSize < total;

  int get totalPages => pageSize <= 0 ? 0 : ((total + pageSize - 1) ~/ pageSize);

  factory PageResult.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic>)? itemParser,
  }) {
    final rawList = json['list'] ?? json['records'] ?? const [];
    return PageResult<T>(
      list: itemParser == null || rawList is! List
          ? const []
          : rawList
              .whereType<Map>()
              .map((e) => itemParser(Map<String, dynamic>.from(e)))
              .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
