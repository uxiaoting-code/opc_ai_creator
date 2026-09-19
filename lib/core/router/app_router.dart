import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../pages/auth/login_register_page.dart';
import '../../pages/creation/image_to_video_page.dart';
import '../../pages/creation/text_to_image_page.dart';
import '../../pages/gallery/gallery_page.dart';
import '../../pages/gallery/work_detail_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/knowledge/prompt_library_page.dart';
import '../../pages/material_gallery_page.dart';
import '../../pages/profile/profile_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/shell/main_shell.dart';
import '../../pages/skill/skill_market_page.dart';
import '../../pages/task/task_detail_page.dart';
import '../../pages/task/task_list_page.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'route_names.dart';

/// 全局路由表。
///
/// 结构分三层：
/// 1. `/login`            —— 独立顶层路由，未登录时所有跳转都会被拦到这里；
/// 2. `StatefulShellRoute`—— 底部 5 个 Tab（首页/任务/画廊/素材/我的），
///                           每个 Tab 维护自己的导航栈，切 Tab 不丢失页面状态，
///                           对应手机 App 的经典交互；
/// 3. 其余顶层路由        —— 创作页、知识库、Skill 市场、设置，全屏盖在 Tab 之上。
///
/// 为什么用 go_router 而不是 Navigator 命名路由：
/// Web 调试时地址栏会真实显示 /tasks/12，刷新页面不丢路由、浏览器前进后退可用；
/// Android 上是原生页面栈，一套代码两端行为一致。
class AppRouter {
  AppRouter(this._authProvider);

  final AuthProvider _authProvider;

  /// 未登录时唯一放行的路径。
  static const Set<String> _publicPaths = {RouteNames.loginPath};

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'home');
  static final GlobalKey<NavigatorState> _taskNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'task');
  static final GlobalKey<NavigatorState> _galleryNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'gallery');
  static final GlobalKey<NavigatorState> _materialNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'material');
  static final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'profile');

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.homePath,
    debugLogDiagnostics: true,

    // 登录状态变化时自动重新执行 redirect，
    // 比如「退出登录」后立刻被踢回登录页。
    refreshListenable: _authProvider,

    // ---------------------------------------------------------------------
    // 全局登录拦截
    // ---------------------------------------------------------------------
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = _authProvider.isLoggedIn;
      final goingToLogin = _publicPaths.contains(state.matchedLocation);

      // 没登录 → 一律去登录页
      if (!loggedIn && !goingToLogin) {
        // 记下原本想去的地址，登录成功后直接跳回去
        final redirectTo = state.matchedLocation;
        return Uri(
          path: RouteNames.loginPath,
          queryParameters: redirectTo == RouteNames.homePath
              ? null
              : {'redirect': redirectTo},
        ).toString();
      }

      // 已登录还停留在登录页 → 直接进首页
      if (loggedIn && goingToLogin) {
        return RouteNames.homePath;
      }

      return null; // 放行
    },

    routes: <RouteBase>[
      // =====================================================================
      // 页面 1：登录 / 注册
      // =====================================================================
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginRegisterPage(),
      ),

      // =====================================================================
      // 底部导航 Shell：页面 2 / 5 / 6 / 7 / 11
      // =====================================================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          // -----------------------------------------------------------------
          // 页面 2：首页（Skill 选择入口）
          // -----------------------------------------------------------------
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.homePath,
                name: RouteNames.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),

          // -----------------------------------------------------------------
          // 页面 5：我的任务列表  +  页面 13：任务详情
          // -----------------------------------------------------------------
          StatefulShellBranch(
            navigatorKey: _taskNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.taskListPath,
                name: RouteNames.taskList,
                builder: (context, state) => const TaskListPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: RouteNames.taskDetailSegment,
                    name: RouteNames.taskDetail,
                    builder: (context, state) => TaskDetailPage(
                      taskId: state.pathParameters['taskId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // -----------------------------------------------------------------
          // 页面 6：作品画廊  +  页面 10：作品详情
          // -----------------------------------------------------------------
          StatefulShellBranch(
            navigatorKey: _galleryNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.galleryPath,
                name: RouteNames.gallery,
                builder: (context, state) => const GalleryPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: RouteNames.workDetailSegment,
                    name: RouteNames.workDetail,
                    builder: (context, state) => WorkDetailPage(
                      workId: state.pathParameters['workId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // -----------------------------------------------------------------
          // 页面 7：素材库
          //
          // 与顶层路由 `/select-material` 指向**同一个页面**，
          // 区别只在进入方式：
          //   - 底部 Tab 走这里（分支根页面，没有上一页）；
          //   - 图生视频创作页用 push('/select-material')，选中素材后 pop 回传。
          // 页面内部用 Navigator.canPop() 区分这两种身份，见 MaterialGalleryPage。
          // -----------------------------------------------------------------
          StatefulShellBranch(
            navigatorKey: _materialNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.materialsPath,
                name: RouteNames.materials,
                builder: (context, state) => MaterialGalleryPage(),
              ),
            ],
          ),

          // -----------------------------------------------------------------
          // 页面 11：个人中心
          // -----------------------------------------------------------------
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: RouteNames.profilePath,
                name: RouteNames.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // =====================================================================
      // 页面 3：文生图创作
      // =====================================================================
      GoRoute(
        path: RouteNames.textToImagePath,
        name: RouteNames.textToImage,
        builder: (context, state) => TextToImagePage(
          // 从 Skill 市场/首页跳进来时可带上线路 ID
          skillId: state.uri.queryParameters['skillId'],
        ),
      ),

      // =====================================================================
      // 页面 4：图生视频创作
      // =====================================================================
      GoRoute(
        path: RouteNames.imageToVideoPath,
        name: RouteNames.imageToVideo,
        builder: (context, state) => ImageToVideoPage(
          skillId: state.uri.queryParameters['skillId'],
        ),
      ),



      // ==========【在这里插入素材选择弹窗页面路由】==========
      GoRoute(
        path: '/select-material',
        name: 'selectMaterial',
        builder: (context, state) => MaterialGalleryPage(),
      ),
      // =====================================================

      // =====================================================================
      // 页面 8：Prompt 知识库广场
      // =====================================================================
      GoRoute(
        path: RouteNames.promptsPath,
        name: RouteNames.prompts,
        builder: (context, state) => const PromptLibraryPage(),
      ),

      // =====================================================================
      // 页面 9：Skill 市场
      // =====================================================================
      GoRoute(
        path: RouteNames.skillMarketPath,
        name: RouteNames.skillMarket,
        builder: (context, state) => const SkillMarketPage(),
      ),

      // =====================================================================
      // 页面 12：设置
      // =====================================================================
      GoRoute(
        path: RouteNames.settingsPath,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],

    // 未知路径兜底
    errorBuilder: (context, state) => _RouteNotFoundPage(location: state.uri.toString()),
  );
}

/// 404 兜底页：Web 上手动改错地址栏时会出现。
class _RouteNotFoundPage extends StatelessWidget {
  const _RouteNotFoundPage({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wrong_location_outlined,
                  size: 56, color: AppColors.statusFailed),
              const SizedBox(height: 16),
              Text('找不到路由', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                location,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(RouteNames.homePath),
                child: const Text('返回首页'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
