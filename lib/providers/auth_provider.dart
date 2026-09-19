import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/user_model.dart';

/// 登录态状态管理。
///
/// 被 GoRouter 用作 `refreshListenable`：
/// [isLoggedIn] 一旦变化，路由的 redirect 会自动重跑，
/// 于是「退出登录」能立刻把用户弹回登录页，不需要手动跳转。
///
/// 注意：这个类不直接 import 页面或路由，避免循环依赖，
/// 跳转逻辑全部交给 AppRouter 的 redirect 处理。
class AuthProvider extends ChangeNotifier {
  AuthProvider({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  // --- 本地持久化 key ---
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user_id';

  String? _token;
  UserModel? _user;
  bool _loading = false;
  String? _errorMessage;

  /// 当前 token，未登录为 null。
  String? get token => _token;

  /// 当前登录用户。
  UserModel? get user => _user;

  /// 是否已登录（路由守卫依据）。
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// 是否正在请求中（登录按钮 loading 态）。
  bool get isLoading => _loading;

  /// 最近一次错误信息，登录页用来显示红字提示。
  String? get errorMessage => _errorMessage;

  /// 当前是否处于「脚手架放行」模式，登录页据此显示提示横幅。
  bool get isBypassMode => AppConfig.bypassLogin;

  // ===========================================================================
  // 启动恢复
  // ===========================================================================

  /// App 启动时调用：从本地恢复上次的登录态。
  ///
  /// 拿本地 token 直接放行，真正的有效性由后端 401 来判定
  /// （由 [AuthInterceptor] 触发 [handleUnauthorized]）。
  Future<void> restoreSession() async {
    if (AppConfig.bypassLogin && _token == null) {
      // 脚手架模式：直接给一个模拟会话，省得每次热重载都要重新登录
      _applyMockSession();
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      if (savedToken == null || savedToken.isEmpty) return;

      _token = savedToken;
      _api.authToken = savedToken;

      // 缓存里的用户信息先顶上，随后再拉一次最新的
      final userId = prefs.getInt(_userKey);
      if (userId != null) {
        _user = UserModel(id: userId, username: 'user_$userId');
      }
      notifyListeners();

      await loadProfile();
    } catch (e) {
      debugPrint('恢复登录态失败: $e');
    }
  }

  // ===========================================================================
  // 登录 / 注册
  // ===========================================================================

  /// 登录。
  ///
  /// 返回 null 表示成功，否则返回错误提示文案（页面直接展示）。
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    try {
      if (AppConfig.bypassLogin) {
        // ---- 脚手架模式：不调后端，本地造一个会话 ----
        await Future<void>.delayed(const Duration(milliseconds: 300));
        _applyMockSession(username: username);
        debugPrint('[AuthProvider] 脚手架模式登录，未调用后端接口');
        return null;
      }

      // ---- 真实接口：POST /api/auth/login ----
      final result = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        body: {'username': username, 'password': password},
        parser: (data) => Map<String, dynamic>.from(data as Map),
      );

      final token = result?['token'] as String?;
      if (token == null || token.isEmpty) {
        return '登录失败：服务端未返回 token';
      }

      await _saveSession(
        token: token,
        user: result?['user'] == null
            ? null
            : UserModel.fromJson(Map<String, dynamic>.from(result!['user'] as Map)),
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '登录失败：$e';
    } finally {
      _setLoading(false);
    }
  }

  /// 注册。参数与后端 `/api/auth/register` 对应。
  Future<String?> register({
    required String username,
    required String password,
    String? nickname,
    String? email,
  }) async {
    _setLoading(true);
    try {
      if (AppConfig.bypassLogin) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        _applyMockSession(username: username, nickname: nickname);
        return null;
      }

      await _api.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        body: {
          'username': username,
          'password': password,
          'nickname': ?nickname,
          'email': ?email,
        },
        parser: (data) => Map<String, dynamic>.from(data as Map),
      );

      // 注册成功后直接登录，省一次输入
      return await login(username: username, password: password);
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '注册失败：$e';
    } finally {
      _setLoading(false);
    }
  }

  /// 退出登录：清本地状态，路由守卫会自动把人送回登录页。
  Future<void> logout() async {
    try {
      if (!AppConfig.bypassLogin) {
        await _api.post<void>(ApiEndpoints.logout);
      }
    } catch (_) {
      // 退出接口失败也要让本地登出，不能把用户卡在登录态
    }

    _token = null;
    _user = null;
    _api.authToken = null;
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}

    notifyListeners();
  }

  // ===========================================================================
  // 用户资料
  // ===========================================================================

  /// 拉取当前用户信息（含真实算力点），首页 / 个人中心共用。
  ///
  /// ⚠️ 这里**不能**判断 [AppConfig.bypassLogin]：那个开关只表示
  /// 「不走 /auth/login 表单」，而开发令牌（mock-token-for-scaffold）
  /// 在后端会被 AuthInterceptor 映射成 demo 账号，
  /// `/api/auth/profile` 是能正常返回数据库真实 credits 的。
  ///
  /// 之前把 bypassLogin 一起挡掉，导致这个接口在脚手架模式下永远
  /// 不会被调用，首页只能显示 [_applyMockSession] 里写死的假值。
  Future<void> loadProfile() async {
    if (!isLoggedIn) return;
    try {
      final user = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.profile,
        parser: (data) => Map<String, dynamic>.from(data as Map),
      );
      if (user != null) {
        _user = UserModel.fromJson(user);
        notifyListeners();
      }
    } on ApiException catch (e) {
      debugPrint('获取用户资料失败: ${e.message}');
    }
  }

  /// 更新本地用户信息（编辑昵称后调用，避免多一次网络请求）。
  void updateLocalUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  // ===========================================================================
  // 登录态失效
  // ===========================================================================

  /// 由 [ApiClient] 在收到 401 时回调。
  ///
  /// 这里只清状态，不跳转 —— [notifyListeners] 会让 GoRouter 的 redirect
  /// 自动把用户送回登录页，逻辑只有一份。
  void handleUnauthorized() {
    if (!isLoggedIn) return;
    _token = null;
    _user = null;
    _api.authToken = null;
    _errorMessage = '登录已过期，请重新登录';
    notifyListeners();
  }

  // ===========================================================================
  // 内部方法
  // ===========================================================================

  Future<void> _saveSession({required String token, UserModel? user}) async {
    _token = token;
    _api.authToken = token;
    _user = user ?? _user;
    _errorMessage = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      if (_user != null) await prefs.setInt(_userKey, _user!.id);
    } catch (e) {
      debugPrint('保存登录态失败: $e');
    }

    notifyListeners();
  }

  /// 脚手架模式下的模拟会话。
  void _applyMockSession({String username = 'demo_creator', String? nickname}) {
    const mockToken = 'mock-token-for-scaffold';
    _token = mockToken;
    _api.authToken = mockToken;
    _user = UserModel(
      id: 1,
      username: username.isEmpty ? 'demo_creator' : username,
      nickname: nickname ?? '课设演示账号',
      role: 'USER',
      // 不再写死算力点：真实值由 loadProfile() 从 /api/auth/profile 拉取。
      // 这里留空表示「尚未知」，首页在拿到数据前显示占位符 `—`，
      // 而不是先给一个骗人的数字。
      createdAt: '2026-01-01T00:00:00',
    );
    _errorMessage = null;
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  /// 清掉上一次的错误提示（切换登录/注册 Tab 时调用）。
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
