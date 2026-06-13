/// Tolerant summary view of an order for the Current Orders + History lists.
///
/// Parses the rider `GET /orders` payload (which now includes each item's
/// `menuItem.imageUrl`). Every field degrades to null/empty/default rather than
/// throwing, so a partial payload still renders.
library;

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    this.grandTotal,
    this.deliveryAddress,
    this.restaurantName,
    this.distanceKm,
    this.pickedUpAt,
    this.deliveredAt,
    this.placedAt,
    this.items = const [],
  });

  final String id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final num? grandTotal;
  final String? deliveryAddress;
  final String? restaurantName;
  final num? distanceKm;
  final DateTime? pickedUpAt; // departure
  final DateTime? deliveredAt; // arrival
  final DateTime? placedAt;
  final List<OrderItemSummary> items;

  int get itemCount =>
      items.fold(0, (sum, it) => sum + (it.quantity <= 0 ? 1 : it.quantity));

  bool get isDelivered => status == 'DELIVERED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isRejected => status == 'REJECTED';
  bool get isIgnoredTest => status == 'IGNORED_TEST';

  /// Active = not in a terminal state. Drives the Current vs History split.
  bool get isActive => !isDelivered && !isCancelled && !isRejected && !isIgnoredTest;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final restaurant = json['restaurant'];
    return OrderSummary(
      id: _str(json['id']) ?? '',
      orderNumber: _str(json['orderNumber']) ?? '',
      status: _str(json['status']) ?? 'PLACED',
      paymentMethod: _str(json['paymentMethod']) ?? 'COD',
      grandTotal: _num(json['grandTotal']),
      deliveryAddress: _str(json['deliveryAddress']),
      restaurantName: restaurant is Map
          ? _str(restaurant['name'])
          : _str(json['restaurantName']),
      distanceKm: _num(json['routeDistanceKm']),
      pickedUpAt: _date(json['pickedUpAt']),
      deliveredAt: _date(json['deliveredAt']),
      placedAt: _date(json['placedAt']) ?? _date(json['createdAt']),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((i) => OrderItemSummary.fromJson(
                    Map<String, dynamic>.from(i),
                  ))
              .toList()
          : const [],
    );
  }
}

/// One line item, including the catalog image surfaced by the backend join.
class OrderItemSummary {
  const OrderItemSummary({
    required this.name,
    required this.quantity,
    this.imageUrl,
  });

  final String name;
  final int quantity;
  final String? imageUrl;

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    final menuItem = json['menuItem'];
    return OrderItemSummary(
      name: _str(json['name']) ?? 'Item',
      quantity: _num(json['quantity'])?.toInt() ?? 1,
      imageUrl: menuItem is Map ? _str(menuItem['imageUrl']) : null,
    );
  }
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

num? _num(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim());
  return null;
}

DateTime? _date(dynamic v) {
  if (v is String && v.trim().isNotEmpty) return DateTime.tryParse(v);
  return null;
}
