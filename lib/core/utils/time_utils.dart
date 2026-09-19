import 'package:intl/intl.dart';

/// 时间格式化工具。
///
/// 命名为 time_utils 而不是 date_utils，是为了避开 Flutter 自带的
/// `DateUtils`（在 `package:flutter/material.dart` 里），防止 import 冲突。
class TimeUtils {
  const TimeUtils._();

  /// 相对时间文案：刚刚 / 5分钟前 / 3小时前 / 昨天 / 06-12。
  ///
  /// 任务列表、作品列表都用这个，比直接显示时间戳友好得多。
  static String relative(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final diff = now.difference(time);

    // 未来时间（服务器时间偏差）按「刚刚」处理，避免出现「-1分钟前」
    if (diff.isNegative) return '刚刚';

    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';

    // 超过一周显示具体日期
    return DateFormat('MM-dd').format(time);
  }

  /// 完整时间：2026-09-15 14:30
  static String full(DateTime? time) {
    if (time == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(time);
  }

  /// 只到分钟：09-15 14:30
  static String shortDateTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('MM-dd HH:mm').format(time);
  }

  /// 耗时文案：把毫秒转成「1分23秒」。
  ///
  /// 任务详情页展示生成耗时用。
  static String duration(int? milliseconds) {
    if (milliseconds == null || milliseconds <= 0) return '';
    final seconds = milliseconds ~/ 1000;
    if (seconds < 60) return '$seconds秒';
    final minutes = seconds ~/ 60;
    final remainSeconds = seconds % 60;
    if (remainSeconds == 0) return '$minutes分钟';
    return '$minutes分$remainSeconds秒';
  }
}
