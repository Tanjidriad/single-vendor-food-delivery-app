import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/config/api_host_resolver.dart';
import 'core/utils/local_storage/storage_utility.dart';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bootstrapFlutterApp();
  final prefs = await SharedPreferences.getInstance();
  await ApiHostResolver.init(prefs);

  const mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  if (mapboxToken.isEmpty) {
    throw StateError(
      'MAPBOX_ACCESS_TOKEN is not set. Pass it at build time: '
      'flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_TOKEN',
    );
  }
  MapboxOptions.setAccessToken(mapboxToken);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CustomerApp(),
    ),
  );
}
