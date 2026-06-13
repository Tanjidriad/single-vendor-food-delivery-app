import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'app_shimmer_effect.dart';

/// CWT [TVerticalProductShimmer] for product grids.
class AppVerticalProductShimmer extends StatelessWidget {
  const AppVerticalProductShimmer({
    super.key,
    this.itemCount = 4,
    this.cardWidth = 180,
  });

  final int itemCount;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.lg,
      children: List.generate(
        itemCount,
        (_) => SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmerEffect(width: cardWidth, height: cardWidth),
              const SizedBox(height: AppSpacing.md),
              AppShimmerEffect(width: cardWidth * 0.9, height: 14, radius: 4),
              const SizedBox(height: AppSpacing.sm),
              AppShimmerEffect(width: cardWidth * 0.55, height: 14, radius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
