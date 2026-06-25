import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/features/onboarding/presentation/screens/onboarding_screen.dart';

import 'helpers/test_harness.dart';

void main() {
  testWidgets('boots to splash then routes to onboarding', (tester) async {
    await pumpApp(tester);

    // First frame: the splash brand mark is visible.
    expect(find.text('WASABI'), findsOneWidget);

    // Advance past the splash's 1200ms bootstrap delay and the route
    // transition. With no onboarding flag set, it routes to onboarding
    // before any secure-storage access.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('WASABI'), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
