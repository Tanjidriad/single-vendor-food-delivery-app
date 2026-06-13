import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// Base shimmer block for skeleton loaders.
///
/// The public API (width/height/radius/color) is kept stable so call sites
/// don't change. Colors are themed from [AppColors]:
/// - Light base:      [AppColors.borderLight]
/// - Light highlight: [AppColors.primaryLight]
/// - Dark base:       [AppColors.surfaceElevated]
/// - Dark highlight:  a lifted gray that's bright enough to read as a sweep
///   against the dark canvas.
class AppShimmerEffect extends StatelessWidget {
  const AppShimmerEffect({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppRadius.md,
    this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceElevated : AppColors.borderLight,
      highlightColor:
          isDark ? const Color(0xFF3A3A44) : AppColors.primaryLight,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ??
              (isDark ? AppColors.surfaceElevated : AppColors.backgroundLight),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
