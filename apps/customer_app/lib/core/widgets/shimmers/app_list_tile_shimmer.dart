import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/responsive/app_responsive.dart';
import 'app_shimmer_effect.dart';

/// Single list row shimmer (CWT [TListTileShimmer]).
class AppListTileShimmer extends StatelessWidget {
  const AppListTileShimmer({super.key, this.imageSize = 88});

  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmerEffect(width: imageSize, height: imageSize, radius: AppSpacing.radiusMd),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmerEffect(width: double.infinity, height: 15, radius: 4),
                SizedBox(height: AppSpacing.sm),
                AppShimmerEffect(width: 160, height: 12, radius: 4),
                SizedBox(height: AppSpacing.sm),
                AppShimmerEffect(width: 70, height: 14, radius: 4),
                SizedBox(height: AppSpacing.sm),
                AppShimmerEffect(width: 100, height: 11, radius: 4),
              ],
            ),
          ),
          AppShimmerEffect(width: 22, height: 22, radius: 11),
        ],
      ),
    );
  }
}

class AppListTileShimmerList extends StatelessWidget {
  const AppListTileShimmerList({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    final imageSize = AppResponsive.value(context, mobile: 88.0, tablet: 96.0, desktop: 104.0);

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, __) => AppListTileShimmer(imageSize: imageSize),
    );
  }
}
