class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
  static const bool enableNetworkLogging = true;

  /// Your restaurant ID from the database — needed for menu & reports endpoints.
  /// Replace this with your actual restaurant UUID after seeding.
  static const String restaurantId = '46c52268-2146-4543-ab10-92dd34e53d3a';
}
