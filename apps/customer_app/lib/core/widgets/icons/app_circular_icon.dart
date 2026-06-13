import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// CWT [TCircularIcon].
class AppCircularIcon extends StatelessWidget {
  const AppCircularIcon({
    super.key,
    required this.icon,
    this.width,
    this.height,
    this.size = 22,
    this.onPressed,
    this.color,
    this.backgroundColor,
  });

  final double? width;
  final double? height;
  final double size;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? AppSpacing.minTouchTarget,
      height: height ?? AppSpacing.minTouchTarget,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color ?? AppColors.textPrimary, size: size),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
