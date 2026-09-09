import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/profile/presentation/providers/checkout_address_provider.dart';
import '../../../../features/restaurant/data/restaurant_repository.dart';

enum ZoneStatus { unknown, inside, outside }

/// Compares the current checkout address against the restaurant's active
/// delivery zones entirely on-device — no extra network call needed because
/// the restaurant response already includes deliveryZones.
final zoneStatusProvider = Provider<ZoneStatus>((ref) {
  final restaurant = ref.watch(restaurantProvider).valueOrNull;
  final address = ref.watch(checkoutAddressProvider);

  // No address saved yet — don't show any warning.
  if (address == null) return ZoneStatus.unknown;

  final zones = (restaurant?['deliveryZones'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .where((z) => z['isActive'] == true)
          .toList() ??
      [];

  // No active zones configured → restaurant delivers everywhere.
  if (zones.isEmpty) return ZoneStatus.unknown;

  final restLat = (restaurant?['latitude'] as num?)?.toDouble();
  final restLng = (restaurant?['longitude'] as num?)?.toDouble();
  final deliveryLat = (address['latitude'] as num?)?.toDouble();
  final deliveryLng = (address['longitude'] as num?)?.toDouble();

  if (restLat == null ||
      restLng == null ||
      deliveryLat == null ||
      deliveryLng == null) {
    return ZoneStatus.unknown;
  }

  for (final zone in zones) {
    final maxDist = (zone['maxDistanceKm'] as num?)?.toDouble();
    if (maxDist != null) {
      if (_haversineKm(restLat, restLng, deliveryLat, deliveryLng) <= maxDist) {
        return ZoneStatus.inside;
      }
    }

    final polygonGeo = zone['polygonGeo'];
    if (polygonGeo is Map) {
      if (_pointInPolygon(deliveryLat, deliveryLng, polygonGeo)) {
        return ZoneStatus.inside;
      }
    }
  }

  return ZoneStatus.outside;
});

double _haversineKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const R = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

bool _pointInPolygon(double lat, double lng, Map<dynamic, dynamic> polygonGeo) {
  final coordinates = polygonGeo['coordinates'];
  if (coordinates is! List || coordinates.isEmpty) return false;
  final ring = coordinates[0];
  if (ring is! List) return false;

  bool inside = false;
  for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final pi = ring[i];
    final pj = ring[j];
    if (pi is! List || pj is! List) continue;
    final xi = (pi[0] as num).toDouble();
    final yi = (pi[1] as num).toDouble();
    final xj = (pj[0] as num).toDouble();
    final yj = (pj[1] as num).toDouble();
    final intersect =
        (yi > lat) != (yj > lat) && lng < ((xj - xi) * (lat - yi) / (yj - yi) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}
