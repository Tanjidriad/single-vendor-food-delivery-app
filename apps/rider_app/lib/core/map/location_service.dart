import 'geo_point.dart';

/// SDK-neutral abstraction over device geolocation.
///
/// Emits [GeoPoint] values so callers never depend on a map/geolocation SDK
/// type. The concrete implementation (e.g. a geolocator-backed service) lives
/// in the map implementation layer (`core/map/mapbox/`).
abstract class LocationService {
  /// A stream of live device positions as SDK-neutral points.
  Stream<GeoPoint> positionStream();

  /// The current device position, or `null` if it cannot be determined.
  Future<GeoPoint?> currentPosition();
}
