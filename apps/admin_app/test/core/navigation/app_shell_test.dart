// Feature: admin-panel-redesign
//
// Widget tests for the responsive AppShell layout backbone
// (Requirements 16.1-16.7).
//
// AppShell resolves the active LayoutMode from the available width via a
// LayoutBuilder and renders three distinct layouts:
//   * expanded (>= 1200px): full 260px SidebarNavigation + 32px content padding
//   * medium   (768-1199px): 64px icon-only rail            + 24px content padding
//   * compact  (< 768px)   : no persistent sidebar, hamburger + drawer overlay,
//                            16px content padding
//
// The surface size is controlled via `tester.view.physicalSize` so the
// LayoutBuilder inside AppShell sees the intended width.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:admin_app/core/theme/app_theme.dart';
import 'package:admin_app/core/widgets/layouts/app_shell.dart';
import 'package:admin_app/core/widgets/layouts/header_bar.dart';
import 'package:admin_app/core/widgets/layouts/sidebar_navigation.dart';

/// Builds a minimal app whose `ShellRoute` hosts the real [AppShell] wrapping a
/// trivial content widget. Using a tiny child (rather than a real feature
/// screen) keeps the test free of unrelated provider/network dependencies.
Widget _appShellHarness() {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Text('DASHBOARD_CONTENT'),
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

/// Sizes the test surface to [size], pumps the shell, and settles.
Future<void> _pumpShellAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_appShellHarness());
  await tester.pumpAndSettle();
}

/// Returns true if any [Padding] ancestor of the content uses
/// `EdgeInsets.all(expected)` — the content-area padding for the active mode.
bool _hasContentPadding(WidgetTester tester, double expected) {
  final paddings = tester.widgetList<Padding>(
    find.ancestor(
      of: find.text('DASHBOARD_CONTENT'),
      matching: find.byType(Padding),
    ),
  );
  return paddings.any((p) => p.padding == EdgeInsets.all(expected));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // HeaderBar's theme toggle reads themeModeProvider, which hydrates from
    // SharedPreferences on build.
    SharedPreferences.setMockInitialValues({});
  });

  group('AppShell expanded layout (>= 1200px)', () {
    testWidgets('renders the full sidebar, header, content and 32px padding',
        (tester) async {
      await _pumpShellAt(tester, const Size(1400, 900));

      // A persistent (non-collapsed) sidebar and the header are present.
      expect(find.byType(SidebarNavigation), findsOneWidget);
      expect(find.byType(HeaderBar), findsOneWidget);

      final sidebar =
          tester.widget<SidebarNavigation>(find.byType(SidebarNavigation));
      expect(sidebar.isCollapsed, isFalse);

      // Brand wordmark is only shown in the full (non-rail) sidebar.
      expect(find.text('Wasabi Admin'), findsOneWidget);

      // No hamburger on expanded viewports.
      expect(find.byIcon(Icons.menu), findsNothing);

      // Content is rendered with 32px padding (Requirement 16.7).
      expect(find.text('DASHBOARD_CONTENT'), findsOneWidget);
      expect(_hasContentPadding(tester, 32), isTrue);
    });
  });

  group('AppShell medium layout (768-1199px)', () {
    testWidgets('renders a collapsed rail sidebar and 24px padding',
        (tester) async {
      await _pumpShellAt(tester, const Size(1000, 900));

      expect(find.byType(SidebarNavigation), findsOneWidget);
      expect(find.byType(HeaderBar), findsOneWidget);

      final sidebar =
          tester.widget<SidebarNavigation>(find.byType(SidebarNavigation));
      expect(sidebar.isCollapsed, isTrue);

      // The rail hides the brand wordmark and section/item labels.
      expect(find.text('Wasabi Admin'), findsNothing);

      // Still no hamburger — the rail is persistent.
      expect(find.byIcon(Icons.menu), findsNothing);

      expect(find.text('DASHBOARD_CONTENT'), findsOneWidget);
      expect(_hasContentPadding(tester, 24), isTrue);
    });
  });

  group('AppShell compact layout (< 768px)', () {
    testWidgets('hides the persistent sidebar and shows a hamburger + 16px '
        'padding', (tester) async {
      await _pumpShellAt(tester, const Size(500, 900));

      // No persistent sidebar while the drawer is closed.
      expect(find.byType(SidebarNavigation), findsNothing);
      expect(find.byType(HeaderBar), findsOneWidget);

      // The header exposes the hamburger menu button (Requirement 16.2).
      expect(find.byIcon(Icons.menu), findsOneWidget);

      expect(find.text('DASHBOARD_CONTENT'), findsOneWidget);
      expect(_hasContentPadding(tester, 16), isTrue);
    });

    testWidgets('tapping the hamburger opens the navigation drawer',
        (tester) async {
      await _pumpShellAt(tester, const Size(500, 900));

      // Drawer is closed initially.
      expect(find.byType(SidebarNavigation), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // The drawer now hosts a full (non-collapsed) sidebar.
      expect(find.byType(SidebarNavigation), findsOneWidget);
      final drawerSidebar =
          tester.widget<SidebarNavigation>(find.byType(SidebarNavigation));
      expect(drawerSidebar.isCollapsed, isFalse);
      expect(find.text('Wasabi Admin'), findsOneWidget);
    });
  });
}
