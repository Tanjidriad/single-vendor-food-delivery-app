import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_breakpoints.dart';
import '../../theme/app_colors.dart';
import '../commerce/floating_cart_bar.dart';
import '../layout/responsive_center.dart';
import 'app_bottom_nav_bar.dart';
import 'customer_bottom_nav_destinations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final layout = AppBreakpoints.of(context);
    final isDesktop = layout == AppLayoutSize.desktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveCenter(
        child: Row(
          children: [
            if (isDesktop) _SideRail(navigationShell: navigationShell),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FloatingCartBar(),
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
        NavigationRailDestination(icon: Icon(AppIcons.orders), label: Text('Orders')),
        NavigationRailDestination(icon: Icon(AppIcons.offers), label: Text('Offers')),
        NavigationRailDestination(icon: Icon(AppIcons.profile), label: Text('Profile')),
      ],
    );
  }
}
