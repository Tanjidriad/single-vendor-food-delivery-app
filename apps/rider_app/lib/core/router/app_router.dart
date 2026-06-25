import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/earnings/presentation/screens/cash_summary_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/orders/data/order_summary.dart';
import '../../features/orders/presentation/screens/active_delivery_screen.dart';
import '../../features/orders/presentation/screens/current_orders_screen.dart';
import '../../features/orders/presentation/screens/delivered_order_detail_screen.dart';
import '../../features/orders/presentation/screens/history_screen.dart';
import '../../features/orders/presentation/screens/incoming_order_screen.dart';
import '../../features/performance/presentation/screens/performance_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/help_center_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shift/presentation/screens/home_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'home_shell.dart';
import 'route_paths.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isPublic =
          loc == RoutePaths.splash ||
          loc == RoutePaths.login ||
          loc == RoutePaths.forgotPassword ||
          loc.startsWith(RoutePaths.resetPassword) ||
          loc.startsWith(RoutePaths.onboarding);

      if (loc == RoutePaths.splash) return null;

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
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
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
      GoRoute(
        path: RoutePaths.performance,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const PerformanceScreen(),
      ),
      GoRoute(
        path: RoutePaths.cash,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const CashSummaryScreen(),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.profileEdit,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.help,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: RoutePaths.deliveredDetail,
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is OrderSummary) {
            return DeliveredOrderDetailScreen(order: extra);
          }
          final orderId = state.pathParameters['orderId'] ?? '';
          return DeliveredOrderDetailLoader(orderId: orderId);
        },
      ),

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
