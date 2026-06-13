import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// One-time Mapbox SDK bootstrap.
///
/// Lives in the map implementation layer (`core/map/mapbox/`), the only place
/// allowed to import `mapbox_maps_flutter` (Requirement 10.4). It configures
/// the Mapbox access token so `main.dart` stays free of the SDK import. A
/// future migration to another map SDK would replace only this file (and its
/// invocation), leaving `main.dart` untouched.
void bootstrapMapbox() {
  const token = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  if (token.isEmpty) {
    throw StateError(
      'MAPBOX_ACCESS_TOKEN is not set. Pass it at build time: '
      'flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_TOKEN',
    );
  }
  MapboxOptions.setAccessToken(token);
}
