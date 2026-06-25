import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

class AppBottomNavDestination {
  const AppBottomNavDestination({
    required this.label,
    required this.icon,
    this.activeIcon,
  });

  final String label;
  final Widget Function(Color color) icon;
  final Widget Function(Color color)? activeIcon;
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AppBottomNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: List.generate(destinations.length, (index) {
              final dest = destinations[index];
              final selected = index == selectedIndex;
              final iconBuilder =
                  selected ? (dest.activeIcon ?? dest.icon) : dest.icon;

              return Expanded(
                flex: selected ? 2 : 1,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDestinationSelected(index);
                  },
                  child: selected
                      ? _ActiveTab(icon: iconBuilder, label: dest.label)
                      : _InactiveTab(icon: iconBuilder),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.icon, required this.label});

  final Widget Function(Color color) icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Center(child: icon(AppColors.primary)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InactiveTab extends StatelessWidget {
  const _InactiveTab({required this.icon});

  final Widget Function(Color color) icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(child: icon(const Color(0xFFB0B0B0))),
      ),
    );
  }
}
