import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Creates a container with [localStorageProvider] overridden so the cart
  /// persists to the in-memory mock, and disposes it after the test.
  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts empty', () {
    final c = makeContainer();
    final cart = c.read(cartProvider);
    expect(cart.items, isEmpty);
    expect(cart.itemCount, 0);
    expect(cart.subtotal, 0);
  });

  test('addItem adds a line and computes totals', () {
    final c = makeContainer();
    c.read(cartProvider.notifier).addItem(_item(price: 10, qty: 2));
    expect(c.read(cartProvider).itemCount, 2);
    expect(c.read(cartProvider).subtotal, 20);
  });

  test('subtotal includes addon prices', () {
    final c = makeContainer();
    c.read(cartProvider.notifier).addItem(_item(
          price: 10,
          qty: 2,
          addons: const [CartAddon(addonId: 'a1', name: 'Cheese', price: 2.5)],
        ));
    expect(c.read(cartProvider).subtotal, (10 + 2.5) * 2);
  });

  test('addItem merges identical lines by id/notes/addons', () {
    final c = makeContainer();
    c.read(cartProvider.notifier)
      ..addItem(_item(qty: 1))
      ..addItem(_item(qty: 2));
    expect(c.read(cartProvider).items, hasLength(1));
    expect(c.read(cartProvider).items.single.quantity, 3);
  });

  test('addItem keeps distinct lines when notes differ', () {
    final c = makeContainer();
    c.read(cartProvider.notifier)
      ..addItem(_item(notes: 'no onion'))
      ..addItem(_item(notes: 'extra spicy'));
    expect(c.read(cartProvider).items, hasLength(2));
  });

  test('updateQuantity sets the quantity', () {
    final c = makeContainer();
    c.read(cartProvider.notifier)
      ..addItem(_item(qty: 1))
      ..updateQuantity('m1', 5);
    expect(c.read(cartProvider).items.single.quantity, 5);
  });

  test('updateQuantity to zero removes the line', () {
    final c = makeContainer();
    c.read(cartProvider.notifier)
      ..addItem(_item(qty: 1))
      ..updateQuantity('m1', 0);
    expect(c.read(cartProvider).items, isEmpty);
  });

  test('removeItem removes the matching line', () {
    final c = makeContainer();
    c.read(cartProvider.notifier)
      ..addItem(_item(id: 'a'))
      ..addItem(_item(id: 'b'))
      ..removeItem('a');
    expect(c.read(cartProvider).items.single.menuItemId, 'b');
  });

  test('setCoupon stores code and discount', () {
    final c = makeContainer();
    c.read(cartProvider.notifier)
      ..addItem(_item())
      ..setCoupon('SAVE10', 5);
    expect(c.read(cartProvider).couponCode, 'SAVE10');
    expect(c.read(cartProvider).discount, 5);
  });

  test('clear empties the cart', () {
    final c = makeContainer();
    c.read(cartProvider.notifier)
      ..addItem(_item())
      ..clear();
    expect(c.read(cartProvider).items, isEmpty);
  });

  test('persists items across containers', () {
    final c1 = makeContainer();
    c1.read(cartProvider.notifier).addItem(_item(id: 'x', price: 8, qty: 2));

    // A fresh container backed by the same storage restores the saved cart.
    final c2 = makeContainer();
    final cart = c2.read(cartProvider);
    expect(cart.items, hasLength(1));
    expect(cart.items.single.menuItemId, 'x');
    expect(cart.items.single.quantity, 2);
    expect(cart.subtotal, 16);
  });
}
