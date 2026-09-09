class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String registerRider = '/auth/register/rider';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String otpSend = '/auth/otp/send';
  static const String otpVerify = '/auth/otp/verify';
  static const String forgotPasswordReset = '/auth/forgot-password/reset';

  // User / Rider Profile
  static const String me = '/users/me';
  static const String riderOnline = '/users/rider/online';
  static const String uploadsAvatar = '/uploads/avatar';
  static const String uploadsDeliveryProof = '/uploads/image/delivery-proof';

  // Push notifications (device registration)
  static const String devicesRegister = '/devices/register';

  // Rider self-service (work details + verification documents)
  static const String riderProfile = '/rider/profile';
  static const String riderDocuments = '/rider/documents';

  // Dispatch / Assignments (rider-facing)
  static String acceptAssignment(String id) => '/rider/assignments/$id/accept';
  static String rejectAssignment(String id) => '/rider/assignments/$id/reject';
  static const String acceptBatch = '/rider/assignments/accept-batch';
  static const String pendingAssignments = '/rider/assignments/pending';

  // Orders
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String updateOrderStatus(String id) => '/orders/$id/status';
  static String verifyDelivery(String id) => '/orders/$id/verify-delivery';
  static String deliveryException(String id) => '/orders/$id/delivery-exception';
  static String orderMessages(String id) => '/orders/$id/messages';

  // Earnings
  static const String earnings = '/reports/rider/earnings';

  // Performance insights
  static const String riderPerformance = '/reports/rider/performance';

  // COD cash reconciliation
  static const String riderCash = '/reports/rider/cash';

  // In-app notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
}
