import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../geo_point.dart';

/// Conversions between the SDK-neutral [GeoPoint] and Mapbox's [Position].
///
/// This is the ONLY place allowed to import `mapbox_maps_flutter` for the
/// purpose of coordinate conversion (Requirement 10.5). Mapbox orders its
/// [Position] as `(longitude, latitude)` — the opposite of the lat/lng order
/// most callers expect. Encapsulating that axis ordering here keeps the
/// footgun out of screens, providers, and the rest of the app.

/// Converts an SDK-neutral [GeoPoint] into a Mapbox [Position].
extension GeoPointMapbox on GeoPoint {
  /// Returns a Mapbox [Position] with the correct `(longitude, latitude)`
  /// axis ordering.
  Position toPosition() => Position(longitude, latitude);
}

/// Converts a Mapbox [Position] into an SDK-neutral [GeoPoint].
extension PositionGeoPoint on Position {
  /// Returns a [GeoPoint], reading longitude/latitude back from the Mapbox
  /// `(longitude, latitude)` axis ordering. Mapbox stores these as `num`, so
  /// they are narrowed to `double` here.
  GeoPoint toGeoPoint() =>
      GeoPoint(latitude: lat.toDouble(), longitude: lng.toDouble());
}
