import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/config/api_host_resolver.dart';
import 'core/router/app_router.dart';
import 'core/services/kitchen_preferences.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/kitchen_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bootstrapFlutterApp();
  // Guarded — no-ops until Firebase credential files are added to the project.
  await initFirebaseMessaging();
  final prefs = await SharedPreferences.getInstance();
  await ApiHostResolver.init(prefs);
  runApp(const ProviderScope(child: KitchenApp()));
}

class KitchenApp extends ConsumerWidget {
  const KitchenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final prefs = ref.watch(kitchenPreferencesProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Kitchen App',
      theme: KitchenTheme.lightTheme,
      darkTheme: KitchenTheme.darkTheme,
      themeMode: prefs.themeMode,
      routerConfig: router,
    );
  }
}
