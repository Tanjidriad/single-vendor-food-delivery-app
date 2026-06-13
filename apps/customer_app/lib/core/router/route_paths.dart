abstract final class RoutePaths {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static String resetPasswordWithEmail(String email) => '$resetPassword?email=$email';
  static const emailVerify = '/email-verify';
  static String emailVerifyWithEmail(String email) => '$emailVerify?email=$email';
  static const home = '/home';
  static const orders = '/orders';
  static const offers = '/offers';
  static const profile = '/profile';

  static const search = '/search';
  static const menu = '/menu';
  static const category = '/category';
  static String categoryWithId(String id) => '/category/$id';
  static const item = '/item';
  static String itemWithId(String id) => '/item/$id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orderSuccess = '/order-success';
  static String orderSuccessWithId(String id) => '/order-success/$id';
  static const tracking = '/tracking';
  static String trackingWithId(String id) => '/tracking/$id';
  static const favorites = '/favorites';
  static const addresses = '/addresses';
  static const notifications = '/notifications';
  static const editProfile = '/edit-profile';
  static const settings = '/settings';
  static const orderDetail = '/order';
  static String orderDetailWithId(String id) => '/order/$id';
  static const support = '/support';
}
