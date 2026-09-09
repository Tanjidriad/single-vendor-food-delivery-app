import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'app_shimmer_effect.dart';

/// Shimmer placeholder for list-based tab screens.
class ListSkeletonLoader extends StatelessWidget {
  const ListSkeletonLoader({
    super.key,
    this.itemCount = 4,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        return const Row(
          children: [
            AppShimmerEffect(width: 48, height: 48, radius: AppRadius.lg),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerEffect(width: double.infinity, height: 14),
                  SizedBox(height: AppSpacing.sm),
                  AppShimmerEffect(width: 120, height: 12),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
