import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/websockets/socket_service.dart';

/// Holds the rider's shift availability (Online_Status).
///
/// This is the single source of truth for whether the rider is online, read by
/// the home screen and the GO control. The [RiderOnlineController] is the only
/// thing that should flip it during a toggle, and it does so *after* the
/// rider-online request succeeds (Requirement 2.3).
class IsOnlineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isOnlineProvider =
    NotifierProvider<IsOnlineNotifier, bool>(() => IsOnlineNotifier());

/// Observable view-state for the GO control while a toggle is processed.
///
/// [isLoading] is true while a rider-online request is in flight (used to show
/// a loading indicator and to ignore re-entrant activations — Requirement 2.4).
/// [error] carries a user-facing message when the last request failed
/// (Requirement 2.5); it is `null` while there is no error.
@immutable
class RiderOnlineState {
  final bool isLoading;
  final String? error;

  const RiderOnlineState({this.isLoading = false, this.error});

  RiderOnlineState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RiderOnlineState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RiderOnlineState &&
      other.isLoading == isLoading &&
      other.error == error;

  @override
  int get hashCode => Object.hash(isLoading, error);

  @override
  String toString() => 'RiderOnlineState(isLoading: $isLoading, error: $error)';
}

/// Encapsulates the rider online/offline toggle, preserving the
/// request-before-state network sequencing that the GO control relies on.
///
/// Properties guaranteed (see design Correctness Properties 2-5):
/// - The `PATCH /users/rider/online` request is issued **before**
///   [isOnlineProvider] is mutated (Property 2 / Req 2.2).
/// - On success, [isOnlineProvider] ends equal to the target status
///   (Property 3 / Req 2.3).
/// - While a request is in flight, further activations are ignored so exactly
///   one request is issued for N re-entrant activations (Property 4 / Req 2.4).
/// - On failure, [isOnlineProvider] is left unchanged and an error is surfaced
///   via [RiderOnlineState.error] (Property 5 / Req 2.5).
///
/// The API client is obtained from [apiClientProvider], so tests can override
/// that provider with an ordering/counting mock to observe the sequencing.
class RiderOnlineController extends Notifier<RiderOnlineState> {
  @override
  RiderOnlineState build() => const RiderOnlineState();

  /// Sends [target] to the rider-online endpoint and, on success, updates
  /// [isOnlineProvider]. Re-entrant calls while a request is in flight are
  /// ignored (Requirement 2.4).
  Future<void> setOnline(bool target) async {
    // Property 4 / Req 2.4: ignore activations while a request is in flight.
    // The loading flag is set synchronously below before the first await, so
    // any synchronous re-entrant calls observe it and return early.
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Property 2 / Req 2.2: issue the request BEFORE mutating isOnlineProvider.
      await ref.read(apiClientProvider).patch(
        ApiEndpoints.riderOnline,
        data: {'isOnline': target},
      );
      // Property 3 / Req 2.3: on success, set the status to the target.
      ref.read(isOnlineProvider.notifier).set(target);
      if (target) {
        final socket = ref.read(socketServiceProvider);
        if (!socket.isConnected) {
          await socket.connect();
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Property 5 / Req 2.5: retain the previous status and surface the error.
      // isOnlineProvider is intentionally left untouched here.
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Toggles availability to the opposite of the current [isOnlineProvider]
  /// value, following the same sequencing guarantees as [setOnline].
  Future<void> toggle() => setOnline(!ref.read(isOnlineProvider));

  /// Clears any surfaced error (e.g. after it has been shown to the rider).
  void clearError() => state = state.copyWith(clearError: true);
}

final riderOnlineControllerProvider =
    NotifierProvider<RiderOnlineController, RiderOnlineState>(
  () => RiderOnlineController(),
);
