import 'package:equatable/equatable.dart';

/// Typed view over an order JSON document.
///
/// Commonly-read scalar fields are parsed and null-safe. Deeply nested or
/// rarely-used fields (items, restaurant, assignment, tracking internals)
/// remain reachable via [raw] until the order-tracking UI is decomposed.
/// In new code, prefer adding a typed getter here over reaching into [raw].
class OrderModel extends Equatable {
  const OrderModel({
    required this.id,
    required this.raw,
    this.orderNumber,
    this.status = 'PLACED',
    this.grandTotal = 0,
    this.subtotal,
    this.discountAmount,
    this.deliveryFee,
    this.createdAt,
    this.restaurantId,
    this.paymentMethod,
    this.paymentStatus,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['id'] ?? '').toString(),
      raw: json,
      orderNumber: json['orderNumber']?.toString(),
      status: (json['status'] as String?) ?? 'PLACED',
      grandTotal: _toDouble(json['grandTotal']) ?? 0,
      subtotal: _toDouble(json['subtotal']),
      discountAmount: _toDouble(json['discountAmount']),
      deliveryFee: _toDouble(json['deliveryFee']),
      createdAt: _toDate(json['createdAt']),
      restaurantId: json['restaurantId']?.toString(),
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
    );
  }

  final String id;
  final String? orderNumber;
  final String status;
  final double grandTotal;
  final double? subtotal;
  final double? discountAmount;
  final double? deliveryFee;
  final DateTime? createdAt;
  final String? restaurantId;
  final String? paymentMethod;
  final String? paymentStatus;

  /// The original JSON. Escape hatch for nested / not-yet-typed fields.
  final Map<String, dynamic> raw;

  /// Terminal states the backend uses for completed/closed orders.
  static const terminalStatuses = {
    'DELIVERED',
    'CANCELLED',
    'REJECTED',
    'IGNORED_TEST',
  };

  /// True when the order is still in progress (not in a terminal state).
  bool get isActive => !terminalStatuses.contains(status);

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  @override
  List<Object?> get props => [id, orderNumber, status, grandTotal, createdAt];
}
