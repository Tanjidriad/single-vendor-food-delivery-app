import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Full-width primary action button with a soft brand-red glow. Falls back to
/// the theme's elevated-button styling for colors, so passing nothing yields
/// the brand red. Press feedback comes from the Material ink/overlay.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;

  /// Optional leading icon.
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.icon,
  });

  bool get _enabled => !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final Color fill = color ?? AppColors.primary;
    final Color fg = textColor ?? Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: _enabled ? AppShadows.glow(fill) : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: fill,
            foregroundColor: fg,
            disabledBackgroundColor: fill.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: _buildChild(fg),
        ),
      ),
    );
  }

  Widget _buildChild(Color fg) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    }
    final label = Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
    if (icon == null) return label;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(width: AppSpacing.sm),
        label,
      ],
    );
  }
}
