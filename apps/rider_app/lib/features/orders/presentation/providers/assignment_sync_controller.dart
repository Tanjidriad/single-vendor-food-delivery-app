import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../orders/data/orders_repository.dart';
import '../../../shift/presentation/providers/rider_online_controller.dart';
import 'order_providers.dart';

/// Drives REST recovery for missed `assignment:created` socket events.
final assignmentSyncControllerProvider =
    NotifierProvider<AssignmentSyncNotifier, AssignmentSyncState>(
  AssignmentSyncNotifier.new,
);

class AssignmentSyncState {
  final DateTime? lastSyncAt;
  final int lastPendingCount;

  const AssignmentSyncState({
    this.lastSyncAt,
    this.lastPendingCount = 0,
  });

  AssignmentSyncState copyWith({
    DateTime? lastSyncAt,
    int? lastPendingCount,
  }) {
    return AssignmentSyncState(
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastPendingCount: lastPendingCount ?? this.lastPendingCount,
    );
  }
}

class AssignmentSyncNotifier extends Notifier<AssignmentSyncState> {
  @override
  AssignmentSyncState build() => const AssignmentSyncState();

  bool get _canSync =>
      ref.read(isOnlineProvider) &&
      ref.read(activeOrderProvider) == null &&
      ref.read(activeAssignmentProvider) == null;

  /// Fetches pending offers from the API. Caller presents UI when idle.
  Future<List<Map<String, dynamic>>> syncNow() async {
    if (!_canSync) return [];

    final pending =
        await ref.read(ordersRepositoryProvider).fetchPendingAssignments();
    if (pending.isNotEmpty) {
      final ids = pending
          .map((e) => e['assignmentId']?.toString() ?? '<null>')
          .join(', ');
      debugPrint('[AssignTrace] sync pending ids=[$ids]');
    }

    state = state.copyWith(
      lastSyncAt: DateTime.now(),
      lastPendingCount: pending.length,
    );

    return pending;
  }
}
