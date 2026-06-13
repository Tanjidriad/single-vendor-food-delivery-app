/// NestJS API path segments (base URL from [AppConfig.apiBaseUrl]).
abstract final class ApiEndpoints {
  static const health = '/health';
  static const devClientConfig = '/dev/client-config';

  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';
  static const authOtpSend = '/auth/otp/send';
  static const authOtpVerify = '/auth/otp/verify';
  static const authForgotPasswordReset = '/auth/forgot-password/reset';

  static const notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';

  static String orderCancel(String id) => '/orders/$id/cancel';
  static String orderReorder(String id) => '/orders/$id/reorder';
  static String orderReview(String orderId) => '/reviews/orders/$orderId';

  static const complaints = '/complaints';
  static const complaintsMe = '/complaints/me';

  static const usersMe = '/users/me';
  static const uploadsAvatar = '/uploads/avatar';

  static String restaurantBySlug(String slug) => '/restaurant/slug/$slug';
  static String menu(String restaurantId) => '/menu/restaurant/$restaurantId';
  static String menuFeatured(String restaurantId) =>
      '/menu/restaurant/$restaurantId/featured';
  static String menuBanners(String restaurantId) =>
      '/menu/restaurant/$restaurantId/banners';
  static String menuSearch(String restaurantId) =>
      '/menu/restaurant/$restaurantId/search';
  static String menuFilter(String restaurantId) =>
      '/menu/restaurant/$restaurantId/filter';
  static String menuItem(String itemId) => '/menu/items/$itemId';

  static const orders = '/orders';
  static String order(String id) => '/orders/$id';
  static String orderConfirmDelivery(String id) => '/orders/$id/confirm-delivery';

  static const deliveryFeeQuote = '/delivery-fee/quote';
  static const deliveryFeeGeocode = '/delivery-fee/geocode';

  static const addresses = '/addresses';
  static String address(String id) => '/addresses/$id';

  static const favorites = '/favorites';
  static String favorite(String menuItemId) => '/favorites/$menuItemId';

  static const couponsPublic = '/coupons/public';
  static const couponsValidate = '/coupons/validate';

  static String paymentOnlineInitiate(String orderId) =>
      '/payments/orders/$orderId/online/initiate';
  static String paymentOnlineExecute(String orderId) =>
      '/payments/orders/$orderId/online/execute';
}
