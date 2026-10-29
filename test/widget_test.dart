import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:opc_ai_creator/app.dart';
import 'package:opc_ai_creator/core/network/api_client.dart';
import 'package:opc_ai_creator/creator_flow/creator_flow_provider.dart';
import 'package:opc_ai_creator/creator_flow/models/creator_models.dart';
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
    skillProvider: SkillProvider(repository: SkillRepository(apiClient)),
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

  group('CreatorFlowProvider', () {
    test('接单、生成、提交、审核和提现形成完整闭环', () {
      final flow = CreatorFlowProvider();
      final beforeWithdrawable = flow.withdrawable;

      flow.acceptOrder('o-1001');
      expect(flow.currentOrder?.id, 'o-1001');

      final created = flow.createDraft(
        mode: CreationMode.image,
        prompt: '香水产品主图，奶油色背景',
        model: 'GPT-4o Image',
      );
      expect(created, isTrue);
      expect(flow.draft, isNotNull);

      final submission = flow.submitDraft(
        title: '香水主图最终稿',
        note: '已经按要求完成四张主图',
      );
      expect(submission, isNotNull);
      expect(submission!.status, ReviewStatus.pending);
      expect(flow.pendingReviewCount, greaterThanOrEqualTo(1));

      flow.reviewSubmission(submission.id, approved: true);
      final approved = flow.submissionById(submission.id)!;
      expect(approved.status, ReviewStatus.approved);
      expect(flow.withdrawable, closeTo(beforeWithdrawable + 68, 0.001));

      final withdrawn = flow.withdraw(amount: 100, channel: '支付宝');
      expect(withdrawn, isTrue);
      expect(flow.withdrawable, closeTo(beforeWithdrawable + 68 - 100, 0.001));
    });
  });

  group('用户端页面', () {
    testWidgets('未登录启动时显示登录注册页', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      expect(find.text('欢迎回来'), findsOneWidget);
      expect(find.text('注册'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '登录'), findsOneWidget);
    });

    testWidgets('演示账号可以登录并进入接单大厅', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(await buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '登录'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('接单大厅'), findsOneWidget);
      expect(find.text('春季香水商品主图套组'), findsOneWidget);
      expect(find.text('接单'), findsOneWidget);
      expect(find.text('工作台'), findsOneWidget);
      expect(find.text('审核'), findsOneWidget);
      expect(find.text('我的'), findsOneWidget);
    });

    testWidgets('登录后可以查看订单并接单进入工作台', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(await buildApp(loggedIn: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('春季香水商品主图套组').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('订单要求'), findsOneWidget);
      expect(find.text('立即接单'), findsOneWidget);

      await tester.tap(find.text('立即接单'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('创作工作台'), findsOneWidget);
      expect(find.text('图片生成'), findsOneWidget);
      expect(find.text('视频生成'), findsOneWidget);
      expect(find.text('音频生成'), findsOneWidget);
    });

    testWidgets('工作台能打开文生图页面且小屏幕不溢出', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(await buildApp(loggedIn: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('春季香水商品主图套组').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('立即接单'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('图片生成'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('文生图'), findsOneWidget);
      expect(find.textContaining('预计消耗 12 算力'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
