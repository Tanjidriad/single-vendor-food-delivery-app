import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../theme/app_colors.dart';

/// Animated dots for carousels — uses [activeIndex] (no PageController required).
class AppSmoothPageIndicator extends StatelessWidget {
  const AppSmoothPageIndicator({
    super.key,
    required this.activeIndex,
    required this.count,
    this.onDotClicked,
  });

  final int activeIndex;
  final int count;
  final void Function(int index)? onDotClicked;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return AnimatedSmoothIndicator(
      activeIndex: activeIndex,
      count: count,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      onDotClicked: onDotClicked,
      effect: WormEffect(
        dotHeight: 6,
        dotWidth: 6,
        spacing: 8,
        radius: 8,
        type: WormType.normal,
        activeDotColor: AppColors.primary,
        dotColor: AppColors.gray600.withValues(alpha: 0.45),
      ),
    );
  }
}

/// Dots overlaid on photos (white worm on dark pill).
class AppSmoothPageIndicatorOnDark extends StatelessWidget {
  const AppSmoothPageIndicatorOnDark({
    super.key,
    required this.activeIndex,
    required this.count,
    this.onDotClicked,
  });

  final int activeIndex;
  final int count;
  final void Function(int index)? onDotClicked;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedSmoothIndicator(
        activeIndex: activeIndex,
        count: count,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        onDotClicked: onDotClicked,
        effect: WormEffect(
          dotHeight: 6,
          dotWidth: 6,
          spacing: 8,
          radius: 8,
          type: WormType.normal,
          activeDotColor: AppColors.onPrimary,
          dotColor: AppColors.onPrimary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
