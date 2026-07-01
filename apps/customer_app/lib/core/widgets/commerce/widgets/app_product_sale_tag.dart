import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../shapes/app_rounded_container.dart';

/// CWT [ProductSaleTagWidget].
class AppProductSaleTag extends StatelessWidget {
  const AppProductSaleTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 0,
      child: AppRoundedContainer(
        radius: AppSpacing.radiusSm,
        backgroundColor: AppColors.brutalistYellow,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
