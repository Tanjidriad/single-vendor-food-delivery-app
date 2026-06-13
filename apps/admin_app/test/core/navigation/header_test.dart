// Feature: admin-panel-redesign
//
// Widget tests for the HeaderBar component (Requirements 6.1-6.8, 18.2).
//
// Coverage:
//   * Search debounce      : the results dropdown only appears after the 300ms
//     debounce window elapses, and surfaces matching navigation destinations.
//   * Notification badge    : hidden at 0, numeric for 1-99, "99+" beyond 99.
//   * Breadcrumb rendering  : the trail renders the humanized current path with
//     a "/" divider, and tapping a clickable ancestor navigates.
//   * Theme toggle          : tapping the sun/moon control flips
//     themeModeProvider and swaps the icon (Requirement 18.2).
//
// HeaderBar reads GoRouterState.of(context) for the current path and hosts an
// OverlayPortal-based search dropdown, so it is always mounted inside a
// GoRouter + MaterialApp.router. The 300ms search debounce is always pumped to
// completion to avoid leaving a pending Timer at test end.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:admin_app/core/theme/app_theme.dart';
import 'package:admin_app/core/theme/theme_mode_provider.dart';
import 'package:admin_app/core/widgets/layouts/header_bar.dart';

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

/// Builds a `MaterialApp.router` whose `ShellRoute` hosts the real [HeaderBar].
///
/// When [container] is supplied it is used (via [UncontrolledProviderScope]) so
/// the test can read provider state directly; otherwise a fresh [ProviderScope]
/// is created.
Widget _headerHarness({
  String initialLocation = '/dashboard',
  int notificationCount = 0,
  ProviderContainer? container,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          key: _scaffoldKey,
          body: Column(
            children: [
              HeaderBar(
                scaffoldKey: _scaffoldKey,
                notificationCount: notificationCount,
              ),
              Expanded(child: child),
            ],
          ),
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) =>
                Text('CONTENT:${state.matchedLocation}'),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) =>
                Text('CONTENT:${state.matchedLocation}'),
          ),
          GoRoute(
            path: '/menu',
            builder: (context, state) =>
                Text('CONTENT:${state.matchedLocation}'),
            routes: [
              GoRoute(
                path: 'addons',
                builder: (context, state) =>
                    Text('CONTENT:${state.matchedLocation}'),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  final app = MaterialApp.router(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    routerConfig: router,
  );

  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // themeModeProvider hydrates from SharedPreferences on build.
    SharedPreferences.setMockInitialValues({});
  });

  group('HeaderBar search debounce (Requirements 6.1, 6.2, 6.8)', () {
    testWidgets('renders the search field with a leading search icon',
        (tester) async {
      await tester.pumpWidget(_headerHarness());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('dropdown stays hidden before the debounce window elapses, '
        'then surfaces matching destinations', (tester) async {
      await tester.pumpWidget(_headerHarness());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ord');

      // Before 300ms: the debounce timer has not fired, no results dropdown.
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Orders'), findsNothing);

      // After the full debounce window: the dropdown surfaces "Orders".
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Orders'), findsOneWidget);

      // Tearing down with the dropdown open is safe: the one-shot debounce
      // timer has already fired. Clear the field and let it settle anyway.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
    });

    testWidgets('an empty query keeps the dropdown hidden', (tester) async {
      await tester.pumpWidget(_headerHarness());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // A blank query yields no results (Requirement 6.8).
      expect(find.text('Orders'), findsNothing);
    });
  });

  group('HeaderBar notification badge states (Requirements 6.3, 6.4)', () {
    testWidgets('renders the bell icon', (tester) async {
      await tester.pumpWidget(_headerHarness(notificationCount: 0));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('hides the badge when the count is 0', (tester) async {
      await tester.pumpWidget(_headerHarness(notificationCount: 0));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows the numeric count for 1-99', (tester) async {
      await tester.pumpWidget(_headerHarness(notificationCount: 7));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('caps the badge at "99+" above 99', (tester) async {
      await tester.pumpWidget(_headerHarness(notificationCount: 150));
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
    });
  });

  group('HeaderBar breadcrumb rendering (Requirement 6.7)', () {
    testWidgets('renders the humanized current segment', (tester) async {
      await tester.pumpWidget(_headerHarness(initialLocation: '/orders'));
      await tester.pumpAndSettle();

      expect(find.text('Orders'), findsOneWidget);
    });

    testWidgets('renders a multi-level trail with a "/" divider and clickable '
        'ancestor', (tester) async {
      await tester.pumpWidget(_headerHarness(initialLocation: '/menu/addons'));
      await tester.pumpAndSettle();

      // Both levels render: clickable ancestor "Menu" + current "Addons".
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Addons'), findsOneWidget);
      // The "/" divider separates the two segments.
      expect(find.text('/'), findsOneWidget);
    });

    testWidgets('tapping a clickable ancestor navigates to its route',
        (tester) async {
      await tester.pumpWidget(_headerHarness(initialLocation: '/menu/addons'));
      await tester.pumpAndSettle();

      expect(find.text('CONTENT:/menu/addons'), findsOneWidget);

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      // Navigated to the ancestor route; trail collapses to the single segment.
      expect(find.text('CONTENT:/menu'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Addons'), findsNothing);
    });
  });

  group('HeaderBar theme toggle (Requirement 18.2)', () {
    testWidgets('shows the dark-mode icon in light mode and flips the provider '
        'on tap', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(_headerHarness(container: container));
      await tester.pumpAndSettle();

      // Light mode is the default → the control offers "switch to dark".
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_outlined), findsNothing);

      // Tap the toggle.
      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();

      // Provider flipped to dark and the icon swapped to "switch to light".
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);

      // Toggling again returns to light.
      await tester.tap(find.byIcon(Icons.light_mode_outlined));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
