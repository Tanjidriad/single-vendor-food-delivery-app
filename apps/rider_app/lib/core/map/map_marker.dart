import 'package:flutter/foundation.dart';

import 'geo_point.dart';

/// The kind of marker the map abstraction should render.
///
/// [rider] is the directional courier marker that uses [MapMarker.headingDegrees]
/// to indicate the rider's facing direction during an active delivery.
enum MapMarkerKind { rider, pickup, dropoff, generic }

/// An SDK-neutral marker the map abstraction can render.
///
/// Carries the SDK-neutral [point] plus presentation intent ([kind]) and, for
/// the directional rider marker, an optional [headingDegrees].
@immutable
class MapMarker {
  /// The SDK-neutral location of the marker.
  final GeoPoint point;

  /// The presentation intent of the marker.
  final MapMarkerKind kind;

  /// Heading in degrees, used by the [MapMarkerKind.rider] marker to indicate
  /// the rider's facing direction. Null when no heading is available.
  final double? headingDegrees;

  const MapMarker({
    required this.point,
    this.kind = MapMarkerKind.generic,
    this.headingDegrees,
  });

  @override
  bool operator ==(Object other) =>
      other is MapMarker &&
      other.point == point &&
      other.kind == kind &&
      other.headingDegrees == headingDegrees;

  @override
  int get hashCode => Object.hash(point, kind, headingDegrees);

  @override
  String toString() =>
      'MapMarker(point: $point, kind: $kind, headingDegrees: $headingDegrees)';
}
