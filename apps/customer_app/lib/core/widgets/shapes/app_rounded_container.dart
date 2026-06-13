import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// CWT [TRoundedContainer] — rounded box with optional border.
class AppRoundedContainer extends StatelessWidget {
  const AppRoundedContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.margin,
    this.showBorder = false,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderColor = AppColors.border,
    this.radius = AppSpacing.radiusLg,
    this.backgroundColor = AppColors.surface,
  });

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsets? margin;
  final Widget? child;
  final Color backgroundColor;
  final Color borderColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder ? Border.all(color: borderColor) : null,
      ),
      child: child,
    );
  }
}
