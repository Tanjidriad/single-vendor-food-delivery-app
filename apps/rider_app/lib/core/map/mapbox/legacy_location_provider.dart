import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../features/orders/presentation/providers/location_provider.dart';
import 'coordinate_conversions.dart';

/// DEPRECATED compatibility bridge for screens that still consume the rider
/// location as a Mapbox [Position].
///
/// The canonical location provider (`locationStreamProvider`) now exposes
/// SDK-neutral `GeoPoint` values, and `location_provider.dart` no longer
/// imports `mapbox_maps_flutter` (Requirement 10.4). This bridge lives in the
/// map implementation layer — the only place allowed to import Mapbox — and
/// adapts the neutral stream back to [Position] purely so the
/// not-yet-migrated screens keep compiling.
///
/// Remove this once `incoming_order_screen.dart` and
/// `active_delivery_screen.dart` are migrated to `GeoPoint`/`MapMarker`
/// (tasks 10.2 and 11.4); it must not be used by new code.
@Deprecated(
  'Use locationStreamProvider (GeoPoint) instead. This Position bridge exists '
  'only to keep the not-yet-migrated screens compiling and will be removed '
  'once the incoming/active delivery screens are migrated to GeoPoint.',
)
final currentLocationStreamProvider = StreamProvider<Position?>(
  (ref) => ref
      .watch(locationServiceProvider)
      .positionStream()
      .map<Position?>((point) => point.toPosition()),
);
