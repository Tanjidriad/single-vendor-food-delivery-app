import 'dart:math' as math;

import 'geo_point.dart';

/// Pure geographic helpers operating on SDK-neutral [GeoPoint] values.
///
/// These functions carry no map-SDK types so they can be used from screens and
/// providers without breaching the map abstraction boundary (Requirement 10).

/// Returns the initial compass bearing, in degrees in the range `[0, 360)`,
/// for travelling along the great-circle path from [from] to [to].
///
/// The result is a true compass heading where `0` is north and the value
/// increases clockwise (so `90` is east), matching the directional rider
/// marker's rotation convention (Requirement 6.6).
///
/// Returns `null` when [from] and [to] are the same point, since a heading is
/// undefined with no displacement.
double? bearingBetween(GeoPoint from, GeoPoint to) {
  if (from == to) return null;

  final lat1 = _toRadians(from.latitude);
  final lat2 = _toRadians(to.latitude);
  final deltaLon = _toRadians(to.longitude - from.longitude);

  final y = math.sin(deltaLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);

  final theta = math.atan2(y, x);
  final degrees = theta * 180.0 / math.pi;

  // Normalize into [0, 360).
  return (degrees + 360.0) % 360.0;
}

double _toRadians(double degrees) => degrees * math.pi / 180.0;
