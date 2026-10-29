import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'pages/creation_pages.dart';
import 'pages/login_page.dart';
import 'pages/main_shell_page.dart';
import 'pages/order_detail_page.dart';
import 'pages/order_market_page.dart';
import 'pages/profile_page.dart';
import 'pages/recharge_pages.dart';
import 'pages/review_status_page.dart';
import 'pages/submission_page.dart';
import 'pages/submissions_page.dart';
import 'pages/work_detail_page.dart';
import 'pages/workbench_page.dart';
import 'pages/withdraw_pages.dart';

class CreatorRouter {
  CreatorRouter(this._auth);

  final AuthProvider _auth;

  static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'creator-root');
  static final _marketKey = GlobalKey<NavigatorState>(
    debugLabel: 'creator-market',
  );
  static final _workbenchKey = GlobalKey<NavigatorState>(
    debugLabel: 'creator-workbench',
  );
  static final _submissionsKey = GlobalKey<NavigatorState>(
    debugLabel: 'creator-submissions',
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
      if (loggedIn && loggingIn) return '/market';
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
            navigatorKey: _workbenchKey,
            routes: [
              GoRoute(
                path: '/workbench',
                builder: (context, state) => const WorkbenchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _submissionsKey,
            routes: [
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
        path: '/create/image',
        builder: (context, state) => const CreateImagePage(),
      ),
      GoRoute(
        path: '/create/video',
        builder: (context, state) => const CreateVideoPage(),
      ),
      GoRoute(
        path: '/create/audio',
        builder: (context, state) => const CreateAudioPage(),
      ),
      GoRoute(
        path: '/submission',
        builder: (context, state) => const SubmissionPage(),
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
              onPressed: () => context.go('/market'),
              child: const Text('返回接单大厅'),
            ),
          ],
        ),
      ),
    );
  }
}
