import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/config/api_host_resolver.dart';
import 'core/map/mapbox/mapbox_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bootstrapFlutterApp();
  bootstrapMapbox();
  final prefs = await SharedPreferences.getInstance();
  await ApiHostResolver.init(prefs);

  runApp(
    const ProviderScope(
      child: RiderApp(),
    ),
  );
}
