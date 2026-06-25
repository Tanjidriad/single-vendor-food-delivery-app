import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import 'app_shimmer_effect.dart';

enum TabLoadingStyle { list, card, heroAndList }

/// Context-aware skeleton loader for tab screens.
class TabLoadingView extends StatelessWidget {
  const TabLoadingView({
    super.key,
    this.style = TabLoadingStyle.list,
    this.itemCount = 4,
  });

  final TabLoadingStyle style;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case TabLoadingStyle.heroAndList:
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            const AppShimmerEffect(
              width: double.infinity,
              height: 160,
              radius: AppRadius.xl,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < itemCount; i++) ...[
              const _RowSkeleton(),
              if (i < itemCount - 1) const SizedBox(height: AppSpacing.lg),
            ],
          ],
        );
      case TabLoadingStyle.card:
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screen),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
          itemBuilder: (_, _) => const AppShimmerEffect(
            width: double.infinity,
            height: 140,
            radius: AppRadius.lg,
            color: AppColors.surfaceLight,
          ),
        );
      case TabLoadingStyle.list:
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screen),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
          itemBuilder: (_, _) => const _RowSkeleton(),
        );
    }
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
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
  }
}
