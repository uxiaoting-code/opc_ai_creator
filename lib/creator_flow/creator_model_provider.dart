import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import 'data/creator_model_repository.dart';
import 'models/creator_model.dart';

/// 按媒体类型缓存用户端可选模型。
class CreatorModelProvider extends ChangeNotifier {
  CreatorModelProvider(this._repository);

  final CreatorModelRepository _repository;

  final Map<String, List<CreatorModel>> _models = {};
  final Set<String> _loadingTypes = {};
  final Map<String, String> _errors = {};

  List<CreatorModel> modelsFor(String mediaType) {
    return List.unmodifiable(_models[mediaType] ?? const []);
  }

  bool isLoading(String mediaType) => _loadingTypes.contains(mediaType);

  String? errorFor(String mediaType) => _errors[mediaType];

  CreatorModel? findById(String mediaType, int? id) {
    if (id == null) return null;
    for (final model in _models[mediaType] ?? const <CreatorModel>[]) {
      if (model.id == id) return model;
    }
    return null;
  }

  Future<void> loadFor(String mediaType, {bool force = false}) async {
    if (_loadingTypes.contains(mediaType)) return;
    if (!force && (_models[mediaType]?.isNotEmpty ?? false)) return;

    _loadingTypes.add(mediaType);
    _errors.remove(mediaType);
    notifyListeners();

    try {
      _models[mediaType] = await _repository.fetchModels(mediaType);
      _errors.remove(mediaType);
    } on ApiException catch (error) {
      _errors[mediaType] = error.message;
    } catch (error) {
      _errors[mediaType] = '模型目录加载失败';
      debugPrint('CreatorModelProvider load failed: $error');
    } finally {
      _loadingTypes.remove(mediaType);
      notifyListeners();
    }
  }

  void clear() {
    _models.clear();
    _loadingTypes.clear();
    _errors.clear();
    notifyListeners();
  }
}
