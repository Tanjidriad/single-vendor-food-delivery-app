import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../shimmers/app_list_tile_shimmer.dart';
import '../shimmers/app_shimmer_effect.dart';

/// Thin wrapper — prefer [AppShimmerEffect] or section shimmers under `core/widgets/shimmers/`.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppSpacing.radiusMd,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AppShimmerEffect(width: width, height: height, radius: radius);
  }
}

class MenuListSkeleton extends StatelessWidget {
  const MenuListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AppListTileShimmerList(count: count);
  }
}
