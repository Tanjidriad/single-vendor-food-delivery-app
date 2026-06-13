import 'dart:async';

import 'package:flutter/foundation.dart';

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
