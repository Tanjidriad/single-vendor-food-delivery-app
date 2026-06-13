import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/orders/presentation/providers/assignment_bridge_provider.dart';
import 'features/orders/presentation/providers/socket_lifecycle_provider.dart';

class RiderApp extends ConsumerWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    if (ref.watch(authProvider)) {
      ref.watch(assignmentBridgeProvider);
      ref.watch(socketLifecycleProvider);
    }

    return MaterialApp.router(
      title: 'Food Delivery Rider',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Ship light — the ZIPS-style look is a light-forward, crimson-accented UI.
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
