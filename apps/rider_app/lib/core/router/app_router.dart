import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/orders/presentation/screens/active_delivery_screen.dart';
import '../../features/orders/presentation/screens/current_orders_screen.dart';
import '../../features/orders/presentation/screens/history_screen.dart';
import '../../features/orders/presentation/screens/incoming_order_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shift/presentation/screens/home_screen.dart';
import 'home_shell.dart';
import 'route_paths.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: RoutePaths.login,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Auth/onboarding routes live outside the shell and are reachable while
      // unauthenticated.
      final isPublic =
          loc == RoutePaths.login ||
          loc == RoutePaths.forgotPassword ||
          loc.startsWith(RoutePaths.resetPassword) ||
          loc.startsWith(RoutePaths.onboarding);

      if (!isAuthenticated && !isPublic) {
        return RoutePaths.login;
      }
      if (isAuthenticated && loc == RoutePaths.login) {
        return RoutePaths.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Full-screen flows pushed over everything (root navigator) so they
      // cover the bottom-nav shell.
      GoRoute(
        path: RoutePaths.incomingOrder,
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final assignmentData = state.extra as Map<String, dynamic>?;
          return IncomingOrderScreen(assignmentData: assignmentData);
        },
      ),
      GoRoute(
        path: RoutePaths.activeDelivery,
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final orderData = state.extra as Map<String, dynamic>?;
          return ActiveDeliveryScreen(orderData: orderData);
        },
      ),

      // The bottom-nav shell: five top-level branches, each with its own
      // navigator stack so per-tab back behavior is preserved.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.earnings,
                builder: (context, state) => const EarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.orders,
                builder: (context, state) => const CurrentOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
