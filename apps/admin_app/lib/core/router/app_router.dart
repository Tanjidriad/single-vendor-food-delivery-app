import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_transitions.dart';
import '../widgets/layouts/app_shell.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/orders/presentation/screens/orders_management_screen.dart';
import '../../features/orders/presentation/screens/ops_operations_screen.dart';
import '../../features/menu/presentation/screens/menu_management_screen.dart';
import '../../features/menu/presentation/screens/addons_management_screen.dart';
import '../../features/banners/presentation/screens/banners_management_screen.dart';
import '../../features/coupons/presentation/screens/coupons_management_screen.dart';
import '../../features/media/presentation/screens/media_management_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/riders/presentation/screens/riders_screen.dart';
import '../../features/zones/presentation/screens/zones_management_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggingIn = state.uri.path == '/login';
      final isInitial = authState == AuthState.initial;

      if (isInitial) {
        return null; // Wait for initialization
      }

      if (authState == AuthState.unauthenticated && !isLoggingIn) {
        return '/login';
      }

      if (authState == AuthState.authenticated && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => fadeTransition(
          key: state.pageKey,
          duration: kLoginFadeDuration,
          child: const LoginScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const OrdersManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/ops',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const OpsOperationsScreen(),
            ),
          ),
          GoRoute(
            path: '/menu',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const MenuManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/addons',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const AddonsManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/banners',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const BannersManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/coupons',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const CouponsManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/media',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const MediaManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const CustomersScreen(),
            ),
          ),
          GoRoute(
            path: '/riders',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const RidersScreen(),
            ),
          ),
          GoRoute(
            path: '/zones',
            pageBuilder: (context, state) => fadeTransition(
              key: state.pageKey,
              child: const ZonesManagementScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
