import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/features/menu/widgets/menu_featured_banner.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the featured item and fires onAddToBag', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(MenuFeaturedBanner(
      name: 'Signature Burger',
      description: 'House special',
      price: 12.5,
      onAddToBag: () => tapped = true,
    )));

    expect(find.text('FEATURED'), findsOneWidget);
    expect(find.text('Signature Burger'), findsOneWidget);
    expect(find.text('House special'), findsOneWidget);

    await tester.tap(find.text('ADD TO BAG'));
    expect(tapped, isTrue);
  });

  testWidgets('hides the description when empty', (tester) async {
    await tester.pumpWidget(wrap(const MenuFeaturedBanner(
      name: 'Plain',
      description: '',
      price: 5,
      onAddToBag: null,
    )));

    expect(find.text('Plain'), findsOneWidget);
    expect(find.text('FEATURED'), findsOneWidget);
  });
}
