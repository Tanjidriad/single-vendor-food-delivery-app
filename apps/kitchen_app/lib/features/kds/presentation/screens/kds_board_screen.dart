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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _destinations = [
    (
      icon: Iconsax.clipboard_text,
      selectedIcon: Iconsax.clipboard_text,
      label: 'Orders',
    ),
    (
      icon: Iconsax.chart,
      selectedIcon: Iconsax.chart,
      label: 'Stats',
    ),
    (
      icon: Iconsax.menu_board,
      selectedIcon: Iconsax.menu_board,
      label: 'Menu',
    ),
    (
      icon: Iconsax.setting_2,
      selectedIcon: Iconsax.setting_2,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final kdsState = ref.watch(kdsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final useDrawer = width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: useDrawer ? _buildDrawer() : null,
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
                onMenuPressed:
                    useDrawer ? () => _scaffoldKey.currentState?.openDrawer() : null,
              ),
            if (kdsState.lastPrintError != null)
              _buildPrintFailureBanner(kdsState.lastPrintError!),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: useDrawer
          ? null
          : Container(
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
                onDestinationSelected: (index) =>
                    setState(() => _currentIndex = index),
                destinations: _destinations
                    .map(
                      (d) => NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon,
                            color: AppColors.pandaPink),
                        label: d.label,
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.gray200),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.restaurant, color: AppColors.pandaPink, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Kitchen OS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final d = _destinations[index];
                  final selected = index == _currentIndex;
                  return ListTile(
                    leading: Icon(
                      d.icon,
                      color: selected ? AppColors.pandaPink : AppColors.gray700,
                    ),
                    title: Text(
                      d.label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.pandaPink
                            : AppColors.black500,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: AppColors.pandaPinkLight,
                    onTap: () {
                      setState(() => _currentIndex = index);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintFailureBanner(String message) {
    return Container(
      color: AppColors.warningLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Iconsax.printer_slash,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.black500,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(kdsProvider.notifier).retryLastKitchenTicket(),
            child: const Text('Retry',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () =>
                ref.read(kdsProvider.notifier).dismissPrintFailure(),
            child: const Text('Skip',
                style: TextStyle(color: AppColors.gray700)),
          ),
        ],
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
