import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/material_repository.dart';
import 'data/repositories/task_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/work_provider.dart';
import 'widgets/mobile_viewport.dart';

/// 应用根组件。
///
/// 依赖在 [main] 里创建好再注入（而不是在这里 new），原因是：
/// [AuthProvider] 与 [ApiClient] 互相依赖 —— ApiClient 要在 401 时回调
/// AuthProvider，AuthProvider 又要用 ApiClient 发请求。
/// 在 main 里用 late 变量可以干净地解开这个环。
class OpcApp extends StatefulWidget {
  const OpcApp({
    super.key,
    required this.apiClient,
    required this.authProvider,
    required this.themeProvider,
    required this.skillProvider,
    required this.workProvider,
    required this.notificationProvider,
    required this.taskRepository,
    required this.materialRepository,
  });

  final ApiClient apiClient;
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;
  final SkillProvider skillProvider;
  final WorkProvider workProvider;
  final NotificationProvider notificationProvider;

  /// 任务仓库。没有配套的 ChangeNotifier Provider ——
  /// 任务状态是「每个页面各自轮询一份」，不跨页共享，
  /// 所以只注入仓库本身，轮询生命周期由 TaskDetailPage 的 State 管。
  final TaskRepository taskRepository;

  /// 素材仓库。同样没有 Provider —— 只有「图生视频创作页」在提交那一刻用一次，
  /// 没有跨页共享的状态。
  final MaterialRepository materialRepository;

  @override
  State<OpcApp> createState() => _OpcAppState();
}

class _OpcAppState extends State<OpcApp> {
  /// 路由只创建一次，避免每次 build 都重建整个路由表。
  late final AppRouter _appRouter = AppRouter(widget.authProvider);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ApiClient 用 .value 提供：它的生命周期由 main 掌控，这里只做注入
        Provider<ApiClient>.value(value: widget.apiClient),
        ChangeNotifierProvider<AuthProvider>.value(value: widget.authProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: widget.themeProvider),
        // 业务数据 Provider：首页 / 画廊 / 消息共用，
        // 放在应用根节点保证跨 Tab 切换时数据不丢、不重复请求
        ChangeNotifierProvider<SkillProvider>.value(value: widget.skillProvider),
        ChangeNotifierProvider<WorkProvider>.value(value: widget.workProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: widget.notificationProvider,
        ),
        // 仓库层：无状态服务，用普通 Provider 注入即可
        Provider<TaskRepository>.value(value: widget.taskRepository),
        Provider<MaterialRepository>.value(value: widget.materialRepository),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'OPC AI 创作平台',
            debugShowCheckedModeBanner: false,

            // ---------- 主题 ----------
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,

            // ---------- 中文本地化 ----------
            // 不配这个的话，Material 内置控件（日期选择、下拉刷新提示等）
            // 会显示英文，课程设计答辩时很显眼。
            locale: const Locale('zh', 'CN'),
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // ---------- 路由 ----------
            routerConfig: _appRouter.router,

            // ---------- 手机竖屏视口约束 ----------
            // Web 宽屏时把整棵页面树居中收窄成手机比例，
            // Android 上宽度本来就小于阈值，这里是零开销直通。
            builder: (context, child) => MobileViewport(child: child!),
          );
        },
      ),
    );
  }
}
