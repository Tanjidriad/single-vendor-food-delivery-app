import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MobileTabSelector extends StatelessWidget {
  final int activeTab;
  final Function(int) onTabChange;
  final int newCount;
  final int prepCount;
  final int readyCount;

  const MobileTabSelector({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    required this.newCount,
    required this.prepCount,
    required this.readyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          _buildTab(0, 'New', newCount),
          _buildTab(1, 'Prep', prepCount),
          _buildTab(2, 'Ready', readyCount),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, int count) {
    final isActive = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChange(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.pandaPinkLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? AppColors.pandaPink.withValues(alpha: 0.3) : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? AppColors.pandaPink : AppColors.gray700,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.pandaPink : AppColors.gray200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isActive ? AppColors.white50 : AppColors.black500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
