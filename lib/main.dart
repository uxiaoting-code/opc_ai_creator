import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'data/repositories/material_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/skill_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/work_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/work_provider.dart';

/// 应用入口。
///
/// 启动顺序：
/// 1. 初始化 Flutter 绑定（后面要用 SharedPreferences，必须先做）；
/// 2. 解开 ApiClient ↔ AuthProvider 的循环依赖；
/// 3. 恢复上次的登录态与主题设置；
/// 4. runApp。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // 1. 解开循环依赖
  // ---------------------------------------------------------------------------
  //
  // ApiClient 需要在收到 401 时通知 AuthProvider，
  // AuthProvider 又需要 ApiClient 发请求。
  // 用 late 声明 + 闭包捕获变量，回调真正执行时 authProvider 已经赋值好了。
  late final AuthProvider authProvider;

  final apiClient = ApiClient(
    onUnauthorized: () => authProvider.handleUnauthorized(),
  );

  authProvider = AuthProvider(apiClient: apiClient);
  final themeProvider = ThemeProvider();

  // ---------------------------------------------------------------------------
  // 1.5 数据层：Repository 持有 ApiClient，Provider 持有 Repository
  // ---------------------------------------------------------------------------
  //
  // 依赖方向固定为 Provider → Repository → ApiClient，
  // 页面只认识 Provider。业务数据已切到真实接口
  // （AppConfig.useMockData = false），页面与 Provider 都不用改。
  final skillProvider = SkillProvider(
    repository: SkillRepository(apiClient),
  );
  final workProvider = WorkProvider(
    repository: WorkRepository(apiClient),
  );
  final notificationProvider = NotificationProvider(
    repository: NotificationRepository(apiClient),
  );

  // TaskRepository 是唯一没有对应 Provider 的仓库：
  // 任务的「状态」不属于全局共享数据 —— 每个任务详情页各自轮询自己那个任务，
  // 页面的 State 就是它天然的归属地。所以直接注入仓库，由页面自己管轮询生命周期。
  final taskRepository = TaskRepository(apiClient);

  // 素材仓库同理：只有图生视频创作页在提交时上传一次参考图，没有跨页状态。
  final materialRepository = MaterialRepository(apiClient);

  // ---------------------------------------------------------------------------
  // 2. 恢复本地状态
  // ---------------------------------------------------------------------------
  //
  // 放在 runApp 之前 await，避免启动瞬间闪一下登录页。
  // bypassLogin 模式下这一步是同步完成的，不会有明显等待。
  await authProvider.restoreSession();

  // ---------------------------------------------------------------------------
  // 3. 开发期提示：把当前环境打到控制台，方便确认连的是哪个后端
  // ---------------------------------------------------------------------------
  if (AppConfig.isDebug) {
    debugPrint('════════════════════════════════════════════');
    debugPrint('  OPC AI 创作平台 · 脚手架启动');
    debugPrint('  运行环境 : ${AppConfig.envLabel}');
    debugPrint('  后端地址 : ${AppConfig.baseUrl}');
    debugPrint('  登录模式 : ${AppConfig.bypassLogin ? "脚手架放行（未连后端）" : "真实接口"}');
    debugPrint('  数据来源 : ${AppConfig.useMockData ? "本地 Mock 数据" : "真实接口"}');
    debugPrint('════════════════════════════════════════════');
  }

  runApp(
    OpcApp(
      apiClient: apiClient,
      authProvider: authProvider,
      themeProvider: themeProvider,
      skillProvider: skillProvider,
      workProvider: workProvider,
      notificationProvider: notificationProvider,
      taskRepository: taskRepository,
      materialRepository: materialRepository,
    ),
  );
}
