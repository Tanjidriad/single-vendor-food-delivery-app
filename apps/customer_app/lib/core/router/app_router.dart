import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../network/api_client.dart';
import 'auth_refresh_notifier.dart';
import '../../features/auth/presentation/screens/email_verify_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_success_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/menu/presentation/screens/category_screen.dart';
import '../../features/menu/presentation/screens/item_detail_screen.dart';
import '../../features/menu/presentation/screens/menu_screen.dart';
import '../../features/menu/presentation/screens/search_screen.dart';
import '../../features/offers/presentation/screens/offers_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/order_tracking_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/profile/presentation/screens/addresses_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../widgets/navigation/app_shell.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

bool _isPublicRoute(String location) {
  return location == RoutePaths.splash ||
      location == RoutePaths.onboarding ||
      location == RoutePaths.login ||
      location == RoutePaths.register ||
      location == RoutePaths.emailVerify ||
      location == RoutePaths.forgotPassword ||
      location.startsWith(RoutePaths.resetPassword);
}

bool _requiresAuth(String location) {
  const protected = {
    RoutePaths.cart,
    RoutePaths.checkout,
    RoutePaths.orders,
    RoutePaths.profile,
    RoutePaths.favorites,
    RoutePaths.addresses,
    RoutePaths.notifications,
    RoutePaths.editProfile,
    RoutePaths.settings,
    RoutePaths.support,
  };
  if (protected.contains(location)) return true;
  if (location.startsWith(RoutePaths.orderSuccess)) return true;
  if (location.startsWith(RoutePaths.tracking)) return true;
  if (location.startsWith(RoutePaths.orderDetail)) return true;
  return false;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: ref.watch(authRefreshNotifierProvider),
    redirect: (context, state) {
      final token = ref.read(authTokenProvider);
      final isAuthenticated = token != null && token.isNotEmpty;
      final location = state.matchedLocation;

      if (!isAuthenticated && _requiresAuth(location)) {
        return RoutePaths.login;
      }
      if (isAuthenticated &&
          (location == RoutePaths.login || location == RoutePaths.register)) {
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
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
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
        path: RoutePaths.emailVerify,
        builder: (context, state) => EmailVerifyScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
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
                path: RoutePaths.menu,
                builder: (context, state) => const MenuScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.offers,
                builder: (context, state) => const OffersScreen(),
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
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '${RoutePaths.category}/:categoryId',
        builder: (context, state) => CategoryScreen(
          categoryId: state.pathParameters['categoryId']!,
          categoryName: state.uri.queryParameters['name'] ?? 'Category',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '${RoutePaths.item}/:itemId',
        builder: (context, state) => ItemDetailScreen(
          itemId: state.pathParameters['itemId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '${RoutePaths.orderSuccess}/:orderId',
        builder: (context, state) => OrderSuccessScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '${RoutePaths.tracking}/:orderId',
        builder: (context, state) => OrderTrackingScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.addresses,
        builder: (context, state) => AddressesScreen(
          selectForCheckout: state.uri.queryParameters['select'] == 'true',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '${RoutePaths.orderDetail}/:orderId',
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RoutePaths.support,
        builder: (context, state) => SupportScreen(
          orderId: state.uri.queryParameters['orderId'],
        ),
      ),
    ],
  );
});
