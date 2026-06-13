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
      top: 12,
      left: 0,
      child: AppRoundedContainer(
        radius: AppSpacing.radiusSm,
        backgroundColor: AppColors.primary.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
