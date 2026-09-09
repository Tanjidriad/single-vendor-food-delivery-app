import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/helpers/network_listener.dart';

class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Register for push once authenticated (no-op until Firebase is configured).
    ref.listen(authTokenProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        ref.read(pushNotificationServiceProvider).register();
      }
    });

    return NetworkListener(
      child: ResponsiveBreakpoints.builder(
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1200, name: DESKTOP),
          const Breakpoint(start: 1201, end: double.infinity, name: '4K'),
        ],
        child: MaterialApp.router(
          title: 'WASABI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) => MaxWidthBox(
            maxWidth: 1200,
            alignment: Alignment.topCenter,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
