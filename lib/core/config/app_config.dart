import 'package:flutter/foundation.dart';

/// 运行环境枚举。
///
/// 通过 [AppConfig.env] 一键切换，业务代码不要直接判断平台，
/// 统一走 `AppConfig.baseUrl` 拿后端地址。
enum AppEnv {
  /// Chrome / 浏览器调试：后端跑在本机，直接用 localhost
  webDev,

  /// Android 真机 / 模拟器：必须用局域网 IP，手机访问不到 localhost
  androidDevice,

  /// 生产环境：换成线上域名即可
  production,
}

/// 全局环境配置。
///
/// 一键切换方式（三种任选其一）：
/// 1. 直接改下面的 [AppConfig.env] 常量；
/// 2. 运行/打包时用 --dart-define=APP_ENV=android，无需改代码；
/// 3. 只想临时改后端 IP，改 [lanHost] 即可。
///
/// 例：
/// ```bash
/// flutter run -d chrome --dart-define=APP_ENV=webDev
/// flutter build apk   --dart-define=APP_ENV=androidDevice --dart-define=LAN_HOST=192.168.1.20
/// ```
class AppConfig {
  const AppConfig._();

  // ---------------------------------------------------------------------------
  // 一键切换区：改这里就够了
  // ---------------------------------------------------------------------------

  /// 电脑的局域网 IP。
  ///
  /// 查看方式（Windows）：命令行执行 `ipconfig`，找「IPv4 地址」，
  /// 形如 192.168.x.x / 10.x.x.x。手机和电脑必须在同一个 WiFi 下。
  /// 后端 SpringBoot 需监听 0.0.0.0，不能用 127.0.0.1。
  static const String lanHost = String.fromEnvironment(
    'LAN_HOST',
    defaultValue: '192.168.1.100',
  );

  /// 后端端口，与 application.yml 里的 server.port 保持一致。
  static const int serverPort = int.fromEnvironment(
    'SERVER_PORT',
    defaultValue: 8080,
  );

  /// 是否强制使用 localhost（比如 Android 模拟器上跑端口转发时可用）。
  static const bool forceLocalhost = bool.fromEnvironment(
    'FORCE_LOCALHOST',
    defaultValue: false,
  );

  /// 【脚手架阶段开关】**后端联调时请改成 false！**
  ///
  /// 为 true 时：
  /// - 登录页不会真的调后端，点「登录」直接建立一个本地模拟会话；
  /// - 方便后端还没写好时先把 13 个页面全部点一遍、验证路由。
  ///
  /// 为 false 时：走真实 `/api/auth/login` 接口。
  /// 也可以在运行时覆盖：`flutter run --dart-define=BYPASS_LOGIN=false`
  static const bool bypassLogin = bool.fromEnvironment(
    'BYPASS_LOGIN',
    defaultValue: true,
  );

  /// 是否使用本地 Mock 数据（首页 Skill 线路、作品、消息等）。
  ///
  /// **当前为 false：业务数据已全部切到后端真实接口。**
  ///
  /// 为 true 时 Repository 不发网络请求，直接返回 `MockData` 里的假数据，
  /// 保证后端没起来时前端页面也能完整开发、演示、跑测试。
  /// 为 false 时走真实的 `/api/skills`、`/api/works`、`/api/tasks` 等接口。
  ///
  /// 注意它和 [bypassLogin] **不需要同步改**，现在就是
  /// `bypassLogin = true` + `useMockData = false` 的组合：
  /// 登录仍走本地模拟会话（不调 `/api/auth/login`），
  /// 但业务数据全部来自真实后端。
  ///
  /// 这个组合能跑通，是因为 AuthProvider 在 bypassLogin 模式下发出的
  /// 固定令牌与后端 `opc.security.dev-token` 配置一致，
  /// 会被 AuthInterceptor 直接映射成演示账号 demo。
  /// 交付前把后端的 `dev-token-enabled` 关掉，这个组合就会失效（这是预期的）。
  ///
  /// 覆盖方式：`flutter run --dart-define=USE_MOCK_DATA=true`（临时切回 Mock）
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  /// 线上域名，切到 [AppEnv.production] 时生效。
  static const String productionBaseUrl = String.fromEnvironment(
    'PROD_BASE_URL',
    defaultValue: 'https://api.opc-ai-creator.com',
  );

  /// 当前运行环境。--dart-define=APP_ENV=webDev / androidDevice / production
  static AppEnv get env {
    const raw = String.fromEnvironment('APP_ENV', defaultValue: '');
    switch (raw) {
      case 'webDev':
        return AppEnv.webDev;
      case 'androidDevice':
        return AppEnv.androidDevice;
      case 'production':
        return AppEnv.production;
      default:
        // 未显式指定时按平台自动推断，保证「一套代码」开箱即用。
        return autoDetectedEnv;
    }
  }

  /// 根据编译目标自动推断环境。
  static AppEnv get autoDetectedEnv {
    if (kIsWeb) return AppEnv.webDev;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AppEnv.androidDevice;
    }
    return AppEnv.webDev;
  }

  // ---------------------------------------------------------------------------
  // 派生配置
  // ---------------------------------------------------------------------------

  /// 后端根地址（不含 /api 前缀）。
  static String get host {
    switch (env) {
      case AppEnv.production:
        return productionBaseUrl;
      case AppEnv.androidDevice:
        return forceLocalhost ? 'http://localhost:$serverPort' : 'http://$lanHost:$serverPort';
      case AppEnv.webDev:
        return 'http://localhost:$serverPort';
    }
  }

  /// 所有 RESTful 接口的基础地址，[ApiClient] 使用它作为 Dio 的 baseUrl。
  static String get baseUrl => '$host${ApiEndpoints.apiPrefix}';

  /// 静态资源（上传的图片 / 生成的视频）根地址。
  ///
  /// 后端返回的往往是 `/upload/xxx.png` 这种相对路径，
  /// 用 [resolveAssetUrl] 拼成完整地址再交给 Image.network。
  static String get assetBaseUrl => host;

  /// 把后端返回的相对资源路径补全成可直接加载的 URL。
  static String resolveAssetUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '$assetBaseUrl$path';
    return '$assetBaseUrl/$path';
  }

  /// 当前是否处于调试期（控制日志、假数据等）。
  static bool get isDebug => kDebugMode;

  /// 网络请求超时时间。
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Harness 任务轮询间隔：前端主动拉取任务状态用。
  static const Duration taskPollInterval = Duration(seconds: 3);

  /// 环境描述，显示在「设置页」方便调试时确认连的是哪个后端。
  static String get envLabel {
    switch (env) {
      case AppEnv.production:
        return '生产环境';
      case AppEnv.androidDevice:
        return 'Android 真机';
      case AppEnv.webDev:
        return 'Web 调试';
    }
  }
}

/// 接口路径常量，集中管理避免散落在各处。
class ApiEndpoints {
  const ApiEndpoints._();

  /// 统一前缀，与后端 `server.servlet.context-path` 对应。
  static const String apiPrefix = '/api';

  // --- 认证 ---
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // --- AI 任务（Harness 调度） ---
  static const String tasks = '/tasks';
  static String taskDetail(int id) => '/tasks/$id';
  static String taskRetry(int id) => '/tasks/$id/retry';
  static String taskCancel(int id) => '/tasks/$id/cancel';

  /// 各状态任务数量，个人中心的数据统计用它。
  /// 返回 `Map<状态名, 数量>`，例如 `{"SUCCESS": 12, "FAILED": 2}`。
  static const String taskStats = '/tasks/stats';

  // --- 创作 ---
  static const String textToImage = '/creation/text-to-image';
  static const String imageToVideo = '/creation/image-to-video';

  // --- 素材库 ---
  static const String materials = '/materials';
  static String materialDetail(int id) => '/materials/$id';
  static const String materialUpload = '/materials/upload';

  /// 我上传的素材（分页）。后端返回 `Result<Page<MaterialResponse>>`，
  /// 素材在 `data.content` 里。
  static const String materialMine = '/materials/my';

  // --- Prompt 知识库 ---
  static const String prompts = '/prompts';
  static String promptFavorite(int id) => '/prompts/$id/favorite';

  // --- Skill 线路 ---
  static const String skills = '/skills';
  static String skillDetail(int id) => '/skills/$id';

  // --- 作品 ---
  static const String works = '/works';
  static String workDetail(int id) => '/works/$id';
  static String workPublish(int id) => '/works/$id/publish';
}
