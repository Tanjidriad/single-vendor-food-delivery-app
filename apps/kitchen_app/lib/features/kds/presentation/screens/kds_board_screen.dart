import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/kds_header.dart';
import '../providers/kds_provider.dart';
import 'active_orders_view.dart';
import 'menu_availability_view.dart';
import 'settings_view.dart';

import 'daily_stats_view.dart';

class KdsBoardScreen extends ConsumerStatefulWidget {
  const KdsBoardScreen({super.key});

  @override
  ConsumerState<KdsBoardScreen> createState() => _KdsBoardScreenState();
}

class _KdsBoardScreenState extends ConsumerState<KdsBoardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final kdsState = ref.watch(kdsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_currentIndex == 0)
              KdsHeader(
                isConnected: kdsState.networkHealthy,
                isRestaurantActive: kdsState.isRestaurantActive,
                onToggleOnlineStatus: (bool value) {
                  ref.read(kdsProvider.notifier).toggleOnlineStatus(value);
                },
              ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white50,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: AppColors.white50,
          indicatorColor: AppColors.pandaPinkLight,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Iconsax.clipboard_text),
              selectedIcon: Icon(Iconsax.clipboard_text, color: AppColors.pandaPink),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.chart),
              selectedIcon: Icon(Iconsax.chart, color: AppColors.pandaPink),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.menu_board),
              selectedIcon: Icon(Iconsax.menu_board, color: AppColors.pandaPink),
              label: 'Menu',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.setting_2),
              selectedIcon: Icon(Iconsax.setting_2, color: AppColors.pandaPink),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const ActiveOrdersView();
      case 1:
        return const DailyStatsView();
      case 2:
        return const MenuAvailabilityView();
      case 3:
        return const SettingsView();
      default:
        return const SizedBox.shrink();
    }
  }
}
