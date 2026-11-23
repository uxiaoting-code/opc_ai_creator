import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:opc_ai_creator/app.dart';
import 'package:opc_ai_creator/core/network/api_client.dart';
import 'package:opc_ai_creator/core/network/api_response.dart';
import 'package:opc_ai_creator/creator_flow/creator_wallet_provider.dart';
import 'package:opc_ai_creator/creator_flow/data/creator_wallet_repository.dart';
import 'package:opc_ai_creator/creator_flow/models/creator_wallet.dart';
import 'package:opc_ai_creator/creator_flow/pages/profile_page.dart';
import 'package:opc_ai_creator/data/models/skill_model.dart';
import 'package:opc_ai_creator/data/repositories/material_repository.dart';
import 'package:opc_ai_creator/data/repositories/notification_repository.dart';
import 'package:opc_ai_creator/data/repositories/prompt_repository.dart';
import 'package:opc_ai_creator/data/repositories/skill_repository.dart';
import 'package:opc_ai_creator/data/repositories/task_repository.dart';
import 'package:opc_ai_creator/data/repositories/work_repository.dart';
import 'package:opc_ai_creator/providers/auth_provider.dart';
import 'package:opc_ai_creator/providers/notification_provider.dart';
import 'package:opc_ai_creator/providers/skill_provider.dart';
import 'package:opc_ai_creator/providers/theme_provider.dart';
import 'package:opc_ai_creator/providers/work_provider.dart';

class _FakeSkillRepository extends SkillRepository {
  _FakeSkillRepository() : super(ApiClient(onUnauthorized: () {}));

  static const _skills = [
    SkillModel(
      id: 1,
      code: 'anime_v1',
      name: '二次元插画',
      type: SkillType.textToImage,
      scene: '头像 / 立绘',
      provider: 'mock',
      modelName: 'sd-xl-anime',
      width: 1024,
      height: 1024,
    ),
    SkillModel(
      id: 2,
      code: 'ecommerce_v1',
      name: '电商海报',
      type: SkillType.textToImage,
      scene: '商品主图',
      provider: 'mock',
      modelName: 'sd-xl-product',
      width: 1024,
      height: 1024,
    ),
    SkillModel(
      id: 5,
      code: 'motion_v1',
      name: '短视频运镜',
      type: SkillType.imageToVideo,
      scene: '产品展示',
      provider: 'mock',
      modelName: 'svd-xt',
      width: 1024,
      height: 576,
    ),
  ];

  @override
  Future<List<SkillModel>> fetchSkills({SkillType? type, int? limit}) async {
    var result = type == null
        ? List<SkillModel>.from(_skills)
        : _skills.where((skill) => skill.type == type).toList();
    if (limit != null) result = result.take(limit).toList();
    return result;
  }
}

class _FakeWalletRepository extends CreatorWalletRepository {
  _FakeWalletRepository() : super(ApiClient(onUnauthorized: () {}));

  @override
  Future<CreatorProfileStats> fetchProfileStats() async {
    return const CreatorProfileStats(
      credits: 1286,
      withdrawableFen: 36800,
      frozenFen: 10000,
      totalIncomeFen: 68000,
      totalWithdrawnFen: 12000,
      pendingReviewCount: 1,
      approvedReviewCount: 3,
      rejectedReviewCount: 0,
      taskStats: {'SUCCESS': 8, 'RUNNING': 1},
    );
  }

  @override
  Future<PageResult<CreatorWalletTransaction>> fetchTransactions({
    int page = 1,
    int pageSize = 10,
  }) async {
    return PageResult(
      list: [
        CreatorWalletTransaction.fromJson({
          'id': 1,
          'transactionNo': 'WT1',
          'type': 'WITHDRAW_FREEZE',
          'amountFen': 10000,
          'balanceAfterFen': 36800,
          'description': '提现冻结 · 支付宝',
          'createdAt': '2026-11-23T10:00:00',
        }),
      ],
      page: 1,
      pageSize: pageSize,
      total: 1,
    );
  }
}

Future<Widget> buildApp({bool loggedIn = false}) async {
  final apiClient = ApiClient(onUnauthorized: () {});
  final authProvider = AuthProvider(apiClient: apiClient);
  if (loggedIn) {
    final error = await authProvider.login(
      username: 'demo',
      password: 'demo123',
    );
    expect(error, isNull);
  }

  return OpcApp(
    apiClient: apiClient,
    authProvider: authProvider,
    themeProvider: ThemeProvider(),
    skillProvider: SkillProvider(repository: _FakeSkillRepository()),
    workProvider: WorkProvider(repository: WorkRepository(apiClient)),
    notificationProvider: NotificationProvider(
      repository: NotificationRepository(apiClient),
    ),
    taskRepository: TaskRepository(apiClient),
    materialRepository: MaterialRepository(apiClient),
    promptRepository: PromptRepository(apiClient),
  );
}

void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('钱包金额与模型', () {
    test('元金额严格转换为整数分', () {
      expect(parseYuanToFen('10'), 1000);
      expect(parseYuanToFen('10.5'), 1050);
      expect(parseYuanToFen('10.05'), 1005);
      expect(parseYuanToFen('0.01'), 1);
      expect(parseYuanToFen('-1'), isNull);
      expect(parseYuanToFen('1.001'), isNull);
      expect(parseYuanToFen('1e3'), isNull);
    });

    test('分金额格式化不经过浮点数', () {
      expect(formatFen(0), '0.00');
      expect(formatFen(1005), '10.05');
      expect(formatFen(-120), '-1.20');
    });

    test('提现流水按资金离开方向展示', () {
      final freeze = CreatorWalletTransaction.fromJson({
        'id': 1,
        'transactionNo': 'WT1',
        'type': 'WITHDRAW_FREEZE',
        'amountFen': 10000,
        'balanceAfterFen': 26800,
      });
      final income = CreatorWalletTransaction.fromJson({
        'id': 2,
        'transactionNo': 'WT2',
        'type': 'ORDER_INCOME',
        'amountFen': 6800,
        'balanceAfterFen': 36800,
      });

      expect(freeze.displayDeltaFen, -10000);
      expect(income.displayDeltaFen, 6800);
    });

    test('个人统计接口字段保持后端口径', () {
      final stats = CreatorProfileStats.fromJson({
        'credits': 1286,
        'withdrawableFen': 36800,
        'frozenFen': 10000,
        'totalIncomeFen': 68000,
        'totalWithdrawnFen': 12000,
        'pendingReviewCount': 1,
        'approvedReviewCount': 3,
        'rejectedReviewCount': 0,
        'taskStats': {'SUCCESS': 8, 'RUNNING': 1},
      });

      expect(stats.credits, 1286);
      expect(stats.withdrawableFen, 36800);
      expect(stats.pendingReviewCount, 1);
      expect(stats.taskStats['SUCCESS'], 8);
    });
  });

  group('登录态', () {
    test('脚手架模式登录会持久化令牌和用户', () async {
      final auth = AuthProvider(apiClient: ApiClient(onUnauthorized: () {}));

      final error = await auth.login(username: 'demo', password: 'demo123');
      expect(error, isNull);
      expect(auth.isLoggedIn, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'mock-token-for-scaffold');
      expect(prefs.getInt('auth_user_id'), 1);
    });
  });

  group('用户端页面', () {
    testWidgets('个人中心展示真实钱包与统一统计', (tester) async {
      usePhoneViewport(tester);
      final apiClient = ApiClient(onUnauthorized: () {});
      final auth = AuthProvider(apiClient: apiClient);
      await auth.login(username: 'demo', password: 'demo123');
      final wallet = CreatorWalletProvider(_FakeWalletRepository(), auth: auth);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<CreatorWalletProvider>.value(value: wallet),
          ],
          child: const MaterialApp(home: CreatorProfilePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¥ 368.00'), findsOneWidget);
      expect(find.text('1286'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.text('提现冻结 · 支付宝'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('未登录启动时显示登录注册页', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      expect(find.text('欢迎回来'), findsOneWidget);
      expect(find.text('注册'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '登录'), findsOneWidget);
    });

    testWidgets('演示账号可以登录并进入课程中心首页', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '登录'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('课程中心'), findsOneWidget);
      expect(find.text('课程'), findsOneWidget);
      expect(find.text('创作'), findsOneWidget);
      expect(find.text('接单'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);

      await tester.tap(find.text('接单'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('接单大厅'), findsOneWidget);
    });

    testWidgets('登录后可以进入接单大厅', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(await buildApp(loggedIn: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('接单'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('接单大厅'), findsOneWidget);
    });

    testWidgets('创作首页可以打开文生图页面且小屏幕不溢出', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(await buildApp(loggedIn: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('创作'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('✦  开始生成').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('文生图'), findsWidgets);
      expect(find.textContaining('预计消耗 12 算力'), findsOneWidget);
      expect(find.text('二次元插画'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
