import 'package:flutter/foundation.dart';

import 'api_host_resolver.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl => ApiHostResolver.apiBaseUrl;

  static String get socketUrl => ApiHostResolver.socketBaseUrl;

  static const bool enableNetworkLogging = kDebugMode;

  /// Override at build time: `--dart-define=RESTAURANT_ID=...`
  static const String restaurantId = String.fromEnvironment(
    'RESTAURANT_ID',
    defaultValue: '46c52268-2146-4543-ab10-92dd34e53d3a',
  );
}
