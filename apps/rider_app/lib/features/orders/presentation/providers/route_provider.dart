import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../../core/map/geo_point.dart';
import '../../../../core/map/mapbox/mapbox_route_service.dart';
import '../../../../core/map/route_service.dart';

/// Provides the [RouteService] implementation used to fetch routes as
/// SDK-neutral [GeoPoint] polylines.
///
/// The concrete [MapboxRouteService] lives in the map implementation layer, so
/// this provider (and its consumers) never depend on a map-SDK coordinate type
/// and `route_provider.dart` stays free of any `mapbox_maps_flutter` import
/// (Requirement 10.1).
final routeServiceProvider = Provider<RouteService>(
  (ref) => MapboxRouteService(),
);

class RouteRequest {
  final GeoPoint start;
  final GeoPoint end;

  RouteRequest({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteRequest &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

final routeProvider =
    FutureProvider.family<List<GeoPoint>, RouteRequest>((ref, request) async {
  final service = ref.watch(routeServiceProvider);
  return await service.getRoute(request.start, request.end);
});

class LiveRouteState {
  final List<GeoPoint> route;
  final GeoPoint? destination;

  LiveRouteState({this.route = const [], this.destination});
}

class LiveRouteNotifier extends Notifier<LiveRouteState> {
  @override
  LiveRouteState build() {
    return LiveRouteState();
  }

  Future<void> updateLocation(
      GeoPoint currentLocation, GeoPoint destination) async {
    // If destination changed or route is empty, fetch immediately
    if (state.destination?.latitude != destination.latitude ||
        state.destination?.longitude != destination.longitude ||
        state.route.isEmpty) {
      await _fetchRoute(currentLocation, destination);
      return;
    }

    // Check if off-route
    bool isOffRoute = true;
    for (final point in state.route) {
      final distance = geo.Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < 50.0) {
        isOffRoute = false;
        break;
      }
    }

    if (isOffRoute) {
      await _fetchRoute(currentLocation, destination);
    }
  }

  Future<void> _fetchRoute(GeoPoint start, GeoPoint end) async {
    final service = ref.read(routeServiceProvider);
    final route = await service.getRoute(start, end);
    state = LiveRouteState(route: route, destination: end);
  }
}

final liveRouteProvider =
    NotifierProvider<LiveRouteNotifier, LiveRouteState>(() {
  return LiveRouteNotifier();
});
