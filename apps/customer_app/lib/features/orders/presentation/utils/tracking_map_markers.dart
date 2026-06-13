import 'dart:math' as math;

import '../../../../core/widgets/map/models/app_map_marker.dart';
import '../providers/order_tracking_provider.dart';

double? coordFromJson(dynamic value) {
  if (value == null) return null;
  double? parsed;
  if (value is num) {
    parsed = value.toDouble();
  } else if (value is String) {
    parsed = double.tryParse(value);
  }
  return validMapCoord(parsed);
}

/// Rejects null island and unset Prisma defaults (0, 0).
double? validMapCoord(double? value) {
  if (value == null) return null;
  if (value.abs() < 1e-6) return null;
  return value;
}

/// Offsets pins that share the same coordinates so they remain visible.
List<AppMapMarker> spreadMapMarkers(List<AppMapMarker> markers) {
  if (markers.length <= 1) return markers;

  const minSeparation = 0.00022; // ~25 m
  final placed = <AppMapMarker>[];

  for (final marker in markers) {
    var lat = marker.latitude;
    var lng = marker.longitude;
    var attempt = 0;

    while (attempt < 8) {
      var tooClose = false;
      for (final other in placed) {
        if ((lat - other.latitude).abs() < minSeparation &&
            (lng - other.longitude).abs() < minSeparation) {
          tooClose = true;
          break;
        }
      }
      if (!tooClose) break;

      final angle = (attempt + 1) * (math.pi / 4);
      lat = marker.latitude + minSeparation * math.sin(angle);
      lng = marker.longitude + minSeparation * math.cos(angle);
      attempt++;
    }

    placed.add(
      AppMapMarker(
        id: marker.id,
        latitude: lat,
        longitude: lng,
        title: marker.title,
        snippet: marker.snippet,
        headingDegrees: marker.headingDegrees,
      ),
    );
  }

  return placed;
}

/// When live GPS is missing but a rider is active, show an estimated pin
/// between restaurant and delivery address.
Map<String, dynamic>? estimatedRiderLocation(
  Map<String, dynamic> order,
  Map<String, dynamic>? liveLocation,
) {
  if (liveLocation != null) return liveLocation;

  final status = (order['status'] as String? ?? '').toUpperCase();
  if (status != 'ON_THE_WAY' && status != 'PICKED_UP') return null;
  if (!riderInfoFromOrder(order).isAssigned) return null;

  final fromApi = riderLocationFromOrder(order);
  if (fromApi != null) return fromApi;

  double? rLat;
  double? rLng;
  double? hLat;
  double? hLng;

  final restaurant = order['restaurant'];
  if (restaurant is Map) {
    final map = Map<String, dynamic>.from(restaurant);
    rLat = coordFromJson(map['latitude']);
    rLng = coordFromJson(map['longitude']);
  }

  hLat = coordFromJson(order['deliveryLat']);
  hLng = coordFromJson(order['deliveryLng']);

  if (rLat != null && rLng != null && hLat != null && hLng != null) {
    return {
      'latitude': rLat + (hLat - rLat) * 0.4,
      'longitude': rLng + (hLng - rLng) * 0.4,
    };
  }

  if (rLat != null && rLng != null) {
    return {'latitude': rLat, 'longitude': rLng};
  }

  return null;
}

/// Builds map pins in draw order: restaurant → home → rider (on top).
List<AppMapMarker> buildTrackingMapMarkers(
  Map<String, dynamic> order,
  Map<String, dynamic>? riderLocation,
) {
  final pins = <AppMapMarker>[];

  final restaurant = order['restaurant'];
  if (restaurant is Map) {
    final map = Map<String, dynamic>.from(restaurant);
    final rLat = coordFromJson(map['latitude']);
    final rLng = coordFromJson(map['longitude']);
    if (rLat != null && rLng != null) {
      pins.add(
        AppMapMarker(
          id: 'restaurant',
          latitude: rLat,
          longitude: rLng,
          title: map['name'] as String?,
        ),
      );
    }
  }

  final dLat = coordFromJson(order['deliveryLat']);
  final dLng = coordFromJson(order['deliveryLng']);
  if (dLat != null && dLng != null) {
    pins.add(
      AppMapMarker(
        id: 'home',
        latitude: dLat,
        longitude: dLng,
      ),
    );
  }

  final effectiveRider = estimatedRiderLocation(order, riderLocation);
  if (effectiveRider != null) {
    final riderLat = coordFromJson(effectiveRider['latitude']);
    final riderLng = coordFromJson(effectiveRider['longitude']);
    if (riderLat != null && riderLng != null) {
      final heading = coordFromJson(effectiveRider['heading']);
      pins.add(
        AppMapMarker(
          id: 'rider',
          latitude: riderLat,
          longitude: riderLng,
          headingDegrees: heading,
        ),
      );
    }
  }

  return spreadMapMarkers(pins);
}

(double lat, double lng) trackingMapCenter(
  Map<String, dynamic> order,
  List<AppMapMarker> markers,
) {
  if (markers.isNotEmpty) {
    var lat = 0.0;
    var lng = 0.0;
    for (final m in markers) {
      lat += m.latitude;
      lng += m.longitude;
    }
    return (lat / markers.length, lng / markers.length);
  }

  final lat = coordFromJson(order['deliveryLat']);
  final lng = coordFromJson(order['deliveryLng']);
  if (lat != null && lng != null) return (lat, lng);

  final restaurant = order['restaurant'];
  if (restaurant is Map) {
    final rLat = coordFromJson(restaurant['latitude']);
    final rLng = coordFromJson(restaurant['longitude']);
    if (rLat != null && rLng != null) return (rLat, rLng);
  }

  return (23.8103, 90.4125);
}
