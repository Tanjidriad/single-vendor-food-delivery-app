import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'mapbox_directions_service.dart';
import '../geo_point.dart';
import '../route_service.dart';
import 'coordinate_conversions.dart';

/// Mapbox-backed implementation of [RouteService].
///
/// Lives in the map implementation layer (`core/map/mapbox/`), the only place
/// allowed to import `mapbox_maps_flutter` (Requirement 10.4). It wraps the
/// existing [MapboxDirectionsService] (which traffics in Mapbox [Position]
/// values) and converts at the boundary so callers exchange only SDK-neutral
/// [GeoPoint] values (Requirement 10.6).
class MapboxRouteService implements RouteService {
  /// The underlying Mapbox directions client.
  final MapboxDirectionsService _directionsService;

  /// Creates a [MapboxRouteService]. A [MapboxDirectionsService] may be
  /// supplied (useful for testing); otherwise one is created internally.
  MapboxRouteService({MapboxDirectionsService? directionsService})
      : _directionsService = directionsService ?? MapboxDirectionsService();

  @override
  Future<List<GeoPoint>> getRoute(GeoPoint start, GeoPoint end) async {
    // Convert SDK-neutral points to Mapbox positions at the boundary.
    final Position startPosition = start.toPosition();
    final Position endPosition = end.toPosition();

    // The directions service returns an empty list on failure or when no
    // route is found; that empty result maps to an empty list of points,
    // matching the previous route provider's behavior.
    final List<Position> positions =
        await _directionsService.getRoute(startPosition, endPosition);

    // Map each Mapbox position back to an SDK-neutral GeoPoint, preserving
    // order and length (Requirement 10.6).
    return positions.map((position) => position.toGeoPoint()).toList();
  }
}
