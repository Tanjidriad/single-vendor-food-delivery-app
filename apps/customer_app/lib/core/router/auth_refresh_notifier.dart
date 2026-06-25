import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Notifies [GoRouter] when auth token changes so redirects re-run.
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(this._ref) {
    _ref.listen<String?>(authTokenProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}

final authRefreshNotifierProvider = Provider<AuthRefreshNotifier>((ref) {
  final notifier = AuthRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
