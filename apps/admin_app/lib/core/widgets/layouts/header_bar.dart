import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme_extension.dart';
import '../../theme/theme_mode_provider.dart';
import '../../theme/tokens/app_tokens.dart';
import 'sidebar_navigation.dart';

/// Fixed height of the header bar (Requirement 6.6).
const double kHeaderBarHeight = 56;

/// Notification bell icon size (Requirement 6.3).
const double kHeaderBellSize = 20;

/// Header avatar diameter (Requirement 6.5).
const double kHeaderAvatarSize = 32;

/// Maximum number of search results shown in the dropdown (Requirement 6.2).
const int kHeaderSearchMaxResults = 8;

/// Maximum breadcrumb depth (Requirement 6.7).
const int kBreadcrumbMaxLevels = 4;

/// Debounce applied to the header search field (Requirement 6.2).
const Duration kHeaderSearchDebounce = Duration(milliseconds: 300);

// ---------------------------------------------------------------------------
// Pure, testable logic
// ---------------------------------------------------------------------------

/// A single breadcrumb segment produced by [buildBreadcrumbs].
@immutable
class BreadcrumbSegment {
  const BreadcrumbSegment({
    required this.label,
    required this.route,
    required this.isClickable,
  });

  /// Human-readable label displayed for this segment.
  final String label;

  /// Cumulative route this segment navigates to when [isClickable].
  final String route;

  /// Whether this segment is a clickable ancestor. The final (current)
  /// segment is never clickable.
  final bool isClickable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BreadcrumbSegment &&
          label == other.label &&
          route == other.route &&
          isClickable == other.isClickable);

  @override
  int get hashCode => Object.hash(label, route, isClickable);

  @override
  String toString() =>
      'BreadcrumbSegment(label: $label, route: $route, clickable: $isClickable)';
}

/// Builds the breadcrumb trail for a navigation [path].
///
/// Property 11 (validated by task 7.4): for any navigation path with `N`
/// segments, the trail displays at most [maxLevels] levels, showing the last
/// `min(N, maxLevels)` segments, with all but the final segment clickable.
///
/// Each displayed segment carries its cumulative route (e.g. `/menu/addons`)
/// so clickable ancestors navigate to the correct location even when the trail
/// has been truncated.
List<BreadcrumbSegment> buildBreadcrumbs(
  String path, {
  int maxLevels = kBreadcrumbMaxLevels,
}) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return const [];

  // Build cumulative routes for every segment first.
  final all = <BreadcrumbSegment>[];
  final buffer = StringBuffer();
  for (final segment in segments) {
    buffer
      ..write('/')
      ..write(segment);
    all.add(
      BreadcrumbSegment(
        label: humanizeSegment(segment),
        route: buffer.toString(),
        isClickable: false,
      ),
    );
  }

  // Display only the last min(N, maxLevels) segments.
  final start = all.length > maxLevels ? all.length - maxLevels : 0;
  final shown = all.sublist(start);

  // All but the final shown segment are clickable.
  return [
    for (var i = 0; i < shown.length; i++)
      BreadcrumbSegment(
        label: shown[i].label,
        route: shown[i].route,
        isClickable: i < shown.length - 1,
      ),
  ];
}

/// Converts a raw path segment into a display label.
///
/// Splits on `-`/`_` and capitalises each word: `on_the_way` -> `On The Way`.
String humanizeSegment(String segment) {
  final words = segment
      .split(RegExp(r'[-_]'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1));
  final joined = words.join(' ');
  return joined.isEmpty ? segment : joined;
}

/// Resolves the text shown inside the notification badge.
///
/// Property 10 (validated by task 7.4): returns `null` (badge hidden) when
/// [count] is `0` (or negative), the numeric string when `1 <= count <= 99`,
/// and `"99+"` when `count > 99`.
String? notificationBadgeText(int count) {
  if (count <= 0) return null;
  if (count > 99) return '99+';
  return count.toString();
}

/// A search result surfaced in the header search dropdown.
@immutable
class HeaderSearchResult {
  const HeaderSearchResult({
    required this.category,
    required this.title,
    required this.route,
  });

  /// Category label (the navigation section the destination belongs to).
  final String category;

  /// Destination name.
  final String title;

  /// Route the result navigates to when tapped.
  final String route;
}

/// Filters navigation destinations by [query], capped at [maxResults].
///
/// Matches against both the destination title and its section label, so a
/// query like "ord" surfaces Orders and "marketing" surfaces Banners/Coupons.
/// Returns an empty list for a blank query (Requirement 6.8).
List<HeaderSearchResult> searchNavDestinations(
  String query, {
  List<NavSection> sections = kNavSections,
  int maxResults = kHeaderSearchMaxResults,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final results = <HeaderSearchResult>[];
  for (final section in sections) {
    for (final item in section.items) {
      final matches = item.title.toLowerCase().contains(q) ||
          section.label.toLowerCase().contains(q);
      if (matches) {
        results.add(
          HeaderSearchResult(
            category: section.label,
            title: item.title,
            route: item.route,
          ),
        );
      }
    }
  }

  if (results.length > maxResults) {
    return results.sublist(0, maxResults);
  }
  return results;
}

// ---------------------------------------------------------------------------
// HeaderBar widget
// ---------------------------------------------------------------------------

/// The top application bar for the Admin Panel.
///
/// Replaces the temporary header placeholder previously hosted by `AppShell`.
/// Covers Requirements 6.1–6.8 and 18.2:
///
/// * Fixed 56px height with a 1px bottom border ([kHeaderBarHeight]).
/// * Breadcrumb trail (max 4 levels, clickable ancestors, `/` divider).
/// * Global search (36px, radius `md`, 300ms debounce, max 8 results dropdown).
/// * Theme toggle (sun/moon) wired to [themeModeProvider] (Requirement 18.2).
/// * Notification bell (20px) with a count badge (hidden at 0, numeric to 99,
///   "99+" beyond).
/// * User avatar (32px initials circle) and name (text `sm`).
/// * Hamburger button on compact viewports that opens the shell drawer via
///   [scaffoldKey] (Requirement 16.2).
class HeaderBar extends ConsumerWidget {
  const HeaderBar({
    super.key,
    this.scaffoldKey,
    this.showMenuButton = false,
    this.notificationCount = _placeholderNotificationCount,
  });

  /// Key of the host [Scaffold], used to open the navigation drawer from the
  /// compact-viewport hamburger button.
  final GlobalKey<ScaffoldState>? scaffoldKey;

  /// Whether the hamburger button is shown (compact viewports only).
  final bool showMenuButton;

  /// Number of unread notifications driving the bell badge.
  final int notificationCount;

  // No notifications provider exists yet in the presentation-only redesign, so
  // a documented placeholder count is used (mirrors the static user profile
  // placeholder in `SidebarNavigation`). Swap for a provider when available.
  static const int _placeholderNotificationCount = 3;

  // Static profile placeholder, matching `SidebarNavigation`.
  static const String _userName = 'Admin User';

  static String get _initials {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Container(
      height: kHeaderBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final showSearch = width >= 560;
          final showName = width >= 480;

          return Row(
            children: [
              if (showMenuButton) ...[
                IconButton(
                  icon: Icon(Icons.menu, color: colors.textPrimary, size: 22),
                  onPressed: () => scaffoldKey?.currentState?.openDrawer(),
                  tooltip: 'Open navigation',
                ),
                const SizedBox(width: SpacingTokens.sm),
              ],
              Flexible(
                flex: 2,
                child: _Breadcrumbs(path: currentPath),
              ),
              const SizedBox(width: SpacingTokens.lg),
              if (showSearch) ...[
                Flexible(
                  flex: 3,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const _HeaderSearch(),
                  ),
                ),
                const SizedBox(width: SpacingTokens.lg),
              ] else
                const Spacer(),
              const _ThemeToggle(),
              const SizedBox(width: SpacingTokens.xs),
              _NotificationBell(count: notificationCount),
              const SizedBox(width: SpacingTokens.lg),
              _UserProfile(showName: showName, initials: _initials, name: _userName),
            ],
          );
        },
      ),
    );
  }
}

/// Theme toggle control wired to [themeModeProvider] (Requirement 18.2).
class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: kHeaderBellSize,
        color: colors.textPrimary,
      ),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

/// Notification bell with a count badge (Requirements 6.3, 6.4).
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badge = notificationBadgeText(count);

    // Requirement 20.1: describe the bell, including the unread count, for
    // screen readers since the numeric badge is otherwise purely visual.
    final semanticLabel = badge == null
        ? 'Notifications, no unread'
        : 'Notifications, $badge unread';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: 'Notifications',
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none,
                size: kHeaderBellSize,
                color: colors.textPrimary,
              ),
              if (badge != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.surface, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 9,
                        fontWeight: TypographyTokens.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// User avatar (32px initials circle) and name (text `sm`) (Requirement 6.5).
class _UserProfile extends StatelessWidget {
  const _UserProfile({
    required this.showName,
    required this.initials,
    required this.name,
  });

  final bool showName;
  final String initials;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: kHeaderAvatarSize,
          height: kHeaderAvatarSize,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: typography.style(
              size: TypographyTokens.sm,
              weight: TypographyTokens.semibold,
              color: colors.onPrimary,
            ),
          ),
        ),
        if (showName) ...[
          const SizedBox(width: SpacingTokens.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: typography.style(
                size: TypographyTokens.sm,
                weight: TypographyTokens.medium,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Breadcrumb trail with `/` dividers and clickable ancestor segments
/// (Requirement 6.7). Truncation/clickability is delegated to
/// [buildBreadcrumbs] so it can be property-tested independently.
class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final crumbs = buildBreadcrumbs(path);

    if (crumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    for (var i = 0; i < crumbs.length; i++) {
      final crumb = crumbs[i];
      if (crumb.isClickable) {
        children.add(
          InkWell(
            onTap: () => context.go(crumb.route),
            borderRadius: RadiusTokens.borderRadiusSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.xs,
                vertical: SpacingTokens.xs,
              ),
              child: Text(
                crumb.label,
                style: typography.style(
                  size: TypographyTokens.sm,
                  weight: TypographyTokens.medium,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
            child: Text(
              crumb.label,
              style: typography.style(
                size: TypographyTokens.sm,
                weight: TypographyTokens.semibold,
                color: colors.textPrimary,
              ),
            ),
          ),
        );
      }

      if (i < crumbs.length - 1) {
        children.add(
          Text(
            '/',
            style: typography.style(
              size: TypographyTokens.sm,
              color: colors.textDisabled,
            ),
          ),
        );
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Global search field with a debounced results dropdown overlay
/// (Requirements 6.1, 6.2, 6.8).
class _HeaderSearch extends StatefulWidget {
  const _HeaderSearch();

  @override
  State<_HeaderSearch> createState() => _HeaderSearchState();
}

class _HeaderSearchState extends State<_HeaderSearch> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _link = LayerLink();
  final OverlayPortalController _overlay = OverlayPortalController();
  Timer? _debounce;
  List<HeaderSearchResult> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(kHeaderSearchDebounce, () {
      if (!mounted) return;
      final results = searchNavDestinations(value);
      setState(() => _results = results);
      // Requirement 6.8: hide the dropdown when the query is empty or there
      // are no matches; otherwise show the results.
      if (results.isEmpty) {
        _overlay.hide();
      } else {
        _overlay.show();
      }
    });
  }

  void _select(HeaderSearchResult result) {
    _controller.clear();
    setState(() => _results = const []);
    _overlay.hide();
    context.go(result.route);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildOverlay,
        child: _SearchField(
          controller: _controller,
          onChanged: _onChanged,
          colors: colors,
          typography: typography,
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;

    return Stack(
      children: [
        // Tap-outside barrier dismisses the dropdown.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _overlay.hide,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, SpacingTokens.xs),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _link.leaderSize?.width ?? 320,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: RadiusTokens.borderRadiusMd,
                  border: Border.all(color: colors.border),
                  boxShadow: ElevationTokens.md,
                ),
                child: ClipRRect(
                  borderRadius: RadiusTokens.borderRadiusMd,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final result in _results)
                          _SearchResultTile(
                            result: result,
                            colors: colors,
                            typography: typography,
                            onTap: () => _select(result),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The search text field (36px, radius `md`, leading search icon).
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.colors,
    required this.typography,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ColorTokens colors;
  final TypographyTokens typography;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.borderRadiusMd,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: colors.textSecondary),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: colors.primary,
              style: typography.style(
                size: TypographyTokens.base,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Search orders, menu items...',
                hintStyle: typography.style(
                  size: TypographyTokens.base,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single result row in the search dropdown, showing category + name.
class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.colors,
    required this.typography,
    required this.onTap,
  });

  final HeaderSearchResult result;
  final ColorTokens colors;
  final TypographyTokens typography;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.north_east, size: 14, color: colors.textSecondary),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.title,
                    overflow: TextOverflow.ellipsis,
                    style: typography.style(
                      size: TypographyTokens.md,
                      weight: TypographyTokens.medium,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    result.category.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: typography.style(
                      size: TypographyTokens.xs,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
