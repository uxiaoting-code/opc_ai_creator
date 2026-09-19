import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/skill_model.dart';
import '../data/repositories/skill_repository.dart';

/// Skill 创作线路状态管理。
///
/// 首页横滑列表与 Skill 市场页共用同一份数据，
/// 所以状态放在这里而不是页面内部 —— 两个页面看到的是同一份缓存，
/// 在市场上收藏了某条线路，回首页也是最新的。
class SkillProvider extends ChangeNotifier {
  SkillProvider({required this._repository});

  final SkillRepository _repository;

  List<SkillModel> _skills = const [];
  bool _isLoading = false;
  String? _error;

  /// 全部线路。
  List<SkillModel> get skills => _skills;

  bool get isLoading => _isLoading;

  /// 错误提示，非 null 时页面展示重试界面。
  String? get error => _error;

  /// 是否已经加载过（用于 loadIfNeeded 判断）。
  bool get hasLoaded => _skills.isNotEmpty || _error != null;

  /// 文生图线路。
  List<SkillModel> get textToImageSkills =>
      _skills.where((s) => s.type == SkillType.textToImage).toList();

  /// 图生视频线路。
  List<SkillModel> get imageToVideoSkills =>
      _skills.where((s) => s.type == SkillType.imageToVideo).toList();

  /// 首页横滑区展示的线路（只取前几条，列表太长反而不好滑）。
  List<SkillModel> get featuredSkills => _skills.take(6).toList();

  /// 首次加载：已经加载过就直接返回，避免每次切 Tab 都重新请求。
  ///
  /// 注意不能写成 `if (hasLoaded) return;`，因为首次加载失败时
  /// `hasLoaded` 也会变成 true，导致重试按钮点了没反应。
  Future<void> loadIfNeeded() async {
    if (_skills.isNotEmpty || _isLoading) return;
    await load();
  }

  /// 加载线路列表。
  ///
  /// [force] 为 true 时忽略缓存强制重新请求（下拉刷新用）。
  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _skills.isNotEmpty) return;

    _isLoading = true;
    // 重新加载时先清掉上一次的错误，否则重试成功前会一直显示错误界面
    _error = null;
    notifyListeners();

    try {
      _skills = await _repository.fetchSkills();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      // 加载失败时保留旧数据（如果有），避免下拉刷新失败后列表变空
      if (force && _skills.isEmpty) _skills = const [];
    } catch (e) {
      _error = '加载创作线路失败：$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 下拉刷新。
  Future<void> refresh() => load(force: true);

  /// 按 ID 找线路，找不到返回 null。
  SkillModel? findById(int? id) {
    if (id == null) return null;
    for (final skill in _skills) {
      if (skill.id == id) return skill;
    }
    return null;
  }
}
