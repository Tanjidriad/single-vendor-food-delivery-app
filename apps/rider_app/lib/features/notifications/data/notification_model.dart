/// Semantic grouping for an in-app notification, derived from its push `type`.
///
/// Drives the icon, accent colour and — critically — whether a tap is allowed
/// to re-open the live accept flow. Only [offer] notifications are ever
/// time-sensitive; everything else is historical.
enum NotificationKind { offer, orderUpdate, deliveryOtp, payout, approval, system }

/// An assignment offer with no explicit `expiresAt` is treated as dead once it
/// is older than this. Real offers expire in seconds, so anything beyond this
/// window is certainly stale — this guards builds where the backend omitted
/// `expiresAt` from the persisted payload.
const Duration _offerStaleFallback = Duration(minutes: 5);

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

  /// Notification type hint from push payload / data JSON
  /// (e.g. `assignment:created`, `order:status.changed`).
  String? get type => data['type']?.toString();

  /// Order this notification refers to, if any.
  String? get orderId {
    final raw = data['orderId']?.toString();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  /// Expiry instant for a time-sensitive offer, if the payload carried one.
  DateTime? get expiresAt {
    final raw = data['expiresAt']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// True when this is a delivery-offer notification (`assignment:*`).
  bool get isOffer => (type ?? '').contains('assignment');

  /// True when this offer can no longer be accepted: its `expiresAt` has passed,
  /// or (when none was recorded) it is simply too old to still be live.
  bool get isExpiredOffer {
    if (!isOffer) return false;
    final exp = expiresAt;
    if (exp != null) return exp.isBefore(DateTime.now());
    return DateTime.now().difference(createdAt) > _offerStaleFallback;
  }

  /// The only state in which tapping should open the full-screen accept flow:
  /// a live offer that has not yet expired.
  bool get isActionableOffer => isOffer && !isExpiredOffer;

  /// Coarse category used for the icon, accent colour and grouping.
  NotificationKind get kind {
    final t = type ?? '';
    if (t.contains('assignment')) return NotificationKind.offer;
    if (t.contains('delivery.otp')) return NotificationKind.deliveryOtp;
    if (t.contains('refund') || t.contains('payout') || t.contains('earning')) {
      return NotificationKind.payout;
    }
    if (t.contains('approval')) return NotificationKind.approval;
    if (t.startsWith('order')) return NotificationKind.orderUpdate;
    return NotificationKind.system;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : const {},
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
