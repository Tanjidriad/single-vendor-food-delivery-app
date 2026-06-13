import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'addresses_providers.dart';

/// Delivery address chosen for the current checkout session.
final selectedCheckoutAddressProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// Selected address, or default/first saved address from the API.
final checkoutAddressProvider = Provider<Map<String, dynamic>?>((ref) {
  final selected = ref.watch(selectedCheckoutAddressProvider);
  if (selected != null) return selected;

  final addresses = ref.watch(addressesListProvider).valueOrNull;
  if (addresses == null || addresses.isEmpty) return null;

  for (final a in addresses) {
    final map = a as Map<String, dynamic>;
    if (map['isDefault'] == true) return map;
  }
  return addresses.first as Map<String, dynamic>;
});
