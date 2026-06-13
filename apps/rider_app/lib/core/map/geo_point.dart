import 'package:flutter/foundation.dart';

/// An SDK-neutral geographic coordinate.
///
/// [GeoPoint] is the boundary type exchanged between screens, providers, and
/// the map abstraction. It deliberately carries no map-SDK types so that the
/// underlying SDK (currently Mapbox) can be swapped without touching callers.
/// Conversion to/from SDK coordinate types lives only in the map
/// implementation layer (`core/map/mapbox/`).
@immutable
class GeoPoint {
  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint(latitude: $latitude, longitude: $longitude)';
}
