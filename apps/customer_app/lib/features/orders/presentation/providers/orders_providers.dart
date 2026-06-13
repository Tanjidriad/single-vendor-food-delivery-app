import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/orders_repository.dart';

final ordersListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(ordersRepositoryProvider).listOrders();
});

final orderDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.watch(ordersRepositoryProvider).getOrder(id);
});

final activeOrderProvider = Provider<AsyncValue<Map<String, dynamic>?>>((ref) {
  final ordersAsync = ref.watch(ordersListProvider);
  return ordersAsync.whenData((orders) {
    for (final o in orders) {
      final order = o as Map<String, dynamic>;
      final status = order['status'] as String?;
      if (status != 'DELIVERED' && status != 'CANCELLED' && status != 'REJECTED' && status != 'IGNORED_TEST') {
        return order;
      }
    }
    return null;
  });
});
