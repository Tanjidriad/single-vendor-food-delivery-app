import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rider_app/app.dart';
import 'package:rider_app/core/config/api_host_resolver.dart';
import 'package:rider_app/features/auth/presentation/providers/auth_provider.dart';

/// Auth notifier that reports "not authenticated" without touching secure
/// storage or the network, so widget boots stay hermetic. The real
/// [AuthNotifier.build] kicks off an async `checkAuthStatus()` that hits secure
/// storage / the API; we skip that here.
class _UnauthenticatedAuthNotifier extends AuthNotifier {
  @override
  bool build() => false;

  // The real implementation calls checkAuthStatus() → secure storage / API.
  @override
  Future<void> ensureBootstrapped() async {}
}

/// Seeds the API/socket base URLs directly so [ApiHostResolver.init] — and its
/// real network probe — is never invoked in tests.
void seedApiHostResolver() {
  ApiHostResolver.apiBaseUrl = 'http://localhost:3000/api/v1';
  ApiHostResolver.socketBaseUrl = 'http://localhost:3000';
}

/// Pumps [RiderApp] inside a [ProviderScope] seeded for a hermetic boot
/// (no network, no secure storage), starting unauthenticated.
Future<void> pumpRiderApp(WidgetTester tester) async {
  seedApiHostResolver();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_UnauthenticatedAuthNotifier.new),
      ],
      child: const RiderApp(),
    ),
  );
}
