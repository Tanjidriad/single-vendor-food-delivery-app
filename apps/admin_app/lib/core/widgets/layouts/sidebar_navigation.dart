import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme_extension.dart';
import '../../theme/tokens/app_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Fixed width of the full sidebar on expanded viewports (>= 1200px).
///
/// Requirement 5.7: the sidebar uses a fixed width of 260px on expanded
/// viewports.
const double kSidebarExpandedWidth = 260;

/// Width of the collapsed icon-only rail used on medium viewports.
///
/// Requirement 16.3: the sidebar collapses to a 64px icon-only rail with
/// tooltips on hover.
const double kSidebarRailWidth = 64;

/// Consistent icon dimension for every navigation item (Requirement 5.8).
///
/// The design calls for SVG icons. Because no SVG assets are bundled in the
/// project's `pubspec.yaml` (only the `flutter_svg` package is available, with
/// no declared asset files), this component uses Material [IconData] glyphs
/// rendered at the consistent 20px size as the documented fallback. This
/// preserves the visual intent without risking a broken build from missing
/// SVG asset references.
const double kNavIconSize = 20;

/// A single navigation destination within the sidebar.
@immutable
class NavItem {
  const NavItem({
    required this.title,
    required this.route,
    required this.icon,
  });

  /// Human-readable label shown next to the icon (and in the rail tooltip).
  final String title;

  /// GoRouter location this item navigates to. Must match a route registered
  /// in `lib/core/router/app_router.dart`.
  final String route;

  /// Icon glyph rendered at [kNavIconSize].
  final IconData icon;
}

/// A labeled group of [NavItem]s rendered under a section header.
@immutable
class NavSection {
  const NavSection({required this.label, required this.items});

  /// Section label, displayed uppercase (Requirement 5.2).
  final String label;

  /// Items belonging to this section.
  final List<NavItem> items;
}

/// The navigation sections rendered by [SidebarNavigation].
///
/// Routes here must stay in sync with the `ShellRoute` children defined in
/// `lib/core/router/app_router.dart` (Requirement 5.2).
const List<NavSection> kNavSections = [
  NavSection(
    label: 'Main',
    items: [
      NavItem(
        title: 'Dashboard',
        route: '/dashboard',
        icon: Icons.dashboard_outlined,
      ),
    ],
  ),
  NavSection(
    label: 'Management',
    items: [
      NavItem(
        title: 'Orders',
        route: '/orders',
        icon: Icons.receipt_long_outlined,
      ),
      NavItem(
        title: 'Operations',
        route: '/ops',
        icon: Icons.warning_amber_outlined,
      ),
      NavItem(
        title: 'Menu',
        route: '/menu',
        icon: Icons.restaurant_menu_outlined,
      ),
      NavItem(
        title: 'Add-ons',
        route: '/addons',
        icon: Icons.extension_outlined,
      ),
      NavItem(
        title: 'Delivery Zones',
        route: '/zones',
        icon: Icons.map_outlined,
      ),
    ],
  ),
  NavSection(
    label: 'Marketing',
    items: [
      NavItem(
        title: 'Banners',
        route: '/banners',
        icon: Icons.image_outlined,
      ),
      NavItem(
        title: 'Coupons',
        route: '/coupons',
        icon: Icons.local_offer_outlined,
      ),
    ],
  ),
  NavSection(
    label: 'People',
    items: [
      NavItem(
        title: 'Customers',
        route: '/customers',
        icon: Icons.people_outline,
      ),
      NavItem(
        title: 'Riders',
        route: '/riders',
        icon: Icons.delivery_dining_outlined,
      ),
    ],
  ),
  NavSection(
    label: 'Assets',
    items: [
      NavItem(
        title: 'Media',
        route: '/media',
        icon: Icons.perm_media_outlined,
      ),
    ],
  ),
];

/// Determines whether a navigation item is in the active state.
///
/// Property 9 (validated by task 7.4): an item with route [route] is active for
/// the current location [path] **if and only if** `path == route` or
/// (`route != '/'` and `path.startsWith(route)`).
///
/// Exposed as a top-level pure function so the property test can exercise it
/// directly without building a widget tree.
bool isNavItemActive(String path, String route) {
  return path == route || (route != '/' && path.startsWith(route));
}

/// The primary vertical navigation for the Admin Panel.
///
/// Replaces the temporary sidebar placeholder previously hosted by [AppShell].
/// Rendered in three contexts by the shell:
///
/// * Expanded viewport: full 260px sidebar (`isCollapsed: false`).
/// * Medium viewport: 64px icon-only rail with tooltips (`isCollapsed: true`).
/// * Compact viewport: inside a [Drawer] (`isCollapsed: false`) with
///   [onNavigate] wired to dismiss the drawer after a destination is chosen.
///
/// Behaviour implemented here covers Requirements 5.1–5.8:
/// * Brand header with logo + "Wasabi Admin" (w700, lg) and a right border.
/// * Labeled sections (Main, Management, Marketing, People, Assets) with
///   uppercase xs/w600 secondary labels and a 16px gap to the first item.
/// * Active item: 3px primary left border, 8% primary background, primary
///   icon + text at w600.
/// * Hover (inactive): gray100 background with a 150ms transition.
/// * Bottom user profile: 36px initials avatar, name (w600), role (xs
///   secondary), and a logout icon button.
class SidebarNavigation extends ConsumerWidget {
  const SidebarNavigation({
    super.key,
    required this.currentPath,
    this.isCollapsed = false,
    this.onLogout,
    this.onNavigate,
  });

  /// The current GoRouter location, used to resolve the active item.
  final String currentPath;

  /// Whether to render the collapsed 64px icon-only rail (Requirement 16.3).
  final bool isCollapsed;

  /// Logout handler. When omitted, the component invokes the auth provider's
  /// `logout()` directly (Requirement 5.6); the router redirect then routes the
  /// user to the login screen.
  final VoidCallback? onLogout;

  /// Invoked after a navigation tap. Used by the compact drawer to dismiss
  /// itself once a destination is selected.
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    void handleLogout() {
      if (onLogout != null) {
        onLogout!();
      } else {
        // Requirement 5.6: invoke the authentication logout action. The
        // GoRouter redirect listens to auth state and navigates to /login.
        ref.read(authProvider.notifier).logout();
      }
    }

    return Container(
      width: isCollapsed ? kSidebarRailWidth : kSidebarExpandedWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      // Requirement 20.5: identify the sidebar as a navigation landmark so
      // screen readers can jump directly to primary navigation.
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Primary navigation',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BrandHeader(collapsed: isCollapsed),
            Divider(height: 1, color: colors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
                children: [
                  for (final section in kNavSections)
                    _NavSectionView(
                      section: section,
                      currentPath: currentPath,
                      collapsed: isCollapsed,
                      onNavigate: onNavigate,
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            _UserProfile(collapsed: isCollapsed, onLogout: handleLogout),
          ],
        ),
      ),
    );
  }
}

/// Brand header: app logo and the "Wasabi Admin" wordmark (Requirement 5.1).
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final logo = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: RadiusTokens.borderRadiusLg,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.restaurant, color: colors.onPrimary, size: 18),
    );

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: collapsed
          ? Center(child: logo)
          : Row(
              children: [
                logo,
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Text(
                    'Wasabi Admin',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: TypographyTokens.lg,
                      fontWeight: TypographyTokens.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Renders a [NavSection]: an uppercase label (full mode only) followed by its
/// navigation tiles (Requirement 5.2).
class _NavSectionView extends StatelessWidget {
  const _NavSectionView({
    required this.section,
    required this.currentPath,
    required this.collapsed,
    required this.onNavigate,
  });

  final NavSection section;
  final String currentPath;
  final bool collapsed;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!collapsed)
          Padding(
            // 16px (lg) bottom margin from the first item in the section.
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.lg,
              SpacingTokens.md,
              SpacingTokens.lg,
              SpacingTokens.lg,
            ),
            child: Text(
              section.label.toUpperCase(),
              style: TextStyle(
                fontSize: TypographyTokens.xs,
                fontWeight: TypographyTokens.semibold,
                letterSpacing: 0.5,
                color: colors.textSecondary,
              ),
            ),
          )
        else
          const SizedBox(height: SpacingTokens.sm),
        for (final item in section.items)
          _NavTile(
            item: item,
            active: isNavItemActive(currentPath, item.route),
            collapsed: collapsed,
            onNavigate: onNavigate,
          ),
        const SizedBox(height: SpacingTokens.sm),
      ],
    );
  }
}

/// A single navigation tile with active styling and a hover transition.
///
/// Stateful so it can track pointer hover and animate the background over
/// 150ms (Requirements 5.3, 5.4).
class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.onNavigate,
  });

  final NavItem item;
  final bool active;
  final bool collapsed;
  final VoidCallback? onNavigate;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovering = false;

  void _go(BuildContext context) {
    context.go(widget.item.route);
    widget.onNavigate?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = widget.active;
    final collapsed = widget.collapsed;

    final foreground = active ? colors.primary : colors.textSecondary;

    final Color background;
    if (active) {
      background = colors.primary.withValues(alpha: 0.08);
    } else if (_hovering) {
      background = colors.gray100;
    } else {
      background = Colors.transparent;
    }

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          left: BorderSide(
            width: 3,
            color: active ? colors.primary : Colors.transparent,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 0 : SpacingTokens.lg - 3,
        vertical: SpacingTokens.md,
      ),
      child: collapsed
          ? Icon(widget.item.icon, size: kNavIconSize, color: foreground)
          : Row(
              children: [
                Icon(widget.item.icon, size: kNavIconSize, color: foreground),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: Text(
                    widget.item.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: TypographyTokens.md,
                      fontWeight: active
                          ? TypographyTokens.semibold
                          : TypographyTokens.medium,
                    ),
                  ),
                ),
              ],
            ),
    );

    final tappable = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Semantics(
        // Requirement 20.5: expose the nav item as a button and surface its
        // active (selected) state. The accessible name is supplied by the
        // inner label text (expanded) or the Tooltip (collapsed), so no label
        // is set here to avoid a duplicate announcement.
        button: true,
        selected: widget.active,
        child: InkWell(
          onTap: () => _go(context),
          child: collapsed
              ? Tooltip(message: widget.item.title, child: content)
              : content,
        ),
      ),
    );

    return tappable;
  }
}

/// Bottom user profile section with avatar, name, role, and logout button
/// (Requirement 5.5).
class _UserProfile extends StatelessWidget {
  const _UserProfile({required this.collapsed, required this.onLogout});

  final bool collapsed;
  final VoidCallback onLogout;

  // No user model is exposed by the auth layer, so name/role are static
  // placeholders matching the previous shell behaviour.
  static const String _userName = 'Admin User';
  static const String _userRole = 'Superadmin';

  String get _initials {
    final parts = _userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final avatar = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: colors.primary,
          fontSize: TypographyTokens.sm,
          fontWeight: TypographyTokens.bold,
        ),
      ),
    );

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        child: Column(
          children: [
            avatar,
            const SizedBox(height: SpacingTokens.sm),
            IconButton(
              icon: Icon(Icons.logout, size: kNavIconSize, color: colors.textSecondary),
              onPressed: onLogout,
              tooltip: 'Logout',
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: SpacingTokens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: TypographyTokens.semibold,
                    fontSize: TypographyTokens.md,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  _userRole,
                  style: TextStyle(
                    fontSize: TypographyTokens.xs,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, size: kNavIconSize, color: colors.textSecondary),
            onPressed: onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}
