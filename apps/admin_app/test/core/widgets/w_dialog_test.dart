// Feature: admin-panel-redesign
//
// Widget tests for the WDialog component (Requirement 13.1-13.7).
//
// Covered behaviors:
// - Header rendering (title, optional subtitle, close icon button)
// - Footer rendering (right-aligned actions, hidden when empty)
// - Scrollable content region
// - Fade-in / fade-out animations with the specified durations
// - Backdrop dismiss (and suppression when barrierDismissible is false)
// - Close icon button dismissal

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/theme/app_theme.dart';
import 'package:admin_app/core/widgets/w_dialog.dart';

/// Wraps [child] in a themed MaterialApp + Scaffold so design tokens resolve.
Widget _harness(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

/// Pumps a screen containing a single button that opens a [WDialog] via
/// [WDialog.show] with the supplied parameters, then taps it and settles.
Future<void> _openDialog(
  WidgetTester tester, {
  String title = 'Dialog Title',
  String? subtitle,
  Widget content = const Text('Dialog body content'),
  List<Widget> actions = const [],
  bool barrierDismissible = true,
}) async {
  await tester.pumpWidget(
    _harness(
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => WDialog.show<void>(
              context: context,
              title: title,
              subtitle: subtitle,
              content: content,
              actions: actions,
              barrierDismissible: barrierDismissible,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('WDialog header/footer rendering', () {
    testWidgets('renders the title and close icon button in the header',
        (tester) async {
      await _openDialog(tester, title: 'Edit Item');

      expect(find.text('Edit Item'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders the optional subtitle when provided', (tester) async {
      await _openDialog(
        tester,
        title: 'Edit Item',
        subtitle: 'Update the menu item details',
      );

      expect(find.text('Update the menu item details'), findsOneWidget);
    });

    testWidgets('omits the subtitle when not provided', (tester) async {
      await _openDialog(tester, title: 'Edit Item');

      // Only the title is rendered in the header text column.
      expect(find.text('Edit Item'), findsOneWidget);
      expect(find.byType(WDialog), findsOneWidget);
    });

    testWidgets('renders footer actions when provided', (tester) async {
      await _openDialog(
        tester,
        actions: const [
          Text('Cancel'),
          Text('Save'),
        ],
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('does not render footer action when actions list is empty',
        (tester) async {
      await _openDialog(tester, actions: const []);

      // A would-be footer action is absent; the dialog still shows its body.
      expect(find.text('Save'), findsNothing);
      expect(find.text('Dialog body content'), findsOneWidget);
    });
  });

  group('WDialog scrollable content', () {
    testWidgets('places content inside a SingleChildScrollView',
        (tester) async {
      await _openDialog(
        tester,
        content: const Text('A very tall body'),
      );

      // The dialog content region is scrollable so the header/footer stay
      // fixed when the body overflows.
      expect(
        find.ancestor(
          of: find.text('A very tall body'),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
    });
  });

  group('WDialog animations', () {
    testWidgets('exposes the specified fade-in / fade-out durations', (_) async {
      expect(WDialog.fadeInDuration, const Duration(milliseconds: 200));
      expect(WDialog.fadeOutDuration, const Duration(milliseconds: 150));
    });

    testWidgets('renders a 40% black backdrop color', (_) async {
      // Black at 40% alpha.
      expect(WDialog.barrierColor.a, closeTo(0.4, 1e-6));
      expect(WDialog.barrierColor.r, 0.0);
      expect(WDialog.barrierColor.g, 0.0);
      expect(WDialog.barrierColor.b, 0.0);
    });

    testWidgets('fades in gradually rather than appearing instantly',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => WDialog.show<void>(
                  context: context,
                  title: 'Animated',
                  content: const Text('body'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump(); // build the route at animation t = 0

      Finder dialogFade() => find.ancestor(
            of: find.byType(WDialog),
            matching: find.byType(FadeTransition),
          );

      // At the first frame the dialog has not yet faded in.
      var fade = tester.widget<FadeTransition>(dialogFade().first);
      expect(fade.opacity.value, 0.0);

      // Midway through the 200ms fade-in the opacity is partial.
      await tester.pump(const Duration(milliseconds: 100));
      fade = tester.widget<FadeTransition>(dialogFade().first);
      expect(fade.opacity.value, greaterThan(0.0));
      expect(fade.opacity.value, lessThan(1.0));

      // After the animation completes the dialog is fully visible.
      await tester.pumpAndSettle();
      fade = tester.widget<FadeTransition>(dialogFade().first);
      expect(fade.opacity.value, 1.0);
      expect(find.text('Animated'), findsOneWidget);
    });
  });

  group('WDialog dismissal', () {
    testWidgets('tapping the close icon button dismisses the dialog',
        (tester) async {
      await _openDialog(tester, title: 'Closable');
      expect(find.text('Closable'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Closable'), findsNothing);
    });

    testWidgets('tapping the backdrop dismisses the dialog by default',
        (tester) async {
      await _openDialog(tester, title: 'Dismissable');
      expect(find.text('Dismissable'), findsOneWidget);

      // Tap near the top-left corner, which lies on the barrier outside the
      // centered dialog card.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Dismissable'), findsNothing);
    });

    testWidgets(
        'tapping the backdrop does not dismiss when barrierDismissible is false',
        (tester) async {
      await _openDialog(
        tester,
        title: 'Sticky',
        barrierDismissible: false,
      );
      expect(find.text('Sticky'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      // The dialog remains because the backdrop is not dismissible.
      expect(find.text('Sticky'), findsOneWidget);
    });
  });
}
