import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// One tab in [AppBottomNavBar]. Swap [icon] / [activeIcon] for SVG assets later.
class AppBottomNavDestination {
  const AppBottomNavDestination({
    required this.label,
    required this.icon,
    this.activeIcon,
  });

  final String label;

  /// Inactive tab icon (gray). Receives icon color for tinting SVGs.
  final Widget Function(Color color) icon;

  /// Active tab icon (green). Defaults to [icon] when null.
  final Widget Function(Color color)? activeIcon;
}

/// Uber-style bottom bar: white surface, top border, green active / gray inactive, no pill.
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

  static const double _barHeight = 56;
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.gray600, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _barHeight,
            child: Row(
              children: List.generate(destinations.length, (index) {
                final dest = destinations[index];
                final selected = index == selectedIndex;
                final color = selected ? AppColors.primary : AppColors.textSecondary;
                final iconBuilder = selected ? (dest.activeIcon ?? dest.icon) : dest.icon;

                return Expanded(
                  child: InkWell(
                    onTap: () => onDestinationSelected(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: _iconSize,
                          height: _iconSize,
                          child: Center(child: iconBuilder(color)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dest.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
