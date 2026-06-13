import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/map/geo_point.dart';
import '../../../../core/map/location_service.dart';
import '../../../../core/map/mapbox/geolocator_location_service.dart';

/// Provides the [LocationService] implementation used to obtain device
/// positions as SDK-neutral [GeoPoint] values.
///
/// The concrete [GeolocatorLocationService] lives in the map implementation
/// layer and keeps geolocation/SDK details out of this provider, so callers
/// never depend on a map-SDK coordinate type (Requirement 10.1).
final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

/// A stream of the rider's live device position as SDK-neutral [GeoPoint]
/// values.
///
/// Backed by [locationServiceProvider]; it emits an initial fix as soon as it
/// is available and then follows live updates. The Dhaka-center fallback
/// behavior is preserved inside the service (Requirement 10.4).
final locationStreamProvider = StreamProvider<GeoPoint>(
  (ref) => ref.watch(locationServiceProvider).positionStream(),
);

/// The rider's current device position as an SDK-neutral [GeoPoint], or the
/// fallback coordinate when a real position cannot be determined.
final currentLocationProvider = FutureProvider<GeoPoint?>(
  (ref) => ref.watch(locationServiceProvider).currentPosition(),
);
