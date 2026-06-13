import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/map/mapbox_directions_service.dart';
import '../../../../core/map/models/app_map_route_point.dart';
import '../../../../core/widgets/map/models/app_map_marker.dart';
import '../utils/tracking_map_markers.dart';
import 'order_tracking_provider.dart';

final mapboxDirectionsServiceProvider = Provider<MapboxDirectionsService>(
  (ref) => MapboxDirectionsService(),
);

/// Mapbox driving geometry for the customer tracking map.
final trackingRouteProvider = FutureProvider.autoDispose
    .family<List<AppMapRoutePoint>, String>((ref, orderId) async {
  final tracking = ref.watch(orderTrackingProvider(orderId));
  final state = tracking.valueOrNull;
  if (state?.order == null) return [];

  final order = state!.order!;
  final status = (order['status'] as String? ?? '').toUpperCase();
  if (status == 'DELIVERED' || status == 'CANCELLED') return [];

  final markers = buildTrackingMapMarkers(order, state.riderLocation);
  final waypoints = _routeWaypoints(order, markers, status);
  if (waypoints.length < 2) return [];

  return ref.read(mapboxDirectionsServiceProvider).getRouteThrough(waypoints);
});

AppMapMarker? _markerById(List<AppMapMarker> markers, String id) {
  for (final m in markers) {
    if (m.id == id) return m;
  }
  return null;
}

AppMapRoutePoint _toRoutePoint(AppMapMarker marker) {
  return AppMapRoutePoint(
    latitude: marker.latitude,
    longitude: marker.longitude,
  );
}

/// Ordered stops for the driving route line.
List<AppMapRoutePoint> _routeWaypoints(
  Map<String, dynamic> order,
  List<AppMapMarker> markers,
  String status,
) {
  final restaurant = _markerById(markers, 'restaurant');
  final rider = _markerById(markers, 'rider');
  final home = _markerById(markers, 'home');

  final onDeliveryLeg = status == 'ON_THE_WAY' || status == 'PICKED_UP';

  if (onDeliveryLeg && rider != null && home != null) {
    if (restaurant != null) {
      return [
        _toRoutePoint(restaurant),
        _toRoutePoint(rider),
        _toRoutePoint(home),
      ];
    }
    return [_toRoutePoint(rider), _toRoutePoint(home)];
  }

  if (restaurant != null && home != null) {
    return [_toRoutePoint(restaurant), _toRoutePoint(home)];
  }

  if (rider != null && home != null) {
    return [_toRoutePoint(rider), _toRoutePoint(home)];
  }

  return [];
}
