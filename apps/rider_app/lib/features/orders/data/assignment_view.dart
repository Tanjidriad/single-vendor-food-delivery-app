/// Tolerant parse/view model for an incoming delivery assignment.
///
/// Maps the `assignment:created` WebSocket payload (also held by
/// `activeAssignmentProvider`) into a typed, SDK-neutral object used by the
/// redesigned incoming order screen. The backend emits a flat payload
/// (`assignmentId`, `orderId`, `pickupLat`/`pickupLng`, `dropLat`/`dropLng`,
/// `expiresAt`, …) but some payloads also carry a nested `order` object and the
/// existing screen reads alternate keys (`estimatedPayout`/`deliveryFee`,
/// `grandTotal`/`cashToCollect`, `distanceKm`/`totalDistanceKm`). Parsing is
/// therefore tolerant: every field falls back across the known key aliases and
/// degrades to `null`/a sensible default rather than throwing when a field is
/// missing or malformed.
///
/// This model deliberately carries no map-SDK types — coordinates are exposed
/// as SDK-neutral [GeoPoint] values via [pickupPoint]/[dropoffPoint] (see
/// Requirement 10).
library;

import '../../../../core/map/geo_point.dart';

class AssignmentView {
  /// The assignment identifier used to accept/reject. Empty when absent.
  final String assignmentId;

  /// The associated order identifier, if present.
  final String? orderId;

  /// Estimated rider payout. Falls back to the delivery fee. `null` -> `'--'`.
  final num? estimatedPayout;

  /// Cash to collect from the customer. Falls back to the order grand total.
  final num? cashToCollect;

  /// Payment method label (e.g. `COD`). Defaults to `'Cash on Delivery'`.
  final String paymentMethod;

  /// Pickup (restaurant) display name. Defaults to `'Restaurant'`.
  final String pickupName;

  /// Pickup (restaurant) coordinates, if present.
  final num? pickupLat;
  final num? pickupLng;

  /// Dropoff (customer) coordinates, if present.
  final num? dropoffLat;
  final num? dropoffLng;

  /// Distance of the restaurant pickup leg, in km, if present.
  final num? pickupLegKm;

  /// Distance of the customer dropoff leg, in km, if present.
  final num? dropoffLegKm;

  /// When the assignment response window expires; drives the countdown ring.
  final DateTime? expiresAt;

  const AssignmentView({
    required this.assignmentId,
    this.orderId,
    this.estimatedPayout,
    this.cashToCollect,
    this.paymentMethod = 'Cash on Delivery',
    this.pickupName = 'Restaurant',
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.pickupLegKm,
    this.dropoffLegKm,
    this.expiresAt,
  });

  /// The pickup location as an SDK-neutral [GeoPoint], or `null` when either
  /// coordinate is missing.
  GeoPoint? get pickupPoint => (pickupLat != null && pickupLng != null)
      ? GeoPoint(
          latitude: pickupLat!.toDouble(),
          longitude: pickupLng!.toDouble(),
        )
      : null;

  /// The dropoff location as an SDK-neutral [GeoPoint], or `null` when either
  /// coordinate is missing.
  GeoPoint? get dropoffPoint => (dropoffLat != null && dropoffLng != null)
      ? GeoPoint(
          latitude: dropoffLat!.toDouble(),
          longitude: dropoffLng!.toDouble(),
        )
      : null;

  /// Builds an [AssignmentView] from a raw assignment payload map.
  ///
  /// Tolerant of missing/null fields and of the nested `order` object: each
  /// field is resolved from the top-level payload first, then the nested order,
  /// across the known key aliases. Never throws on a well-formed map.
  factory AssignmentView.fromJson(Map<String, dynamic> json) {
    final order = _asMap(json['order']);
    final restaurant = _asMap(json['restaurant']) ?? _asMap(order?['restaurant']);

    // Resolves a value across the top-level payload then the nested order.
    Object? pick(List<String> keys) {
      for (final key in keys) {
        final top = json[key];
        if (top != null) return top;
      }
      if (order != null) {
        for (final key in keys) {
          final nested = order[key];
          if (nested != null) return nested;
        }
      }
      return null;
    }

    return AssignmentView(
      assignmentId: _asString(pick(['assignmentId', 'id'])) ?? '',
      orderId: _asString(pick(['orderId'])),
      estimatedPayout: _asNum(pick(['estimatedPayout', 'deliveryFee'])),
      cashToCollect: _asNum(pick(['cashToCollect', 'grandTotal'])),
      paymentMethod:
          _asString(pick(['paymentMethod'])) ?? 'Cash on Delivery',
      pickupName: _asString(pick(['pickupName', 'restaurantName'])) ??
          _asString(restaurant?['name']) ??
          'Restaurant',
      pickupLat: _asNum(pick(['pickupLat'])) ?? _asNum(restaurant?['latitude']),
      pickupLng: _asNum(pick(['pickupLng'])) ?? _asNum(restaurant?['longitude']),
      dropoffLat: _asNum(pick(['dropoffLat', 'dropLat', 'deliveryLat'])),
      dropoffLng: _asNum(pick(['dropoffLng', 'dropLng', 'deliveryLng'])),
      pickupLegKm: _asNum(pick(['pickupLegKm', 'distanceKm'])),
      dropoffLegKm:
          _asNum(pick(['dropoffLegKm', 'dropLegKm', 'totalDistanceKm'])),
      expiresAt: _asDateTime(pick(['expiresAt'])),
    );
  }
}

/// Coerces a dynamic value to a [Map] of string keys, or `null`.
Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// Coerces a dynamic value to a non-empty [String], or `null`.
String? _asString(Object? value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

/// Coerces a dynamic value to a [num], parsing numeric strings, or `null`.
num? _asNum(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

/// Coerces a dynamic value to a [DateTime] from an ISO string or epoch millis.
DateTime? _asDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value.trim());
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}
