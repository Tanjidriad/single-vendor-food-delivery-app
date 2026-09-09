import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

bool _crashlyticsEnabled = false;

/// Installs global error handlers. Until [enableCrashlyticsReporting] is called
/// (i.e. while Firebase is unconfigured), errors fall back to a release-only
/// debug log so the KDS still runs without crash reporting.
void bootstrapFlutterApp() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (_crashlyticsEnabled) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } else if (kReleaseMode) {
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (_crashlyticsEnabled) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else if (kReleaseMode) {
      debugPrint('[Uncaught] $error\n$stack');
    }
    return true;
  };
}

/// Routes uncaught errors to Crashlytics. Call once, after Firebase has
/// initialized successfully. Collection is disabled in debug so local runs
/// don't ship noise to the dashboard.
Future<void> enableCrashlyticsReporting() async {
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  _crashlyticsEnabled = true;
}
