// Feature: admin-panel-redesign
//
// Widget tests for the form input components (Requirement 14.1-14.6):
// - WTextInput: focus state border change, error display, disabled state,
//   label rendering.
// - WSelectInput: dropdown opens with a max of 6 visible items, selection
//   callback fires with the chosen option.
// - WSearchInput: 300ms debounce on onChanged, leading search icon rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_app/core/theme/app_theme.dart';
import 'package:admin_app/core/theme/tokens/app_tokens.dart';
import 'package:admin_app/core/widgets/w_search_input.dart';
import 'package:admin_app/core/widgets/w_select_input.dart';
import 'package:admin_app/core/widgets/w_text_input.dart';

/// Wraps [child] in a themed MaterialApp + Scaffold so design tokens resolve.
Widget _harness(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(24), child: child)),
  );
}

/// Returns the [Border] applied to the input field container that directly
/// wraps the supplied [inner] finder.
Border _fieldBorder(WidgetTester tester, Finder inner) {
  final container = tester.widget<Container>(
    find
        .ancestor(of: inner, matching: find.byType(Container))
        .first,
  );
  final decoration = container.decoration as BoxDecoration;
  return decoration.border! as Border;
}

void main() {
  final colors = AppTokens.light.colors;

  group('WTextInput', () {
    testWidgets('renders the label when provided', (tester) async {
      await tester.pumpWidget(
        _harness(const WTextInput(label: 'Email address')),
      );

      expect(find.text('Email address'), findsOneWidget);
    });

    testWidgets('does not render a label block when label is null',
        (tester) async {
      await tester.pumpWidget(
        _harness(const WTextInput(placeholder: 'Type here')),
      );

      // The field itself renders; with no label there is exactly one TextField.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders the error text when errorText is non-empty',
        (tester) async {
      await tester.pumpWidget(
        _harness(const WTextInput(
          label: 'Email',
          errorText: 'Email is required',
        )),
      );

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('does not render an error block when errorText is empty',
        (tester) async {
      await tester.pumpWidget(
        _harness(const WTextInput(label: 'Email', errorText: '   ')),
      );

      // Whitespace-only error text is treated as no error.
      expect(find.text('   '), findsNothing);
    });

    testWidgets('uses a 1px border token when unfocused and a 2px primary '
        'border when focused', (tester) async {
      await tester.pumpWidget(_harness(const WTextInput(label: 'Name')));

      final textField = find.byType(TextField);

      // Resting state: 1px border using the border token.
      var border = _fieldBorder(tester, textField);
      expect(border.top.width, WTextInput.restingBorderWidth);
      expect(border.top.color, colors.border);

      // Focus the field by tapping it.
      await tester.tap(textField);
      await tester.pump();

      border = _fieldBorder(tester, textField);
      expect(border.top.width, WTextInput.focusedBorderWidth);
      expect(border.top.color, colors.primary);
    });

    testWidgets('disabled state wraps the field in Opacity + IgnorePointer and '
        'disables the TextField', (tester) async {
      await tester.pumpWidget(
        _harness(const WTextInput(label: 'Name', disabled: true)),
      );

      // Opacity 0.5 reduction.
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, WTextInput.disabledOpacity);

      // IgnorePointer prevents interaction.
      expect(
        find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );

      // The underlying TextField is disabled.
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });
  });

  group('WSelectInput', () {
    final options = List.generate(
      8,
      (i) => SelectOption(value: 'v$i', label: 'Option $i'),
    );

    testWidgets('caps the dropdown overlay at 6 visible items (height '
        'constraint)', (tester) async {
      expect(WSelectInput.maxVisibleItems, 6);
      expect(WSelectInput.itemHeight, 40);

      await tester.pumpWidget(
        _harness(WSelectInput(
          label: 'Category',
          placeholder: 'Select one',
          options: options,
          onChanged: (_) {},
        )),
      );

      // Open the dropdown.
      await tester.tap(find.text('Select one'));
      await tester.pumpAndSettle();

      // All 8 options exist in the (scrollable) overlay.
      for (final option in options) {
        expect(find.text(option.label), findsOneWidget);
      }

      // The overlay height is constrained to at most 6 rows (6 * 40 = 240).
      final menu = tester.widget<PopupMenuButton<SelectOption>>(
        find.byType(PopupMenuButton<SelectOption>),
      );
      expect(
        menu.constraints!.maxHeight,
        WSelectInput.maxVisibleItems * WSelectInput.itemHeight,
      );
    });

    testWidgets('invokes onChanged with the selected option', (tester) async {
      SelectOption? selected;

      await tester.pumpWidget(
        _harness(WSelectInput(
          label: 'Category',
          placeholder: 'Select one',
          options: options,
          onChanged: (option) => selected = option,
        )),
      );

      await tester.tap(find.text('Select one'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Option 3'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.value, 'v3');
      expect(selected!.label, 'Option 3');
    });

    testWidgets('renders the error text when provided', (tester) async {
      await tester.pumpWidget(
        _harness(WSelectInput(
          label: 'Category',
          options: options,
          errorText: 'Please choose a category',
        )),
      );

      expect(find.text('Please choose a category'), findsOneWidget);
    });
  });

  group('WSearchInput', () {
    testWidgets('renders a leading search icon', (tester) async {
      await tester.pumpWidget(
        _harness(const WSearchInput(placeholder: 'Search...')),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('debounces onChanged: fires once after the debounce window',
        (tester) async {
      final received = <String>[];

      await tester.pumpWidget(
        _harness(WSearchInput(
          placeholder: 'Search...',
          debounce: const Duration(milliseconds: 300),
          onChanged: received.add,
        )),
      );

      await tester.enterText(find.byType(TextField), 'pizza');

      // Immediately after typing, the debounce timer has not yet elapsed.
      await tester.pump(const Duration(milliseconds: 100));
      expect(received, isEmpty);

      // After the full 300ms window elapses, the callback fires once.
      await tester.pump(const Duration(milliseconds: 250));
      expect(received, ['pizza']);
    });

    testWidgets('debounce collapses rapid input into a single trailing call',
        (tester) async {
      final received = <String>[];

      await tester.pumpWidget(
        _harness(WSearchInput(
          placeholder: 'Search...',
          debounce: const Duration(milliseconds: 300),
          onChanged: received.add,
        )),
      );

      // Two quick edits within the debounce window.
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump(const Duration(milliseconds: 100));

      // Nothing emitted yet — the second edit reset the timer.
      expect(received, isEmpty);

      // Only the latest value is delivered once the window finally elapses.
      await tester.pump(const Duration(milliseconds: 300));
      expect(received, ['ab']);
    });
  });
}
