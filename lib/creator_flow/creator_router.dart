import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../data/models/task_model.dart';
import 'models/creator_order.dart';
import 'pages/course_center_page.dart';
import 'pages/create_home_page.dart';
import 'pages/creator_works_page.dart';
import 'pages/creation_pages.dart';
import 'pages/login_page.dart';
import 'pages/main_shell_page.dart';
import 'pages/order_detail_page.dart';
import 'pages/order_market_page.dart';
import 'pages/profile_page.dart';
import 'pages/recharge_pages.dart';
import 'pages/result_page.dart';
import 'pages/review_status_page.dart';
import 'pages/submission_page.dart';
import 'pages/submissions_page.dart';
import 'pages/work_detail_page.dart';
import 'pages/workbench_page.dart';
import 'pages/withdraw_pages.dart';

CreatorCreationArgs _creationArgs(Object? extra) {
  if (extra is CreatorCreationArgs) return extra;
  if (extra is String) return CreatorCreationArgs(prompt: extra);
  return const CreatorCreationArgs();
}

class CreatorRouter {
  CreatorRouter(this._auth);

  final AuthProvider _auth;

  static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'creator-root');
  static final _courseKey = GlobalKey<NavigatorState>(
    debugLabel: 'creator-course',
  );
  static final _createKey = GlobalKey<NavigatorState>(
    debugLabel: 'creator-create',
  );
  static final _marketKey = GlobalKey<NavigatorState>(
    debugLabel: 'creator-market',
  );
  static final _profileKey = GlobalKey<NavigatorState>(
    debugLabel: 'creator-profile',
  );

  late final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    refreshListenable: _auth,
    redirect: (context, state) {
      final loggedIn = _auth.isLoggedIn;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/course';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const CreatorLoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CreatorMainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _courseKey,
            routes: [
              GoRoute(
                path: '/course',
                builder: (context, state) => const CourseCenterPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _createKey,
            routes: [
              GoRoute(
                path: '/create',
                builder: (context, state) => const CreateHomePage(),
                routes: [
                  GoRoute(
                    path: 'image',
                    builder: (context, state) {
                      final args = _creationArgs(state.extra);
                      return CreateImagePage(
                        initialPrompt: args.prompt,
                        orderId: args.orderId,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'video',
                    builder: (context, state) {
                      final args = _creationArgs(state.extra);
                      return CreateVideoPage(
                        initialPrompt: args.prompt,
                        orderId: args.orderId,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'audio',
                    builder: (context, state) {
                      final args = _creationArgs(state.extra);
                      return CreateAudioPage(
                        initialPrompt: args.prompt,
                        orderId: args.orderId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _marketKey,
            routes: [
              GoRoute(
                path: '/market',
                builder: (context, state) => const OrderMarketPage(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => OrderDetailPage(
                      orderId: state.pathParameters['orderId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const CreatorProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/workbench',
        builder: (context, state) => const WorkbenchPage(),
      ),
      GoRoute(
        path: '/submissions',
        builder: (context, state) => const SubmissionsPage(),
        routes: [
          GoRoute(
            path: ':submissionId',
            builder: (context, state) => WorkDetailPage(
              submissionId: state.pathParameters['submissionId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/submission',
        builder: (context, state) => SubmissionPage(
          initialTask: state.extra is TaskModel ? state.extra as TaskModel : null,
        ),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => ResultPage(
          initialTask: state.extra is TaskModel ? state.extra as TaskModel : null,
        ),
      ),
      GoRoute(
        path: '/works',
        builder: (context, state) => const CreatorWorksPage(),
      ),
      GoRoute(
        path: '/review/:submissionId',
        builder: (context, state) => ReviewStatusPage(
          submissionId: state.pathParameters['submissionId']!,
        ),
      ),
      GoRoute(
        path: '/recharge',
        builder: (context, state) => const RechargePage(),
      ),
      GoRoute(
        path: '/recharge/channel',
        builder: (context, state) {
          final amount =
              double.tryParse(state.uri.queryParameters['amount'] ?? '') ?? 0;
          return RechargeChannelPage(amount: amount);
        },
      ),
      GoRoute(
        path: '/withdraw',
        builder: (context, state) => const WithdrawPage(),
      ),
      GoRoute(
        path: '/withdraw/channel',
        builder: (context, state) {
          final amount =
              double.tryParse(state.uri.queryParameters['amount'] ?? '') ?? 0;
          return WithdrawChannelPage(amount: amount);
        },
      ),
    ],
    errorBuilder: (context, state) =>
        _NotFoundPage(location: state.uri.toString()),
  );
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wrong_location_outlined,
              size: 54,
              color: AppColors.statusFailed,
            ),
            const SizedBox(height: 12),
            Text(location, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.go('/course'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
