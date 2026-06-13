import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../orders/data/orders_repository.dart';

class ActiveAssignmentNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  void set(Map<String, dynamic>? data) => state = data;
}

/// Holds the current incoming assignment data from WebSocket.
/// Set when `assignment:created` arrives, cleared after accept/reject/expire.
final activeAssignmentProvider = NotifierProvider<ActiveAssignmentNotifier, Map<String, dynamic>?>(() => ActiveAssignmentNotifier());

class ActiveOrderNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  void set(Map<String, dynamic>? data) => state = data;
}

/// Holds the full order data for the active delivery.
/// Set after accepting an assignment, cleared on delivery completion.
final activeOrderProvider = NotifierProvider<ActiveOrderNotifier, Map<String, dynamic>?>(() => ActiveOrderNotifier());

class PendingAssignmentNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  void set(Map<String, dynamic>? data) => state = data;
}

/// Buffers the latest incoming assignment payload so shell-level listeners
/// can react even if a screen-level stream listener temporarily disposes.
final pendingAssignmentProvider =
    NotifierProvider<PendingAssignmentNotifier, Map<String, dynamic>?>(
  () => PendingAssignmentNotifier(),
);

class LastPresentedAssignmentIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

/// Dedupes incoming-order popup presentation across socket + poll paths.
final lastPresentedAssignmentIdProvider =
    NotifierProvider<LastPresentedAssignmentIdNotifier, String?>(
  () => LastPresentedAssignmentIdNotifier(),
);

class LastAcceptedAssignmentIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? id) => state = id;
}

/// Tracks the most recently accepted assignment id to suppress stale re-prompts.
final lastAcceptedAssignmentIdProvider =
    NotifierProvider<LastAcceptedAssignmentIdNotifier, String?>(
  () => LastAcceptedAssignmentIdNotifier(),
);

class DeliveryStepNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int step) => state = step;
}

/// Tracks the current delivery step:
/// 0 = Arrived at restaurant (UI-only confirmation)
/// 1 = Confirm pickup (sends PICKED_UP)
/// 2 = On the way to customer (sends ON_THE_WAY)
/// 3 = At customer (proof-of-delivery / OTP)
final deliveryStepProvider = NotifierProvider<DeliveryStepNotifier, int>(() => DeliveryStepNotifier());

/// Fetches a single order by ID.
final orderDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final repo = ref.read(ordersRepositoryProvider);
  return repo.getOrder(orderId);
});
