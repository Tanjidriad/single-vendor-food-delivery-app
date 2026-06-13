import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/responsive/app_responsive.dart';
import 'app_shimmer_effect.dart';

/// Horizontal promo / product cards (CWT [THorizontalProductShimmer] layout).
class AppHorizontalPromoShimmer extends StatelessWidget {
  const AppHorizontalPromoShimmer({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final cardWidth = AppResponsive.homePromoCardWidth(context);
    final rowHeight = AppResponsive.homePromoRowHeight(context);
    final padding = AppResponsive.pagePadding(context);

    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) => SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmerEffect(
                width: cardWidth,
                height: cardWidth / 1.15,
                radius: AppSpacing.radiusMd,
              ),
              const SizedBox(height: 10),
              const AppShimmerEffect(width: 140, height: 14, radius: 4),
              const SizedBox(height: 6),
              const AppShimmerEffect(width: 90, height: 12, radius: 4),
              const SizedBox(height: 6),
              const AppShimmerEffect(width: 60, height: 14, radius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
