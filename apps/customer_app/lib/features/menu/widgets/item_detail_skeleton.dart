import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shimmers/app_shimmer_effect.dart';

/// Loading placeholder for the item-detail screen.
class ItemDetailSkeleton extends StatelessWidget {
  const ItemDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: AppShimmerEffect(width: double.infinity, height: 300, radius: 0),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppShimmerEffect(width: 200, height: 32, radius: 8),
                      const AppShimmerEffect(width: 80, height: 32, radius: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const AppShimmerEffect(width: double.infinity, height: 16, radius: 4),
                  const SizedBox(height: 8),
                  const AppShimmerEffect(width: double.infinity, height: 16, radius: 4),
                  const SizedBox(height: 8),
                  const AppShimmerEffect(width: 150, height: 16, radius: 4),
                  const SizedBox(height: 40),
                  const AppShimmerEffect(width: 100, height: 24, radius: 8),
                  const SizedBox(height: 16),
                  const AppShimmerEffect(width: double.infinity, height: 80, radius: 16),
                  const SizedBox(height: 12),
                  const AppShimmerEffect(width: double.infinity, height: 80, radius: 16),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
