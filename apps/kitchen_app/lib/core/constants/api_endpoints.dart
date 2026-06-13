class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';

  // Orders (role-based — OWNER/MANAGER/CASHIER/KITCHEN get restaurant orders)
  static const String orders = '/orders';
  static String updateOrderStatus(String id) => '/orders/$id/status';
  
  // Menu (public — needs restaurantId in path)
  static String menuForRestaurant(String restaurantId) =>
      '/menu/restaurant/$restaurantId';

  // Menu Admin (needs auth — OWNER/MANAGER/CASHIER)
  static const String adminMenu = '/admin/menu';
  static const String adminMenuItems = '/admin/menu/items';
  static const String adminMenuCategories = '/admin/menu/categories';
  static const String adminMenuAddons = '/admin/menu/addons';
  static const String adminMedia = '/admin/media';

  // Banners Admin (needs auth — OWNER/MANAGER)
  static const String adminBanners = '/admin/restaurant/banners';
  
  // Coupons Admin (needs auth — OWNER/MANAGER)
  static const String adminCoupons = '/admin/restaurant/coupons';

  // Riders Admin
  static const String adminRiders = '/admin/riders';
  static const String adminRidersPending = '/admin/riders/pending';
  static String adminRidersApprove(String id) => '/admin/riders/$id/approve';

  // Users
  static const String usersMe = '/users/me';

  // Reports (OWNER/MANAGER only)
  static const String reportsSales = '/reports/sales';
  static const String reportsEarnings = '/reports/earnings';
  static const String reportsRiders = '/reports/riders';
}
