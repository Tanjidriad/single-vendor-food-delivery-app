import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/orders_repository.dart';
import 'order_providers.dart';

/// Order statuses where the rider should resume the active delivery flow.
const _activeDeliveryStatuses = {
  'ACCEPTED',
  'PREPARING',
  'READY_FOR_PICKUP',
  'PICKED_UP',
  'ON_THE_WAY',
};

/// Maps persisted [order] status to the in-app delivery step indicator.
int deliveryStepForOrderStatus(String? status) {
  switch (status) {
    case 'ON_THE_WAY':
      return 3;
    case 'PICKED_UP':
      return 2;
    default:
      return 0;
  }
}

int _statusPriority(String status) {
  switch (status) {
    case 'ON_THE_WAY':
      return 5;
    case 'PICKED_UP':
      return 4;
    case 'READY_FOR_PICKUP':
      return 3;
    case 'PREPARING':
      return 2;
    case 'ACCEPTED':
      return 1;
    default:
      return 0;
  }
}

/// Rehydrates [activeOrderProvider] from the API after cold start / app restart.
///
/// [activeOrderProvider] is memory-only; [riderOrdersProvider] still shows the
/// same order on Current Orders — this keeps Home + Active Delivery in sync.
Future<void> restoreActiveOrderSession(Ref ref) async {
  if (ref.read(activeOrderProvider) != null) return;

  try {
    final repo = ref.read(ordersRepositoryProvider);
    final raw = await repo.listOrders(limit: 30);

    Map<String, dynamic>? candidate;
    var bestPriority = -1;

    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final status = map['status'] as String? ?? '';
      if (!_activeDeliveryStatuses.contains(status)) continue;

      final priority = _statusPriority(status);
      if (priority > bestPriority) {
        bestPriority = priority;
        candidate = map;
      }
    }

    if (candidate == null) return;

    final orderId = candidate['id'] as String?;
    if (orderId == null || orderId.isEmpty) return;

    final fullOrder = await repo.getOrder(orderId);
    final assignment = fullOrder['assignment'];
    final assignmentStatus = assignment is Map
        ? assignment['status']?.toString()
        : null;
    // Only restore when this rider has already accepted the assignment.
    // Otherwise a merely "NOTIFIED" offer can be mistaken as active delivery.
    if (assignmentStatus != 'ACCEPTED') {
      debugPrint(
        'Skip restore for order ${fullOrder['orderNumber']} (assignment status: $assignmentStatus)',
      );
      return;
    }
    ref.read(activeOrderProvider.notifier).set(fullOrder);
    ref.read(deliveryStepProvider.notifier).set(
          deliveryStepForOrderStatus(fullOrder['status'] as String?),
        );

    debugPrint('Restored active order ${fullOrder['orderNumber']} (${fullOrder['status']})');
  } catch (e) {
    debugPrint('Active order restore failed: $e');
  }
}

/// Runs once per authenticated session when the shell mounts.
final activeOrderRestoreProvider = FutureProvider<void>((ref) async {
  await restoreActiveOrderSession(ref);
});
