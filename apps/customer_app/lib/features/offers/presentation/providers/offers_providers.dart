import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/data/orders_repository.dart';
import '../../../restaurant/data/restaurant_repository.dart';

final publicCouponsProvider = FutureProvider<List<dynamic>>((ref) async {
  final restaurantId = ref.watch(restaurantIdProvider);
  if (restaurantId == null) return [];
  return ref.watch(ordersRepositoryProvider).listPublicCoupons(restaurantId);
});
