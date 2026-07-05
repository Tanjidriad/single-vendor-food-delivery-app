import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Production builds MUST inject the real API at build time:
  /// `--dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1`.
  ///
  /// The localhost fallback is gated behind `kDebugMode`, so a release build can
  /// NEVER silently ship pointing at a developer machine — if the define is
  /// missing in production the base URL is empty and requests fail fast and
  /// loudly instead of quietly hitting localhost.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kDebugMode ? 'http://localhost:3000/api/v1' : '',
  );

  static const bool enableNetworkLogging = kDebugMode;

  /// Override at build time: `--dart-define=RESTAURANT_ID=...`
  /// Debug-only fallback; production must supply the real restaurant UUID (and,
  /// longer term, derive it from the authenticated user's restaurant context).
  static const String restaurantId = String.fromEnvironment(
    'RESTAURANT_ID',
    defaultValue: kDebugMode ? '46c52268-2146-4543-ab10-92dd34e53d3a' : '',
  );
}
