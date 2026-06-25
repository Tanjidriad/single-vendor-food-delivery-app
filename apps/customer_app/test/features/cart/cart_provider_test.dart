import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/core/utils/local_storage/storage_utility.dart';
import 'package:customer_app/features/cart/domain/entities/cart_item.dart';
import 'package:customer_app/features/cart/presentation/providers/cart_provider.dart';

CartItem _item({
  String id = 'm1',
  double price = 10,
  int qty = 1,
  String? notes,
  List<CartAddon> addons = const [],
}) =>
    CartItem(
      menuItemId: id,
      name: 'Item $id',
      unitPrice: price,
      quantity: qty,
      notes: notes,
      addons: addons,
    );

void main() {
  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
  });

  test('starts empty', () {
    final cart = CartNotifier(storage);
    expect(cart.state.items, isEmpty);
    expect(cart.state.itemCount, 0);
    expect(cart.state.subtotal, 0);
  });

  test('addItem adds a line and computes totals', () {
    final cart = CartNotifier(storage)..addItem(_item(price: 10, qty: 2));
    expect(cart.state.itemCount, 2);
    expect(cart.state.subtotal, 20);
  });

  test('subtotal includes addon prices', () {
    final cart = CartNotifier(storage)
      ..addItem(_item(
        price: 10,
        qty: 2,
        addons: const [CartAddon(addonId: 'a1', name: 'Cheese', price: 2.5)],
      ));
    expect(cart.state.subtotal, (10 + 2.5) * 2);
  });

  test('addItem merges identical lines by id/notes/addons', () {
    final cart = CartNotifier(storage)
      ..addItem(_item(qty: 1))
      ..addItem(_item(qty: 2));
    expect(cart.state.items, hasLength(1));
    expect(cart.state.items.single.quantity, 3);
  });

  test('addItem keeps distinct lines when notes differ', () {
    final cart = CartNotifier(storage)
      ..addItem(_item(notes: 'no onion'))
      ..addItem(_item(notes: 'extra spicy'));
    expect(cart.state.items, hasLength(2));
  });

  test('updateQuantity sets the quantity', () {
    final cart = CartNotifier(storage)..addItem(_item(qty: 1));
    cart.updateQuantity('m1', 5);
    expect(cart.state.items.single.quantity, 5);
  });

  test('updateQuantity to zero removes the line', () {
    final cart = CartNotifier(storage)..addItem(_item(qty: 1));
    cart.updateQuantity('m1', 0);
    expect(cart.state.items, isEmpty);
  });

  test('removeItem removes the matching line', () {
    final cart = CartNotifier(storage)
      ..addItem(_item(id: 'a'))
      ..addItem(_item(id: 'b'));
    cart.removeItem('a');
    expect(cart.state.items.single.menuItemId, 'b');
  });

  test('setCoupon stores code and discount', () {
    final cart = CartNotifier(storage)..addItem(_item());
    cart.setCoupon('SAVE10', 5);
    expect(cart.state.couponCode, 'SAVE10');
    expect(cart.state.discount, 5);
  });

  test('clear empties the cart', () {
    final cart = CartNotifier(storage)..addItem(_item());
    cart.clear();
    expect(cart.state.items, isEmpty);
  });

  test('persists items across notifier instances', () {
    CartNotifier(storage).addItem(_item(id: 'x', price: 8, qty: 2));

    final reloaded = CartNotifier(storage);
    expect(reloaded.state.items, hasLength(1));
    expect(reloaded.state.items.single.menuItemId, 'x');
    expect(reloaded.state.items.single.quantity, 2);
    expect(reloaded.state.subtotal, 16);
  });
}
