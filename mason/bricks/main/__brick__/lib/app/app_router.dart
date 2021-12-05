import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import '../shared/guards/check_auth_guard.dart';
import '../shared/guards/check_connectivity_guard.dart';
import '../ui/decision/decision_view.dart';
import '../ui/home/home_view.dart';

import '../ui/shared/notConnected/not_connected_view.dart';
import 'app_router.gr.dart';

final appRouter = AppRouter(
  checkAuthGuard: CheckAuthGuard(),
  checkConnectivityGuard: CheckConnectivityGuard(),
);

@AdaptiveAutoRouter(routes: <AutoRoute>[
  AutoRoute(
    page: HomeView,
    guards: [CheckAuthGuard],
    initial: true,
  ),
  AutoRoute(
    page: DecisionView,
    guards: [CheckConnectivityGuard],
  ),
  AutoRoute(page: NotConnectedView),
])
class $AppRouter {}
