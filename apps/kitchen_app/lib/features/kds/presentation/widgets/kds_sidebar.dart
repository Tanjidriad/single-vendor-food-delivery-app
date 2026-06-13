import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';

class KdsSidebar extends StatelessWidget {
  final int activeIndex;
  final Function(int) onNavigate;

  const KdsSidebar({
    super.key,
    required this.activeIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(),
          const SizedBox(height: 48),
          _buildNavItem(0, Iconsax.clipboard_text, 'Orders'),
          _buildNavItem(1, Iconsax.clock, 'History'),
          _buildNavItem(2, Iconsax.menu_board, '86 List'),
          _buildNavItem(3, Iconsax.chart, 'Analytics'),
          const Spacer(),
          _buildNavItem(4, Iconsax.setting_2, 'Settings'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Iconsax.shop, color: AppColors.white50),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = activeIndex == index;
    return GestureDetector(
      onTap: () => onNavigate(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
