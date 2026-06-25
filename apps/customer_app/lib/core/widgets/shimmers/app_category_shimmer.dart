import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'app_shimmer_effect.dart';

/// Horizontal category row shimmer (CWT [TCategoryShimmer]).
class AppCategoryShimmer extends StatelessWidget {
  const AppCategoryShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, _) => const Column(
          children: [
            AppShimmerEffect(width: 55, height: 55, radius: 55),
            SizedBox(height: AppSpacing.sm),
            AppShimmerEffect(width: 55, height: 8, radius: 4),
          ],
        ),
      ),
    );
  }
}
