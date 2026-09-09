import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/websockets/socket_service.dart';

/// REAL-TIME PROOF (Flow #5): the reconnection *policy* that keeps a rider from
/// silently falling offline (missing assignment offers) — without churning the
/// connection when they deliberately log out or background the app.
void main() {
  group('reconnectBackoff — retry cadence', () {
    test('first retry waits 3s', () {
      expect(reconnectBackoff(0), const Duration(seconds: 3));
    });

    test('second retry waits 6s', () {
      expect(reconnectBackoff(1), const Duration(seconds: 6));
    });

    test('third and later retries cap at 15s (no runaway growth)', () {
      expect(reconnectBackoff(2), const Duration(seconds: 15));
      expect(reconnectBackoff(5), const Duration(seconds: 15));
      expect(reconnectBackoff(100), const Duration(seconds: 15));
    });

    test('delay never decreases as attempts grow (backs off, never speeds up)', () {
      var prev = Duration.zero;
      for (var attempt = 0; attempt < 12; attempt++) {
        final delay = reconnectBackoff(attempt);
        expect(delay >= prev, isTrue, reason: 'attempt $attempt regressed');
        prev = delay;
      }
    });
  });

  group('shouldScheduleReconnect — suppression policy', () {
    test('reconnects when active and foregrounded (the normal case)', () {
      expect(
        shouldScheduleReconnect(
          manualDisconnect: false,
          lifecycleAllowsReconnect: true,
        ),
        isTrue,
      );
    });

    test('does NOT reconnect after a manual disconnect (e.g. logout)', () {
      expect(
        shouldScheduleReconnect(
          manualDisconnect: true,
          lifecycleAllowsReconnect: true,
        ),
        isFalse,
      );
    });

    test('does NOT reconnect while the app is backgrounded', () {
      expect(
        shouldScheduleReconnect(
          manualDisconnect: false,
          lifecycleAllowsReconnect: false,
        ),
        isFalse,
      );
    });

    test('stays suppressed when both conditions block it', () {
      expect(
        shouldScheduleReconnect(
          manualDisconnect: true,
          lifecycleAllowsReconnect: false,
        ),
        isFalse,
      );
    });
  });
}
