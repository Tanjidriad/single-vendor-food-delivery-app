import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme_extension.dart';
import '../../theme/tokens/app_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'breakpoints.dart';
import 'header_bar.dart';
import 'sidebar_navigation.dart';

/// The single, responsive application shell for the Admin Panel.
///
/// `AppShell` is the consolidated layout backbone that replaces the previous
/// duplicate implementations (`SiteLayout`/`DesktopLayout`/`Sidebar`/`Header`
/// and the standalone `navigation/app_shell.dart`). It is hosted by the
/// `ShellRoute` in `app_router.dart` and wraps every authenticated feature
/// screen passed as [child].
///
/// ## Responsive behaviour (Requirements 16.2, 16.3, 16.4, 16.7)
///
/// A [LayoutBuilder] resolves the active [LayoutMode] from the available width
/// via [Breakpoints.fromWidth]:
///
/// | Mode                  | Sidebar                         | Content padding |
/// |-----------------------|---------------------------------|-----------------|
/// | [LayoutMode.expanded] | full 260px sidebar              | 32px            |
/// | [LayoutMode.medium]   | 64px icon-only rail             | 24px            |
/// | [LayoutMode.compact]  | none (hamburger + drawer overlay)| 16px           |
///
/// ## Extension points for tasks 7.2 and 7.3
///
/// This task (7.1) ships functional *placeholder* navigation and header widgets
/// so routing keeps working. The follow-up tasks replace the placeholders:
///
/// * **Task 7.2 – `SidebarNavigation`**: replace [_SidebarPlaceholder] in the
///   expanded body, the rail body, and the compact [Drawer] with
///   `SidebarNavigation(currentPath: path, isCollapsed: mode == LayoutMode.medium,
///   onLogout: ...)`.
/// * **Task 7.3 – `HeaderBar`**: replace the header with
///   `HeaderBar(scaffoldKey: _scaffoldKey)`. The [_scaffoldKey] below is the
///   handle the header's hamburger uses to open the compact drawer.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  /// The current route's screen, supplied by the `ShellRoute` builder.
  final Widget child;

  /// Key used to open the navigation drawer from the header on compact
  /// viewports. Task 7.3's `HeaderBar` accepts this key and wires the
  /// hamburger button to `scaffoldKey.currentState?.openDrawer()`.
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentPath = GoRouterState.of(context).matchedLocation;

    void handleLogout() => ref.read(authProvider.notifier).logout();

    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = Breakpoints.fromWidth(constraints.maxWidth);

        final double contentPadding = switch (mode) {
          LayoutMode.expanded => SpacingTokens.xxxl, // 32
          LayoutMode.medium => SpacingTokens.xxl, // 24
          LayoutMode.compact => SpacingTokens.lg, // 16
        };

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colors.background,
          // Compact viewports have no persistent sidebar; the navigation is
          // presented as a drawer overlay opened from the header hamburger.
          drawer: mode == LayoutMode.compact
              ? Drawer(
                  width: kSidebarExpandedWidth,
                  backgroundColor: colors.surface,
                  child: SafeArea(
                    child: SidebarNavigation(
                      currentPath: currentPath,
                      isCollapsed: false,
                      onLogout: handleLogout,
                      onNavigate: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              // Persistent sidebar for expanded (260px) and medium (64px rail).
              if (mode == LayoutMode.expanded)
                SidebarNavigation(
                  currentPath: currentPath,
                  isCollapsed: false,
                  onLogout: handleLogout,
                ),
              if (mode == LayoutMode.medium)
                SidebarNavigation(
                  currentPath: currentPath,
                  isCollapsed: true,
                  onLogout: handleLogout,
                ),
              Expanded(
                child: Column(
                  children: [
                    HeaderBar(
                      scaffoldKey: _scaffoldKey,
                      showMenuButton: mode == LayoutMode.compact,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(contentPadding),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
