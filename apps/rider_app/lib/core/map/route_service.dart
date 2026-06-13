import 'geo_point.dart';

/// SDK-neutral abstraction over a directions/routing provider.
///
/// Screens and providers depend on [RouteService] and exchange only
/// [GeoPoint] values, so the underlying map SDK (currently Mapbox) stays
/// confined to the implementation layer (`core/map/mapbox/`). A migration to
/// another provider replaces only the implementation, leaving callers
/// untouched.
abstract class RouteService {
  /// Returns the route between [start] and [end] as an ordered list of
  /// SDK-neutral points (the polyline from start to end).
  Future<List<GeoPoint>> getRoute(GeoPoint start, GeoPoint end);
}
