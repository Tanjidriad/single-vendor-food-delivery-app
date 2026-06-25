import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/config/api_host_resolver.dart';
import 'core/services/push_notification_service.dart';
import 'core/utils/local_storage/storage_utility.dart';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bootstrapFlutterApp();

  if (kDebugMode) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }

  // Guarded — no-ops until Firebase credential files are added to the project.
  await initFirebaseMessaging();
  if (isFirebaseConfigured()) {
    await enableCrashlyticsReporting();
  }

  final prefs = await SharedPreferences.getInstance();
  await ApiHostResolver.init(prefs);

  const envMapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  final mapboxToken = envMapboxToken.isNotEmpty
      ? envMapboxToken
      : (kDebugMode && dotenv.isInitialized) ? dotenv.env['MAPBOX_ACCESS_TOKEN'] : null;
  if (mapboxToken == null || mapboxToken.isEmpty) {
    throw StateError(
      'MAPBOX_ACCESS_TOKEN is not set. Pass --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxx '
      'or add it to apps/customer_app/.env in debug mode.',
    );
  }
  MapboxOptions.setAccessToken(mapboxToken);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CustomerApp(),
    ),
  );
}
