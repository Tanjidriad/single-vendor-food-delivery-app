/// Semantic grouping for a customer in-app notification, derived from its push
/// `type` (e.g. `order:created`, `order:status.changed`, `order:delivery.otp`).
///
/// Drives the icon, accent colour and tap destination.
enum CustomerNotificationKind {
  orderPlaced,
  orderUpdate,
  outForDelivery,
  delivered,
  deliveryOtp,
  promo,
  system,
}

/// One in-app notification from `GET /notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.data = const {},
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> data;

  bool get isRead => readAt != null;

  /// Notification type hint from the push payload / data JSON
  /// (e.g. `order:status.changed`).
  String? get type => data['type']?.toString();

  /// Order status carried by `order:status.changed` payloads, if any.
  String? get status {
    final raw = data['status']?.toString();
    return (raw == null || raw.isEmpty) ? null : raw.toUpperCase();
  }

  /// Order this notification refers to, if any.
  String? get orderId {
    final raw = data['orderId']?.toString();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  /// True when tapping should open the order (live tracking screen).
  bool get hasOrder => orderId != null;

  /// Coarse category used for the icon, accent colour, pill label and routing.
  CustomerNotificationKind get kind {
    final t = type ?? '';
    if (t.contains('delivery.otp')) return CustomerNotificationKind.deliveryOtp;
    if (t == 'order:created') return CustomerNotificationKind.orderPlaced;
    if (t.startsWith('order')) {
      final s = status ?? '';
      if (s == 'DELIVERED') return CustomerNotificationKind.delivered;
      if (s == 'OUT_FOR_DELIVERY') return CustomerNotificationKind.outForDelivery;
      return CustomerNotificationKind.orderUpdate;
    }
    if (t.contains('promo') ||
        t.contains('offer') ||
        t.contains('discount') ||
        t.contains('coupon')) {
      return CustomerNotificationKind.promo;
    }
    return CustomerNotificationKind.system;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())?.toLocal()
          : null,
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
    );
  }

  /// Returns a copy marked read at [readAt] (defaults to now).
  AppNotification markedRead([DateTime? at]) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        readAt: at ?? DateTime.now(),
        data: data,
      );
}
