import '../config/app_config.dart';

class ApiEndpoints {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  
  // Menu Endpoints
  static const String menuItems = '/admin/menu';
  static String updateMenuItem(String id) => '/admin/menu/items/$id';
}
