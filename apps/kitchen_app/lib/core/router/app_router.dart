import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/kds/presentation/screens/kds_board_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/kds',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState.status == AuthStatus.initial) return null;

      if (authState.status == AuthStatus.unauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn && authState.status == AuthStatus.authenticated) {
        return '/kds';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/kds',
        builder: (context, state) => const KdsBoardScreen(),
      ),
    ],
  );
});
