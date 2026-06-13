import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Resend / timer chip (Figma 215:1135 — Timer Button).
class AppResendTimerChip extends StatelessWidget {
  const AppResendTimerChip({
    super.key,
    required this.label,
    this.enabled = false,
    this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 24 / 16,
                  color: enabled ? AppColors.textPrimary : const Color(0xFF7F7F7F),
                ),
          ),
        ),
      ),
    );
  }
}
