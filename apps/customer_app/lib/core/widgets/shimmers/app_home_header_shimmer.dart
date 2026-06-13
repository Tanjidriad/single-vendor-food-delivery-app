import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'app_category_shimmer.dart';
import 'app_shimmer_effect.dart';

/// Home curved header loading placeholder.
class AppHomeHeaderShimmer extends StatelessWidget {
  const AppHomeHeaderShimmer({super.key, this.onPrimary = false});

  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    final blockColor = onPrimary ? AppColors.onPrimary.withValues(alpha: 0.2) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            AppShimmerEffect(width: 44, height: 44, radius: 44),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerEffect(width: 80, height: 10, radius: 4),
                  SizedBox(height: 6),
                  AppShimmerEffect(width: 140, height: 16, radius: 4),
                ],
              ),
            ),
            AppShimmerEffect(width: 44, height: 44, radius: 44),
            SizedBox(width: AppSpacing.sm),
            AppShimmerEffect(width: 44, height: 44, radius: 44),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppShimmerEffect(
          width: double.infinity,
          height: 44,
          radius: AppSpacing.radiusLg,
          color: blockColor,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (onPrimary)
          AppShimmerEffect(width: 120, height: 14, radius: 4, color: blockColor),
        if (onPrimary) const SizedBox(height: AppSpacing.md),
        const AppCategoryShimmer(itemCount: 5),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
