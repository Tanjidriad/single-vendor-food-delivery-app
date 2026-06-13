import 'package:geolocator/geolocator.dart' as geo;

import '../geo_point.dart';
import '../location_service.dart';

/// Geolocator-backed implementation of [LocationService].
///
/// Wraps the device geolocation logic previously embedded in
/// `location_provider.dart`, returning SDK-neutral [GeoPoint] values so that
/// callers never depend on a map/geolocation SDK type (Requirement 10.1).
///
/// It lives in the map implementation layer (`core/map/mapbox/`) per the map
/// abstraction's containment rule, but it does NOT import
/// `mapbox_maps_flutter`: device positions come from the `geolocator` package
/// and are exposed as [GeoPoint].
///
/// The original Dhaka-center fallback behavior is preserved (Requirement
/// 10.4): when location services are disabled, permission is denied, or a
/// position cannot be obtained in time, the service degrades to a fixed
/// fallback coordinate rather than failing.
class GeolocatorLocationService implements LocationService {
  /// Fallback coordinate (Dhaka city center) used when a real device position
  /// cannot be determined. Preserves the previous provider's behavior.
  static const GeoPoint _fallback =
      GeoPoint(latitude: 23.8103, longitude: 90.4125);

  /// How long to wait for an initial fix before falling back.
  static const Duration _fixTimeout = Duration(seconds: 5);

  /// Settings for the live position stream.
  static const geo.LocationSettings _streamSettings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.high,
    distanceFilter: 10,
  );

  const GeolocatorLocationService();

  @override
  Future<GeoPoint?> currentPosition() async {
    try {
      if (!await _ensurePermitted()) {
        return _fallback;
      }

      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings:
            const geo.LocationSettings(timeLimit: _fixTimeout),
      );
      return _toGeoPoint(pos);
    } catch (_) {
      // Service errors, permission races, or a timeout all degrade to the
      // fallback so callers always get a usable coordinate.
      return _fallback;
    }
  }

  @override
  Stream<GeoPoint> positionStream() async* {
    // Resolve permission/service availability up front. If unavailable, emit
    // the fallback once and stop, matching the previous provider.
    bool permitted;
    try {
      permitted = await _ensurePermitted();
    } catch (_) {
      yield _fallback;
      return;
    }

    if (!permitted) {
      yield _fallback;
      return;
    }

    // Emit an initial position first for a faster UI response, falling back if
    // the initial fix fails or times out.
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings:
            const geo.LocationSettings(timeLimit: _fixTimeout),
      );
      yield _toGeoPoint(pos);
    } catch (_) {
      yield _fallback;
    }

    // Then follow the live stream of device positions.
    yield* geo.Geolocator.getPositionStream(locationSettings: _streamSettings)
        .map(_toGeoPoint);
  }

  /// Ensures location services are enabled and permission is granted,
  /// requesting it once if currently denied. Returns `true` only when a real
  /// position can be requested; `false` means callers should use the fallback.
  Future<bool> _ensurePermitted() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        return false;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  GeoPoint _toGeoPoint(geo.Position pos) =>
      GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
}
