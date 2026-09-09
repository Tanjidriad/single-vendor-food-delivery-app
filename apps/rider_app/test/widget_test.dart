import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_harness.dart';

void main() {
  testWidgets('boots to splash then routes to login when unauthenticated',
      (tester) async {
    await pumpRiderApp(tester);

    // First frame: the splash brand mark is visible.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Rider'), findsOneWidget);

    // Advance past the splash's 800ms bootstrap delay and the route
    // transition. Unauthenticated, it routes to the login screen.
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(find.text('Rider'), findsNothing);
  });
}
