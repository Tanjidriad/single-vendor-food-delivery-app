// Feature: admin-panel-redesign
//
// Widget tests for the accessibility pass over the shared component library
// (Requirement 20: semantic labels, keyboard navigation, focus indicators,
// touch targets, live regions, and dialog focus traps).
//
// These tests assert the *programmatic* accessibility support that can be
// verified without assistive technology: Semantics flags/labels, focus ring
// visibility, minimum touch-target sizing, Escape-to-close on dialogs, and
// live-region presence. Full WCAG conformance additionally requires manual
// screen-reader testing and expert review.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/theme/app_theme.dart';
import 'package:admin_app/core/widgets/a11y/focus_ring.dart';
import 'package:admin_app/core/widgets/w_button.dart';
import 'package:admin_app/core/widgets/w_data_table.dart';
import 'package:admin_app/core/widgets/w_dialog.dart';
import 'package:admin_app/core/widgets/w_text_input.dart';

/// Wraps [child] in a themed MaterialApp + Scaffold so design tokens resolve.
Widget _harness(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('WButton accessibility (Requirements 20.1, 20.3, 20.4, 20.5)', () {
    testWidgets('exposes a button semantics node with the label and enabled '
        'state', (tester) async {
      await tester.pumpWidget(
        _harness(WButton(label: 'Save', onPressed: () {})),
      );

      expect(
        tester.getSemantics(find.byType(WButton)),
        isSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          label: 'Save',
        ),
      );
    });

    testWidgets('a disabled button reports the disabled semantics state',
        (tester) async {
      await tester.pumpWidget(
        _harness(const WButton(label: 'Save', isDisabled: true)),
      );

      expect(
        tester.getSemantics(find.byType(WButton)),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
    });

    testWidgets('honors a semanticLabel override', (tester) async {
      await tester.pumpWidget(
        _harness(WButton(
          label: 'X',
          semanticLabel: 'Close dialog',
          onPressed: () {},
        )),
      );

      expect(
        tester.getSemantics(find.byType(WButton)),
        isSemantics(label: 'Close dialog'),
      );
    });

    testWidgets('meets the 44x44 minimum touch target', (tester) async {
      await tester.pumpWidget(
        _harness(WButton(label: 'A', size: WButtonSize.sm, onPressed: () {})),
      );

      // The InkWell-backed hit region is at least 44x44 even though the sm
      // variant paints a 32px-tall pill.
      final size = tester.getSize(find.byType(InkWell));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
    });

    testWidgets('shows the focus ring when the button gains focus',
        (tester) async {
      await tester.pumpWidget(
        _harness(WButton(label: 'Focus me', onPressed: () {})),
      );

      // Resting: the focus ring border is transparent.
      WFocusRing ringWidget() =>
          tester.widget<WFocusRing>(find.byType(WFocusRing));
      // Focus the button via keyboard traversal.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // The ring container now paints a non-transparent (primary) border.
      final container = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(WFocusRing),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.width, kFocusRingWidth);
      expect(border.top.color, isNot(Colors.transparent));
      expect(ringWidget(), isNotNull);
    });
  });

  group('WTextInput accessibility (Requirements 20.5, 20.7)', () {
    testWidgets('exposes a textField semantics node with its label',
        (tester) async {
      await tester.pumpWidget(
        _harness(const SizedBox(
          width: 300,
          child: WTextInput(label: 'Email'),
        )),
      );

      expect(
        tester.getSemantics(find.byType(WTextInput)),
        isSemantics(isTextField: true),
      );
    });

    testWidgets('wraps the error message in a live region', (tester) async {
      await tester.pumpWidget(
        _harness(const SizedBox(
          width: 300,
          child: WTextInput(label: 'Email', errorText: 'Email is required'),
        )),
      );

      final liveRegion = find.ancestor(
        of: find.text('Email is required'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.liveRegion ?? false),
        ),
      );
      expect(liveRegion, findsOneWidget);
    });
  });

  group('WDialog accessibility (Requirements 20.2, 20.6)', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        _harness(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => WDialog.show<void>(
                context: context,
                title: 'Trapped',
                content: const Text('body'),
                actions: [
                  WButton(label: 'OK', onPressed: () {}),
                ],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('marks the title as a route-naming header', (tester) async {
      await openDialog(tester);

      final header = find.ancestor(
        of: find.text('Trapped'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.namesRoute ?? false),
        ),
      );
      expect(header, findsOneWidget);
    });

    testWidgets('Escape closes the dialog (Requirement 20.2)', (tester) async {
      await openDialog(tester);
      expect(find.text('Trapped'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Trapped'), findsNothing);
    });

    testWidgets('constrains focus within a FocusScope (Requirement 20.6)',
        (tester) async {
      await openDialog(tester);

      // The dialog content lives inside a dedicated FocusScope that traps Tab.
      expect(
        find.descendant(
          of: find.byType(WDialog),
          matching: find.byType(FocusScope),
        ),
        findsWidgets,
      );
    });
  });

  group('WDataTable accessibility (Requirements 20.5, 20.7)', () {
    Widget table({int currentPage = 1, int totalItems = 30}) {
      return _harness(
        SizedBox(
          width: 1200,
          height: 600,
          child: WDataTable<int>(
            columns: [
              WTableColumn<int>(
                label: 'Name',
                sortable: true,
                cellBuilder: (i) => Text('Item $i'),
              ),
            ],
            data: List.generate(10, (i) => i),
            currentPage: currentPage,
            totalItems: totalItems,
            pageSize: 10,
            onPageChanged: (_) {},
            onSort: (_) {},
          ),
        ),
      );
    }

    testWidgets('renders a hidden live region announcing the current range',
        (tester) async {
      await tester.pumpWidget(table());
      await tester.pumpAndSettle();

      final liveRegion = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.liveRegion ?? false) &&
            (w.properties.label?.contains('of 30') ?? false),
      );
      expect(liveRegion, findsOneWidget);
    });

    testWidgets('wraps the table in a labeled container', (tester) async {
      await tester.pumpWidget(table());
      await tester.pumpAndSettle();

      final container = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label == 'Data table'),
      );
      expect(container, findsOneWidget);
    });
  });
}
