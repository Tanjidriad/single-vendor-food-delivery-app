import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/websockets/socket_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shift/presentation/providers/rider_online_controller.dart';
import 'assignment_sync_controller.dart';
import 'order_providers.dart';

/// Subscribes to assignment socket events as soon as the rider is authenticated,
/// before [HomeShell] mounts — so offers are not lost on a broadcast stream.
///
/// Uses raw stream subscriptions (not Riverpod StreamProviders) to avoid
/// equality-based deduplication that swallows repeated void emissions.
final assignmentBridgeProvider = Provider<void>((ref) {
  if (!ref.watch(authProvider)) return;

  debugPrint('[AssignBridge] provider CREATED — setting up listeners');

  final socket = ref.read(socketServiceProvider);

  // --- 1. Listen for assignment:created socket events ---
  final assignmentSub = socket.assignmentCreatedStream.listen((data) {
    debugPrint(
      '[AssignBridge] SOCKET EVENT assignmentId=${data['assignmentId']}',
    );
    ref.read(pendingAssignmentProvider.notifier).set(data);
  });

  // --- 2. On every socket connect/reconnect, pull pending from REST ---
  final connectedSub = socket.connectedStream.listen((_) {
    debugPrint('[AssignBridge] socket connected — pulling pending');
    unawaited(_pullPendingOffers(ref));
  });

  // --- 3. When rider goes online, pull pending ---
  ref.listen(isOnlineProvider, (previous, next) {
    debugPrint('[AssignBridge] isOnline changed: $previous → $next');
    if (next && previous != next) {
      unawaited(_pullPendingOffers(ref));
    }
  });

  // --- 4. Periodic REST safety net (every 8s while idle) ---
  var pollCount = 0;
  final pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
    pollCount++;
    final online = ref.read(isOnlineProvider);
    final hasOrder = ref.read(activeOrderProvider) != null;
    final hasAssignment = ref.read(activeAssignmentProvider) != null;
    if (!online || hasOrder || hasAssignment) {
      if (pollCount <= 3 || pollCount % 10 == 0) {
        debugPrint(
          '[AssignBridge] poll #$pollCount SKIP (online=$online order=$hasOrder assignment=$hasAssignment)',
        );
      }
      return;
    }
    debugPrint('[AssignBridge] poll #$pollCount — calling REST');
    _pullPendingOffers(ref);
  });

  // --- 5. Initial pull on provider creation ---
  Future.microtask(() {
    final online = ref.read(isOnlineProvider);
    debugPrint('[AssignBridge] initial microtask — online=$online');
    if (online) {
      _pullPendingOffers(ref);
    }
  });

  ref.onDispose(() {
    debugPrint('[AssignBridge] DISPOSED');
    assignmentSub.cancel();
    connectedSub.cancel();
    pollTimer.cancel();
  });
});

Future<void> _pullPendingOffers(Ref ref) async {
  try {
    final online = ref.read(isOnlineProvider);
    final hasOrder = ref.read(activeOrderProvider) != null;
    final hasAssignment = ref.read(activeAssignmentProvider) != null;
    if (!online || hasOrder || hasAssignment) {
      debugPrint(
        '[AssignBridge] pullPending SKIP (online=$online order=$hasOrder assignment=$hasAssignment)',
      );
      return;
    }

    debugPrint('[AssignBridge] pullPending calling syncNow()...');
    final pending =
        await ref.read(assignmentSyncControllerProvider.notifier).syncNow();
    debugPrint('[AssignBridge] pullPending result: ${pending.length} items');

    if (pending.isEmpty) return;

    final first = pending.first;
    debugPrint(
      '[AssignBridge] setting pendingAssignment: id=${first['assignmentId']} order=${first['orderId']}',
    );
    ref.read(pendingAssignmentProvider.notifier).set(first);
  } catch (e) {
    debugPrint('[AssignBridge] pullPending ERROR: $e');
  }
}
