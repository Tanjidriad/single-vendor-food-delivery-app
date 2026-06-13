/// Tolerant parse/view model for the rider's active delivery order.
///
/// Maps the order payload held by `activeOrderProvider` (fetched after
/// accepting an assignment) into a typed, SDK-neutral object used by the
/// redesigned active delivery screen. The backend payload is flat with a
/// nested `restaurant` object: it carries `id`, `customerName`,
/// `customerPhone`, `deliveryAddress`, `deliveryLat`/`deliveryLng`,
/// `grandTotal`, `paymentMethod`, `routeEtaMinutes`, and either a nested
/// `restaurant` (`name`, `latitude`, `longitude`) or a flat `restaurantName`.
///
/// Parsing is tolerant: every field falls back across the known key aliases and
/// degrades to `null`/a sensible default rather than throwing when a field is
/// missing or malformed.
///
/// This model deliberately carries no map-SDK types — coordinates are exposed
/// as SDK-neutral [GeoPoint] values via [restaurantPoint]/[dropoffPoint] (see
/// Requirement 10).
library;

import '../../../../core/map/geo_point.dart';

class ActiveOrderView {
  /// The order identifier. Empty when absent.
  final String id;

  /// Customer display name. Defaults to `'Customer'`.
  final String customerName;

  /// Customer phone number, if present. Drives call-control visibility
  /// (see [hasPhone]).
  final String? customerPhone;

  /// Customer delivery address. Defaults to `'Delivery address'`.
  final String deliveryAddress;

  /// Pickup (restaurant) display name. Defaults to `'Restaurant'`.
  final String restaurantName;

  /// Pickup (restaurant) coordinates as an SDK-neutral [GeoPoint], or `null`
  /// when either coordinate is missing.
  final GeoPoint? restaurantPoint;

  /// Dropoff (customer) coordinates as an SDK-neutral [GeoPoint], or `null`
  /// when either coordinate is missing.
  final GeoPoint? dropoffPoint;

  /// Payment method label (e.g. `COD`). Defaults to `'COD'`.
  final String paymentMethod;

  /// Order grand total, if present. `null` -> render `'--'`.
  final num? grandTotal;

  /// Estimated time to the current destination, in minutes, if present.
  final int? etaMinutes;

  /// List of items in the order.
  final List<ActiveOrderItemView> items;

  const ActiveOrderView({
    this.id = '',
    this.customerName = 'Customer',
    this.customerPhone,
    this.deliveryAddress = 'Delivery address',
    this.restaurantName = 'Restaurant',
    this.restaurantPoint,
    this.dropoffPoint,
    this.paymentMethod = 'COD',
    this.grandTotal,
    this.etaMinutes,
    this.items = const [],
  });

  /// Whether the order carries a usable customer phone number.
  ///
  /// True if and only if [customerPhone] is non-empty after trimming, so a
  /// whitespace-only value is treated as absent (Correctness Property 11).
  bool get hasPhone => (customerPhone ?? '').trim().isNotEmpty;

  /// The destination for the given delivery [step].
  ///
  /// While heading to / waiting at the restaurant (`step < 2`) the destination
  /// is the [restaurantPoint]; from the pickup onward (`step >= 2`) it is the
  /// customer [dropoffPoint]. Returns `null` when the relevant point is missing.
  GeoPoint? destinationForStep(int step) =>
      step < 2 ? restaurantPoint : dropoffPoint;

  /// Builds an [ActiveOrderView] from a raw order payload map.
  ///
  /// Tolerant of missing/null fields and of the nested `restaurant` object:
  /// the restaurant name and coordinates are resolved from the nested object
  /// first, then from flat aliases. Never throws on a well-formed map.
  factory ActiveOrderView.fromJson(Map<String, dynamic> json) {
    final restaurant = _asMap(json['restaurant']);

    final restaurantLat =
        _asNum(restaurant?['latitude']) ?? _asNum(json['restaurantLat']);
    final restaurantLng =
        _asNum(restaurant?['longitude']) ?? _asNum(json['restaurantLng']);
    final dropoffLat =
        _asNum(json['deliveryLat']) ?? _asNum(json['dropoffLat']);
    final dropoffLng =
        _asNum(json['deliveryLng']) ?? _asNum(json['dropoffLng']);

    final rawItems = json['items'];
    final itemsList = (rawItems is List)
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map((e) => ActiveOrderItemView.fromJson(e))
            .toList()
        : <ActiveOrderItemView>[];

    return ActiveOrderView(
      id: _asString(json['id']) ?? '',
      customerName: _asString(json['customerName']) ?? 'Customer',
      customerPhone: _asString(json['customerPhone']),
      deliveryAddress: _asString(json['deliveryAddress']) ?? 'Delivery address',
      restaurantName: _asString(restaurant?['name']) ??
          _asString(json['restaurantName']) ??
          'Restaurant',
      restaurantPoint: _toGeoPoint(restaurantLat, restaurantLng),
      dropoffPoint: _toGeoPoint(dropoffLat, dropoffLng),
      paymentMethod: _asString(json['paymentMethod']) ?? 'COD',
      grandTotal: _asNum(json['grandTotal']),
      etaMinutes:
          _asNum(json['routeEtaMinutes'] ?? json['etaMinutes'])?.toInt(),
      items: itemsList,
    );
  }
}

class ActiveOrderItemView {
  final String name;
  final num unitPrice;
  final int quantity;
  final List<String> addons;

  const ActiveOrderItemView({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.addons = const [],
  });

  factory ActiveOrderItemView.fromJson(Map<String, dynamic> json) {
    final rawAddons = json['addons'];
    final addonsList = (rawAddons is List)
        ? rawAddons
            .whereType<Map<String, dynamic>>()
            .map((e) => _asString(e['name']))
            .whereType<String>()
            .toList()
        : <String>[];

    return ActiveOrderItemView(
      name: _asString(json['name']) ?? 'Item',
      unitPrice: _asNum(json['unitPrice']) ?? 0,
      quantity: _asNum(json['quantity'])?.toInt() ?? 1,
      addons: addonsList,
    );
  }
}

/// Builds a [GeoPoint] from a lat/lng pair, or `null` when either is missing.
GeoPoint? _toGeoPoint(num? lat, num? lng) =>
    (lat != null && lng != null)
        ? GeoPoint(latitude: lat.toDouble(), longitude: lng.toDouble())
        : null;

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
