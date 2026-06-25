import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingIndicator extends StatelessWidget {
  final int itemCount;
  final int currentPage;

  const OnboardingIndicator({
    super.key,
    required this.itemCount,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (i) {
        final isSelected = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.5),
          ),
        );
      }),
    );
  }
}
