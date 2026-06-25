import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app.dart';
import 'package:customer_app/core/config/api_host_resolver.dart';
import 'package:customer_app/core/utils/helpers/network_manager.dart';
import 'package:customer_app/core/utils/local_storage/storage_utility.dart';
import 'package:customer_app/features/force_update/presentation/providers/app_update_provider.dart';

/// Connectivity that never touches the platform channel. The real
/// [NetworkConnectivity.startListening] subscribes to an EventChannel that
/// throws under the test binding; this no-op keeps widget boots clean.
class _NoopNetworkConnectivity extends NetworkConnectivity {
  _NoopNetworkConnectivity() : super(Connectivity());

  @override
  Future<void> startListening(BuildContext context) async {}

  @override
  Future<bool> isConnected() async => true;
}

/// Seeds the API/socket base URLs directly so [ApiHostResolver.init] — and its
/// real `dio.get('…/health')` network probe — is never invoked in tests.
void seedApiHostResolver() {
  ApiHostResolver.apiBaseUrl = 'http://localhost:3000/api/v1';
  ApiHostResolver.socketBaseUrl = 'http://localhost:3000';
}

/// Pumps [CustomerApp] with the overrides every widget test needs:
/// a mocked SharedPreferences and a no-op connectivity listener.
///
/// [prefs] seeds SharedPreferences; pass extra Riverpod [overrides] as needed.
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  List<Override> overrides = const [],
}) async {
  seedApiHostResolver();
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        networkConnectivityProvider.overrideWithValue(_NoopNetworkConnectivity()),
        // No real network/version probe in widget tests (would hang fake-async).
        appUpdateProvider.overrideWith((ref) async => AppUpdateStatus.none),
        ...overrides,
      ],
      child: const CustomerApp(),
    ),
  );
}
