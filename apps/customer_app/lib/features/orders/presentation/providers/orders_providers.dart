import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/order_model.dart';
import '../../data/orders_repository.dart';

final ordersListProvider = FutureProvider<List<OrderModel>>((ref) async {
  final orders = await ref.watch(ordersRepositoryProvider).listOrders();
  // Auto-refresh every 30s so the floating active-order card stays current
  final timer = Timer(const Duration(seconds: 30), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return orders;
});

final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, id) async {
  return ref.watch(ordersRepositoryProvider).getOrder(id);
});

final activeOrderProvider = Provider<AsyncValue<OrderModel?>>((ref) {
  final ordersAsync = ref.watch(ordersListProvider);
  return ordersAsync.whenData((orders) {
    for (final order in orders) {
      if (order.isActive) return order;
    }
    return null;
  });
});
