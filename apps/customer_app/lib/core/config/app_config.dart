import 'api_host_resolver.dart';

/// Runtime configuration — set [ApiHostResolver.init] in main() before runApp.
class AppConfig {
  const AppConfig._();

  static String get apiBaseUrl => ApiHostResolver.apiBaseUrl;

  static String get socketBaseUrl => ApiHostResolver.socketBaseUrl;

  static const String restaurantSlug = String.fromEnvironment(
    'RESTAURANT_SLUG',
    defaultValue: 'demo-kitchen',
  );
}
