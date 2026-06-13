import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';

/// CWT [TSearchContainer] — tappable search row for headers and store screens.
class AppSearchContainer extends StatelessWidget {
  const AppSearchContainer({
    super.key,
    required this.hint,
    this.icon = AppIcons.search,
    this.showBackground = true,
    this.showBorder = true,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.backgroundColor,
  });

  final String hint;
  final IconData icon;
  final VoidCallback? onTap;
  final bool showBackground;
  final bool showBorder;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hintStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        );

    return Padding(
      padding: padding,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: showBackground ? (backgroundColor ?? AppColors.surface) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: showBorder ? Border.all(color: AppColors.border) : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    hint,
                    style: hintStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
