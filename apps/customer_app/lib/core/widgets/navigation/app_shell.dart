import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';

import '../../network/api_client.dart';
import '../../realtime/socket_service.dart';
import '../../theme/app_breakpoints.dart';
import '../../theme/app_colors.dart';
import '../commerce/floating_cart_bar.dart';
import '../layout/responsive_center.dart';
import 'app_bottom_nav_bar.dart';
import 'customer_bottom_nav_destinations.dart';
import '../../../features/home/presentation/providers/zone_check_provider.dart';
import '../../../features/home/presentation/widgets/zone_takeover.dart';

/// Index of the Profile branch in the navigation shell. The out-of-zone gate
/// covers the discovery tabs but leaves Profile reachable so the customer can
/// still manage addresses and account settings.
const int _profileBranchIndex = 3;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On resume, recover a socket that may have dropped while backgrounded so
    // live order tracking keeps updating. ensureConnected is a no-op when the
    // socket is already healthy.
    if (state == AppLifecycleState.resumed) {
      final token = ref.read(authTokenProvider);
      if (token != null && token.isNotEmpty) {
        ref.read(socketServiceProvider).ensureConnected(token);
      }
    }
  }

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  Widget build(BuildContext context) {
    final layout = AppBreakpoints.of(context);
    final isDesktop = layout == AppLayoutSize.desktop;

    final outsideZone =
        ref.watch(zoneStatusProvider) == ZoneStatus.outside;
    final gated =
        outsideZone && navigationShell.currentIndex != _profileBranchIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveCenter(
        child: Row(
          children: [
            if (isDesktop) _SideRail(navigationShell: navigationShell),
            Expanded(
              child: gated ? const ZoneTakeover() : navigationShell,
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!gated) const FloatingCartBar(),
                AppBottomNavBar(
                  destinations: customerBottomNavDestinations,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: navigationShell.goBranch,
                ),
              ],
            ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      destinations: const [
        NavigationRailDestination(icon: Icon(AppIcons.home), label: Text('Home')),
        NavigationRailDestination(icon: Icon(Icons.grid_view_outlined), label: Text('Menu')),
        NavigationRailDestination(icon: Icon(AppIcons.offers), label: Text('Offers')),
        NavigationRailDestination(icon: Icon(AppIcons.profile), label: Text('Profile')),
      ],
    );
  }
}
