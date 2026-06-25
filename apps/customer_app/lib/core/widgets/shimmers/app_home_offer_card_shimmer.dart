import 'package:flutter/material.dart';

import '../../theme/home_offer_card_layout.dart';
import '../../theme/app_spacing.dart';
import 'app_shimmer_effect.dart';

/// Uber-style offer card loading placeholder.
class AppHomeOfferCardShimmer extends StatelessWidget {
  const AppHomeOfferCardShimmer({
    super.key,
    this.width,
    this.compact = false,
  });

  final double? width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageWidth = width ?? double.infinity;
    final imageHeight = width != null ? width! / (16 / 9) : 200.0;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmerEffect(
            width: imageWidth,
            height: imageHeight,
            radius: HomeOfferCardLayout.imageCornerRadius,
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmerEffect(width: 140, height: 16, radius: 4),
                    SizedBox(height: 8),
                    AppShimmerEffect(width: 200, height: 12, radius: 4),
                  ],
                ),
              ),
              AppShimmerEffect(width: 36, height: 36, radius: 36),
            ],
          ),
          if (!compact) const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Horizontal carousel shimmer row.
class AppHomeOfferCarouselShimmer extends StatelessWidget {
  const AppHomeOfferCarouselShimmer({super.key, required this.cardWidth, this.count = 2});

  final double cardWidth;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardWidth / (16 / 9) + 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => AppHomeOfferCardShimmer(width: cardWidth, compact: true),
      ),
    );
  }
}

/// Vertical list shimmer.
class AppHomeOfferListShimmer extends StatelessWidget {
  const AppHomeOfferListShimmer({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          count,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppHomeOfferCardShimmer(),
          ),
        ),
      ),
    );
  }
}
