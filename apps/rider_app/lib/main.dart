import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/config/api_host_resolver.dart';
import 'core/map/mapbox/mapbox_bootstrap.dart';
import 'core/services/push_notification_service.dart';

/// Sentry DSN, injected at build time:
/// `flutter build apk --release --dart-define=SENTRY_DSN=https://...`.
/// Empty (the default) keeps Sentry fully disabled — the app then relies on the
/// local error hooks in [bootstrapFlutterApp].
const String _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bootstrapFlutterApp();

  if (kDebugMode) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }

  bootstrapMapbox();
  // Guarded — no-ops until Firebase credential files are added to the project.
  await initFirebaseMessaging();
  final prefs = await SharedPreferences.getInstance();
  await ApiHostResolver.init(prefs);

  // When no DSN is configured, skip Sentry entirely and run the app directly.
  if (_sentryDsn.isEmpty) {
    runApp(const ProviderScope(child: RiderApp()));
    return;
  }

  // Sentry installs its own FlutterError / PlatformDispatcher handlers (chaining
  // the ones set in [bootstrapFlutterApp]) and runs the app inside a guarded
  // zone so uncaught async errors are reported too.
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = 0.2;
      options.enableAutoSessionTracking = true;
      // Don't ship PII (rider id, order ids in breadcrumbs) to Sentry.
      options.sendDefaultPii = false;
    },
    appRunner: () => runApp(const ProviderScope(child: RiderApp())),
  );
}
