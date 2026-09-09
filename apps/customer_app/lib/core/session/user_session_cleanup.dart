import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cart/presentation/providers/cart_provider.dart';
import '../../features/favorites/presentation/providers/favorites_provider.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../features/orders/presentation/providers/orders_providers.dart';
import '../../features/profile/presentation/providers/addresses_providers.dart';
import '../../features/profile/presentation/providers/checkout_address_provider.dart';

/// Clears in-memory and cached data that belongs to the previous account.
void clearUserScopedData(Ref ref) {
  ref.read(cartProvider.notifier).clear();
  ref.read(selectedCheckoutAddressProvider.notifier).state = null;

  ref.invalidate(addressesListProvider);
  ref.invalidate(favoritesListProvider);
  ref.invalidate(favoriteMenuItemIdsProvider);
  ref.invalidate(ordersListProvider);
  ref.invalidate(orderDetailProvider);
  ref.invalidate(notificationsProvider);
}
