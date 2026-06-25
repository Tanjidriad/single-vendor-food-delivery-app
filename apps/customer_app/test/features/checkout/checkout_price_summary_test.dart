import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/features/cart/domain/entities/cart_item.dart';
import 'package:customer_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:customer_app/features/checkout/presentation/widgets/checkout_price_summary.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  const cart = CartState(
    items: [
      CartItem(menuItemId: 'm1', name: 'Burger', unitPrice: 10, quantity: 2),
    ],
  );

  testWidgets('renders line items and the standard summary rows', (tester) async {
    await tester.pumpWidget(wrap(const CheckoutPriceSummary(
      cart: cart,
      deliveryFee: 5,
      tax: null,
      packaging: null,
      quoteLoading: false,
      total: 25,
    )));

    expect(find.text('2x Burger'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Delivery Fee'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    // No discount row when there is no discount.
    expect(find.text('Discount'), findsNothing);
  });

  testWidgets('shows "Calculating…" while the quote is loading', (tester) async {
    await tester.pumpWidget(wrap(const CheckoutPriceSummary(
      cart: cart,
      deliveryFee: null,
      tax: null,
      packaging: null,
      quoteLoading: true,
      total: 20,
    )));

    expect(find.text('Calculating…'), findsOneWidget);
  });

  testWidgets('shows a discount row when the cart is discounted', (tester) async {
    const discounted = CartState(
      items: [
        CartItem(menuItemId: 'm1', name: 'Burger', unitPrice: 10, quantity: 2),
      ],
      discount: 3,
    );

    await tester.pumpWidget(wrap(const CheckoutPriceSummary(
      cart: discounted,
      deliveryFee: 5,
      tax: null,
      packaging: null,
      quoteLoading: false,
      total: 22,
    )));

    expect(find.text('Discount'), findsOneWidget);
  });
}
