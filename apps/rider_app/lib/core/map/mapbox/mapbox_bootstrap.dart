import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// One-time Mapbox SDK bootstrap.
///
/// Lives in the map implementation layer (`core/map/mapbox/`), the only place
/// allowed to import `mapbox_maps_flutter` (Requirement 10.4). It configures
/// the Mapbox access token so `main.dart` stays free of the SDK import. A
/// future migration to another map SDK would replace only this file (and its
/// invocation), leaving `main.dart` untouched.
void bootstrapMapbox() {
  final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
  if (token == null || token.isEmpty) {
    throw StateError(
      'MAPBOX_ACCESS_TOKEN is not set. Add it to apps/rider_app/.env '
      '(copy from .env.example)',
    );
  }
  MapboxOptions.setAccessToken(token);
}
