import 'package:flutter/foundation.dart';

import 'api_host_resolver.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl => ApiHostResolver.apiBaseUrl;

  static String get socketUrl => ApiHostResolver.socketBaseUrl;

  static const bool enableNetworkLogging = kDebugMode;
}
