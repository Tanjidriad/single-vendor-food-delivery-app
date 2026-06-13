import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/order_summary.dart';
import '../../data/orders_repository.dart';

/// Fetches the rider's orders (paginated list) and parses them into typed
/// [OrderSummary] values. Shared by the Current Orders and History screens,
/// which filter the same list by active vs terminal status.
final riderOrdersProvider = FutureProvider<List<OrderSummary>>((ref) async {
  final repo = ref.watch(ordersRepositoryProvider);
  final raw = await repo.listOrders(limit: 50);
  return raw
      .whereType<Map>()
      .map((m) => OrderSummary.fromJson(Map<String, dynamic>.from(m)))
      .toList();
});

/// Active (non-terminal) orders for the Current Orders screen.
final currentOrdersProvider = Provider<AsyncValue<List<OrderSummary>>>((ref) {
  return ref.watch(riderOrdersProvider).whenData(
        (orders) => orders.where((o) => o.isActive).toList(),
      );
});

/// Delivered/cancelled orders for the History screen.
final pastOrdersProvider = Provider<AsyncValue<List<OrderSummary>>>((ref) {
  return ref.watch(riderOrdersProvider).whenData(
        (orders) => orders.where((o) => !o.isActive).toList(),
      );
});
