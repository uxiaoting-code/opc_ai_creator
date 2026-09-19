import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:opc_ai_creator/app.dart';
import 'package:opc_ai_creator/core/network/api_client.dart';
import 'package:opc_ai_creator/core/router/route_names.dart';
import 'package:opc_ai_creator/data/datasources/mock_data.dart';
import 'package:opc_ai_creator/data/repositories/material_repository.dart';
import 'package:opc_ai_creator/data/repositories/notification_repository.dart';
import 'package:opc_ai_creator/data/repositories/skill_repository.dart';
import 'package:opc_ai_creator/data/repositories/task_repository.dart';
import 'package:opc_ai_creator/data/repositories/work_repository.dart';
import 'package:opc_ai_creator/providers/auth_provider.dart';
import 'package:opc_ai_creator/providers/notification_provider.dart';
import 'package:opc_ai_creator/providers/skill_provider.dart';
import 'package:opc_ai_creator/providers/theme_provider.dart';
import 'package:opc_ai_creator/providers/work_provider.dart';

/// 构造一棵完整的 App 组件树。
///
/// [loggedIn] 为 true 时会先恢复登录态（脚手架模式下即建立本地模拟会话），
/// 这样路由守卫才会放行到首页；为 false 则停在登录页。
///
/// ⚠️ **这些测试必须带 `--dart-define=USE_MOCK_DATA=true` 运行**：
/// ```bash
/// flutter test --dart-define=USE_MOCK_DATA=true
/// ```
/// 因为 `AppConfig.useMockData` 的默认值已经改成 `false`（联调真实后端），
/// 而测试环境里没有后端 —— flutter_test 会把所有 HTTP 请求拦成 400，
/// 于是首页拿不到线路和作品，下面那些断言 Mock 数据的用例会全部失败。
/// 带上这个 flag 就临时切回 MockData，测试重新变成纯粹的 UI 回归测试。
Future<Widget> buildApp({bool loggedIn = false}) async {
  final apiClient = ApiClient(onUnauthorized: () {});
  final authProvider = AuthProvider(apiClient: apiClient);

  if (loggedIn) {
    await authProvider.restoreSession();
  }

  return OpcApp(
    apiClient: apiClient,
    authProvider: authProvider,
    themeProvider: ThemeProvider(),
    skillProvider: SkillProvider(repository: SkillRepository(apiClient)),
    workProvider: WorkProvider(repository: WorkRepository(apiClient)),
    notificationProvider: NotificationProvider(
      repository: NotificationRepository(apiClient),
    ),
    taskRepository: TaskRepository(apiClient),
    materialRepository: MaterialRepository(apiClient),
  );
}

/// 等待首页数据加载完成。
///
/// ⚠️ 这里不能只写 `await tester.pumpAndSettle()`：
/// pumpAndSettle 只在「还有帧排队」时才推进时钟，加载态一旦静止它立刻就返回了，
/// 于是 `Future.delayed(320ms)` 的定时器根本不会触发，测试会断言在骨架屏上。
/// 必须显式把时钟往前拨过 Mock 的模拟延迟。
Future<void> pumpHomeLoaded(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(MockData.latency + const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

/// 把测试窗口设成一块够高的手机竖屏。
///
/// ListView 是**懒加载**的，默认 800×600 的测试窗口只会构建视口内的区块，
/// 首页下半部分（更多功能 / 最近作品）压根不会被创建，断言自然找不到。
/// 这里把逻辑尺寸调高，保证首页所有区块都进入构建范围。
void useTallPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    // Provider 会读写 SharedPreferences，测试里给个假实现
    SharedPreferences.setMockInitialValues({});
  });

  // ===========================================================================
  // 路由表
  // ===========================================================================
  group('路由表', () {
    test('13 个业务页面全部登记，且路径不重复', () {
      expect(
        RouteNames.allBusinessPaths.length,
        RouteNames.requiredPageCount,
        reason: '课程设计要求至少 13 个业务页面',
      );
      expect(
        RouteNames.allBusinessPaths.toSet().length,
        RouteNames.requiredPageCount,
        reason: '存在重复的路由路径',
      );
    });

    test('带参数路由能正确拼接', () {
      expect(RouteNames.taskDetailOf(42), '/tasks/42');
      expect(RouteNames.workDetailOf(7), '/gallery/7');
      expect(RouteNames.textToImageWithSkill(3), '/create/text-to-image?skillId=3');
    });
  });

  // ===========================================================================
  // 登录守卫
  // ===========================================================================
  group('登录守卫', () {
    testWidgets('未登录时打开首页会被重定向到登录页', (tester) async {
      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      // 初始地址是 /home，被 redirect 拦到 /login
      expect(find.text('OPC AI 创作平台'), findsOneWidget);
      expect(find.text('登 录'), findsOneWidget);
      expect(find.text('注册'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 首页
  // ===========================================================================
  group('首页', () {
    testWidgets('登录后展示顶部栏、Skill 线路、创作入口、功能入口与最近作品',
        (tester) async {
      useTallPhoneViewport(tester);
      await tester.pumpWidget(await buildApp(loggedIn: true));
      await pumpHomeLoaded(tester);

      // --- 需求 1：顶部栏 ---
      expect(find.textContaining('你好，'), findsOneWidget);
      expect(find.text('搜索提示词、创作线路'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

      // --- 需求 2：Skill 线路（Mock 数据里的线路名） ---
      expect(find.text('创作线路'), findsOneWidget);
      expect(find.text('二次元插画'), findsOneWidget);
      expect(find.text('写实摄影'), findsOneWidget);
      expect(find.text('电商海报'), findsOneWidget);

      // --- 需求 3：两大创作入口 ---
      expect(find.text('开始创作'), findsOneWidget);
      expect(find.text('文生图'), findsWidgets);
      expect(find.text('图生视频'), findsWidgets);

      // --- 需求 4：功能入口 ---
      expect(find.text('更多功能'), findsOneWidget);
      expect(find.text('Prompt 知识库'), findsOneWidget);
      expect(find.text('Skill 市场'), findsOneWidget);

      // --- 需求 5：最近作品 ---
      expect(find.text('最近作品'), findsOneWidget);
      expect(find.text('赛博朋克少女'), findsOneWidget);
    });

    testWidgets('点击 Skill 线路卡片会带着 skillId 进入文生图创作页', (tester) async {
      useTallPhoneViewport(tester);
      await tester.pumpWidget(await buildApp(loggedIn: true));
      await pumpHomeLoaded(tester);

      // Mock 数据里 id=1 是「二次元插画」，类型为文生图
      await tester.tap(find.text('二次元插画'));
      await tester.pumpAndSettle();

      // 应该跳到真实的文生图创作页（不再是脚手架占位页）
      expect(find.text('文生图创作'), findsOneWidget);
      expect(find.text('开始生成'), findsOneWidget);

      // skillId=1 预选成功的证据：线路参数预览只在「选中了某条线路」时才渲染，
      // 而「自动前缀」来自 anime_v1 的 promptPrefix。
      // 比断言路由字符串更能反映真实行为 —— 预选失败时这块根本不会出现。
      expect(find.textContaining('自动前缀'), findsOneWidget);
    });

    testWidgets('点击「图生视频」创作入口进入图生视频页', (tester) async {
      useTallPhoneViewport(tester);
      await tester.pumpWidget(await buildApp(loggedIn: true));
      await pumpHomeLoaded(tester);

      // 创作入口卡片上的标题（区别于 Skill 卡片的类型角标）
      await tester.tap(find.text('让静态图片动起来'));
      await tester.pumpAndSettle();

      expect(find.text('图生视频创作'), findsOneWidget);
    });

    testWidgets('在 360×800 的小屏手机上不出现布局溢出', (tester) async {
      // 360×800 是典型的安卓窄屏机型（约等于 720×1600 实机）
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(await buildApp(loggedIn: true));
      await pumpHomeLoaded(tester);

      // RenderFlex overflow 会被测试框架记成异常，
      // 这里显式断言没有异常，等于给首页布局加了一道小屏回归防线。
      expect(tester.takeException(), isNull);
    });

    testWidgets('顶部消息入口能打开消息弹层', (tester) async {
      useTallPhoneViewport(tester);
      await tester.pumpWidget(await buildApp(loggedIn: true));
      await pumpHomeLoaded(tester);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      // 弹层里的 Mock 消息
      expect(find.text('消息'), findsOneWidget);
      expect(find.text('生成成功'), findsOneWidget);
      expect(find.text('全部已读'), findsOneWidget);
    });
  });
}
