import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';

/// Base shimmer block (ported from CWT [TShimmerEffect], themed for this app).
class AppShimmerEffect extends StatelessWidget {
  const AppShimmerEffect({
    super.key,
    required this.width,
    required this.height,
    this.radius = 15,
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
      baseColor: isDark ? AppColors.black300 : AppColors.gray600,
      highlightColor: isDark ? AppColors.black200 : AppColors.gray200,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? (isDark ? AppColors.black400 : AppColors.gray400),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
