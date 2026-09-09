import 'package:flutter/foundation.dart';

/// Production-safe global error hooks (extend with Crashlytics/Sentry when added).
void bootstrapFlutterApp() {
  // Silence verbose operational logging in release builds so order/assignment
  // IDs and internal state never leak to the device system log. Crash logs
  // below bypass this by writing through [debugPrintSynchronously] directly.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      debugPrintSynchronously('[FlutterError] ${details.exceptionAsString()}');
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReleaseMode) {
      debugPrintSynchronously('[Uncaught] $error\n$stack');
    }
    return true;
  };
}

void logDebug(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
