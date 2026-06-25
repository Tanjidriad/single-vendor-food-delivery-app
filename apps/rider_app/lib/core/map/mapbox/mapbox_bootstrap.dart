import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void bootstrapMapbox() {
  const envToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  final token = envToken.isNotEmpty
      ? envToken
      : (kDebugMode && dotenv.isInitialized) ? dotenv.env['MAPBOX_ACCESS_TOKEN'] : null;
  if (token == null || token.isEmpty) {
    throw StateError(
      'MAPBOX_ACCESS_TOKEN is not set. Pass --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxx '
      'or add it to apps/rider_app/.env in debug mode.',
    );
  }
  MapboxOptions.setAccessToken(token);
}
