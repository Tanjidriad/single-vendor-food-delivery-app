// Feature: admin-panel-redesign
//
// Widget tests for the SidebarNavigation component (Requirements 5.1-5.8).
//
// Coverage:
//   * Section grouping  : every labeled section (uppercased) and every nav
//     item title renders in the full sidebar.
//   * Active item styling: the item whose route matches the current path shows
//     the 3px primary left border, 8% primary background, and primary w600
//     icon/text; inactive items use a transparent border + secondary text.
//   * Rail mode          : collapsed (64px) hides the brand wordmark, section
//     labels and item titles, keeps icons, and exposes tooltips.
//   * Logout action      : tapping the logout button invokes the onLogout
//     callback (Requirement 5.6).
//   * Navigation         : tapping an item routes via context.go and updates
//     the active item.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:admin_app/core/theme/app_theme.dart';
import 'package:admin_app/core/theme/tokens/app_tokens.dart';
import 'package:admin_app/core/widgets/layouts/sidebar_navigation.dart';

/// Renders [SidebarNavigation] directly (no router) for rendering/styling
/// tests. The sidebar is placed in a [Row] so its fixed-width [Container]
/// receives loose horizontal constraints and reports its intrinsic width.
Widget _renderHarness({
  required String currentPath,
  bool isCollapsed = false,
  VoidCallback? onLogout,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Row(
          children: [
            SidebarNavigation(
              currentPath: currentPath,
              isCollapsed: isCollapsed,
              onLogout: onLogout ?? () {},
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    ),
  );
}

/// Sizes the test surface tall enough that the full sidebar (brand header,
/// every section in the lazily-built `ListView`, and the bottom profile) is
/// laid out, then pumps [_renderHarness]. Without a tall surface the bottom
/// sections (`Assets`/`Media`) stay off-screen and are never built.
Future<void> _pumpRender(
  WidgetTester tester, {
  required String currentPath,
  bool isCollapsed = false,
  VoidCallback? onLogout,
}) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    _renderHarness(
      currentPath: currentPath,
      isCollapsed: isCollapsed,
      onLogout: onLogout,
    ),
  );
  await tester.pumpAndSettle();
}

/// Hosts the sidebar inside a `ShellRoute` so `context.go` navigation taps
/// resolve and the sidebar persists across route changes.
Widget _routerHarness() {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          body: Row(
            children: [
              SidebarNavigation(
                currentPath: state.matchedLocation,
                onLogout: () {},
              ),
              Expanded(child: child),
            ],
          ),
        ),
        routes: [
          for (final route in const [
            '/dashboard',
            '/orders',
            '/menu',
            '/addons',
            '/banners',
            '/coupons',
            '/customers',
            '/riders',
            '/media',
          ])
            GoRoute(
              path: route,
              builder: (context, state) => Text('CONTENT:${state.matchedLocation}'),
            ),
        ],
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: router,
    ),
  );
}

/// Returns the [BoxDecoration] of the tile [AnimatedContainer] wrapping [label].
BoxDecoration _tileDecoration(WidgetTester tester, String label) {
  final container = tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  final colors = AppTokens.light.colors;

  group('SidebarNavigation section grouping (Requirement 5.2)', () {
    testWidgets('renders every section label uppercased', (tester) async {
      await _pumpRender(tester, currentPath: '/dashboard');

      expect(find.text('MAIN'), findsOneWidget);
      expect(find.text('MANAGEMENT'), findsOneWidget);
      expect(find.text('MARKETING'), findsOneWidget);
      expect(find.text('PEOPLE'), findsOneWidget);
      expect(find.text('ASSETS'), findsOneWidget);
    });

    testWidgets('renders every navigation item title and the brand wordmark',
        (tester) async {
      await _pumpRender(tester, currentPath: '/dashboard');

      expect(find.text('Wasabi Admin'), findsOneWidget);
      for (final title in const [
        'Dashboard',
        'Orders',
        'Menu',
        'Add-ons',
        'Banners',
        'Coupons',
        'Customers',
        'Riders',
        'Media',
      ]) {
        expect(find.text(title), findsOneWidget, reason: 'missing "$title"');
      }
    });
  });

  group('SidebarNavigation active item styling (Requirement 5.3)', () {
    testWidgets('the matching item shows the primary border, tint and weight',
        (tester) async {
      await _pumpRender(tester, currentPath: '/orders');

      // Active tile decoration: 3px primary left border + 8% primary fill.
      final activeDecoration = _tileDecoration(tester, 'Orders');
      final activeBorder = activeDecoration.border! as Border;
      expect(activeBorder.left.width, 3);
      expect(activeBorder.left.color, colors.primary);
      expect(activeDecoration.color, colors.primary.withValues(alpha: 0.08));

      // Active label: primary color, semibold (w600).
      final activeText = tester.widget<Text>(find.text('Orders'));
      expect(activeText.style!.color, colors.primary);
      expect(activeText.style!.fontWeight, TypographyTokens.semibold);
    });

    testWidgets('non-matching items have a transparent border and secondary '
        'text', (tester) async {
      await _pumpRender(tester, currentPath: '/orders');

      final inactiveDecoration = _tileDecoration(tester, 'Menu');
      final inactiveBorder = inactiveDecoration.border! as Border;
      expect(inactiveBorder.left.color, Colors.transparent);
      // No hover in a widget test, so the resting background is transparent.
      expect(inactiveDecoration.color, Colors.transparent);

      final inactiveText = tester.widget<Text>(find.text('Menu'));
      expect(inactiveText.style!.color, colors.textSecondary);
      expect(inactiveText.style!.fontWeight, TypographyTokens.medium);
    });

    testWidgets('a prefix path keeps the parent item active', (tester) async {
      // Property 9 semantics: /orders/detail activates the Orders item.
      await _pumpRender(tester, currentPath: '/orders/detail');

      final activeBorder =
          _tileDecoration(tester, 'Orders').border! as Border;
      expect(activeBorder.left.color, colors.primary);
    });
  });

  group('SidebarNavigation rail mode (Requirement 16.3)', () {
    testWidgets('collapses to 64px, icon-only, with tooltips', (tester) async {
      await _pumpRender(tester, currentPath: '/dashboard', isCollapsed: true);

      // Fixed rail width.
      expect(
        tester.getSize(find.byType(SidebarNavigation)).width,
        kSidebarRailWidth,
      );

      // Brand wordmark, section labels and item titles are all hidden.
      expect(find.text('Wasabi Admin'), findsNothing);
      expect(find.text('MANAGEMENT'), findsNothing);
      expect(find.text('Orders'), findsNothing);

      // Icons remain visible at the consistent nav icon size.
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);

      // Collapsed tiles wrap their icon in a Tooltip.
      expect(find.byType(Tooltip), findsWidgets);
    });

    testWidgets('expanded sidebar reports the full 260px width', (tester) async {
      await _pumpRender(tester, currentPath: '/dashboard');

      expect(
        tester.getSize(find.byType(SidebarNavigation)).width,
        kSidebarExpandedWidth,
      );
    });
  });

  group('SidebarNavigation logout action (Requirement 5.6)', () {
    testWidgets('tapping logout invokes the onLogout callback', (tester) async {
      var loggedOut = 0;
      await _pumpRender(
        tester,
        currentPath: '/dashboard',
        onLogout: () => loggedOut++,
      );

      expect(find.byIcon(Icons.logout), findsOneWidget);
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      expect(loggedOut, 1);
    });
  });

  group('SidebarNavigation navigation', () {
    testWidgets('tapping an item routes and updates the active item',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_routerHarness());
      await tester.pumpAndSettle();

      // Dashboard is the initial active route.
      expect(find.text('CONTENT:/dashboard'), findsOneWidget);

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      // Navigation occurred and the Orders item is now active.
      expect(find.text('CONTENT:/orders'), findsOneWidget);
      final activeBorder = _tileDecoration(tester, 'Orders').border! as Border;
      expect(activeBorder.left.color, colors.primary);
    });
  });
}
