import 'dart:async';

import 'package:flutter/foundation.dart';

/// Production-safe global error hooks (extend with Crashlytics/Sentry when added).
void bootstrapFlutterApp() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReleaseMode) {
      debugPrint('[Uncaught] $error\n$stack');
    }
    return true;
  };
}

void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
