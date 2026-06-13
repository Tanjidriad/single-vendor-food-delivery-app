import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/earnings_cache.dart';
import '../../../../core/websockets/socket_service.dart';
import '../../data/auth_repository.dart';
import '../../../earnings/presentation/providers/earnings_summary_provider.dart';
import '../../../orders/presentation/providers/active_order_restore.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../orders/presentation/providers/rider_orders_provider.dart';
import '../../../profile/presentation/providers/rider_profile_provider.dart';
import '../../../shift/presentation/providers/rider_online_controller.dart';

/// Holds auth state: null = loading, true = authenticated, false = not authenticated
final authProvider = NotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    _checkStatus();
    return false;
  }

  Future<void> _checkStatus() async {
    final status = await ref.read(authRepositoryProvider).checkAuthStatus();
    state = status;
    if (status) {
      await _syncOnlineStateFromServer();
      if (ref.read(isOnlineProvider)) {
        // Re-assert online so the backend retries dispatch for orders that were
        // accepted while this rider was unavailable (same as toggling GO).
        await _setRiderOnline(true);
        await _connectWebSocket();
      }
      await restoreActiveOrderSession(ref);
    }
  }

  Future<bool> login(String phone, String password) async {
    await ref.read(authRepositoryProvider).login(phone, password);
    state = true;

    // Mark online on the server before opening the realtime socket so dispatch
    // can target this rider and pending offers are recoverable via REST.
    final setOnlineOk = await _setRiderOnline(true);
    ref.read(isOnlineProvider.notifier).set(setOnlineOk);

    await _connectWebSocket();
    await restoreActiveOrderSession(ref);

    return true;
  }

  /// Logs the Rider out, surfacing failure to the caller (Requirements 8.5,
  /// 8.6).
  ///
  /// Returns `true` when the logout succeeds and the session has been ended
  /// (tokens cleared, [state] set to `false`). Returns `false` when the
  /// critical token-clearing step fails; in that case the session is RETAINED
  /// ([state] is left untouched) so the caller can keep the Rider signed in
  /// and surface an error.
  ///
  /// Setting the rider offline and disconnecting the socket are best-effort
  /// steps that already swallow their own errors; session validity hinges only
  /// on clearing the persisted tokens via [AuthRepository.logout].
  Future<bool> logout() async {
    // Best-effort: set rider offline before disconnecting.
    await _setRiderOnline(false);

    // Best-effort: disconnect WebSocket.
    ref.read(socketServiceProvider).disconnect();

    // Critical: clear tokens. If this fails, retain the session and signal
    // failure so the caller stays on the current screen (Requirement 8.6).
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (e) {
      debugPrint('Logout failed (session retained): $e');
      return false;
    }

    ref.read(activeOrderProvider.notifier).set(null);
    ref.read(activeAssignmentProvider.notifier).set(null);
    ref.read(deliveryStepProvider.notifier).set(0);

    // Clear local disk caches so next user doesn't see old data
    await EarningsCache().clearAll();

    // Invalidate cached Riverpod state
    ref.invalidate(earningsSummaryProvider);
    ref.invalidate(riderOrdersProvider);
    ref.invalidate(riderProfileProvider);

    state = false;
    return true;
  }

  Future<void> _connectWebSocket() async {
    try {
      await ref.read(socketServiceProvider).connect();
    } catch (e) {
      debugPrint('WebSocket connect failed: $e');
    }
  }

  /// Re-sync session after app resume (profile, online flag, socket).
  Future<void> refreshSessionAfterResume() async {
    if (!state) return;
    await _syncOnlineStateFromServer();
    if (ref.read(isOnlineProvider)) {
      await _setRiderOnline(true);
    }
    if (ref.read(isOnlineProvider)) {
      await _connectWebSocket();
    }
    if (ref.read(activeOrderProvider) == null) {
      await restoreActiveOrderSession(ref);
    }
  }

  Future<void> _syncOnlineStateFromServer() async {
    try {
      final res = await ref.read(apiClientProvider).get(ApiEndpoints.riderProfile);
      final data = res.data;
      final isOnline = data is Map && data['isOnline'] == true;
      ref.read(isOnlineProvider.notifier).set(isOnline);
    } catch (e) {
      // Be conservative: don't show online unless we verified it from backend.
      ref.read(isOnlineProvider.notifier).set(false);
      debugPrint('Failed to sync rider online state: $e');
    }
  }

  Future<bool> _setRiderOnline(bool online) async {
    try {
      await ref.read(apiClientProvider).patch(
        ApiEndpoints.riderOnline,
        data: {'isOnline': online},
      );
      return true;
    } catch (e) {
      debugPrint('Set rider online failed: $e');
      return false;
    }
  }
}
