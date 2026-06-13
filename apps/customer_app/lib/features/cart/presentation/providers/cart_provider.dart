import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/local_storage/storage_utility.dart';
import '../../domain/entities/cart_item.dart';

class CartState {
  const CartState({this.items = const [], this.couponCode, this.discount = 0});

  final List<CartItem> items;
  final String? couponCode;
  final double discount;

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);
  double get subtotal => items.fold(0, (s, i) => s + i.lineTotal);

  CartState copyWith({
    List<CartItem>? items,
    String? couponCode,
    double? discount,
  }) =>
      CartState(
        items: items ?? this.items,
        couponCode: couponCode ?? this.couponCode,
        discount: discount ?? this.discount,
      );
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._storage) : super(const CartState()) {
    _load();
  }

  final LocalStorage _storage;
  static const _key = 'cart_v1';

  Future<void> _load() async {
    final raw = _storage.readString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = list.map((e) {
        final m = e as Map<String, dynamic>;
        return CartItem(
          menuItemId: m['menuItemId'] as String,
          name: m['name'] as String,
          unitPrice: (m['unitPrice'] as num).toDouble(),
          quantity: m['quantity'] as int,
          imageUrl: m['imageUrl'] as String?,
          notes: m['notes'] as String?,
          addons: (m['addons'] as List<dynamic>? ?? [])
              .map((a) => CartAddon.fromJson(a as Map<String, dynamic>))
              .toList(),
        );
      }).toList();
      state = state.copyWith(items: items);
    } catch (_) {}
  }

  Future<void> _persist() async {
    final data = state.items
        .map((i) => {
              'menuItemId': i.menuItemId,
              'name': i.name,
              'unitPrice': i.unitPrice,
              'quantity': i.quantity,
              'imageUrl': i.imageUrl,
              'notes': i.notes,
              'addons': i.addons.map((a) => a.toJson()).toList(),
            })
        .toList();
    await _storage.writeString(_key, jsonEncode(data));
  }

  void addItem(CartItem item) {
    final idx = state.items.indexWhere((i) =>
        i.menuItemId == item.menuItemId &&
        i.notes == item.notes &&
        _addonsKey(i.addons) == _addonsKey(item.addons));
    List<CartItem> next;
    if (idx >= 0) {
      next = [...state.items];
      next[idx] = next[idx].copyWith(quantity: next[idx].quantity + item.quantity);
    } else {
      next = [...state.items, item];
    }
    state = state.copyWith(items: next);
    _persist();
  }

  String _addonsKey(List<CartAddon> addons) =>
      addons.map((a) => a.addonId).join(',');

  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }
    state = state.copyWith(
      items: state.items
          .map((i) => i.menuItemId == menuItemId ? i.copyWith(quantity: quantity) : i)
          .toList(),
    );
    _persist();
  }

  void removeItem(String menuItemId) {
    state = state.copyWith(
      items: state.items.where((i) => i.menuItemId != menuItemId).toList(),
    );
    _persist();
  }

  void setCoupon(String? code, double discount) {
    state = CartState(
      items: state.items,
      couponCode: code,
      discount: discount,
    );
  }

  void clear() {
    state = const CartState();
    _storage.remove(_key);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.watch(localStorageProvider));
});
