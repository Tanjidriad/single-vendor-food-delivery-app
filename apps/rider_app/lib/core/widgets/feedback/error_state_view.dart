import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';

/// A brand-consistent view shown when a data request fails. Surfaces the
/// failure [message] and a retry control that invokes [onRetry], adapting to
/// the active light/dark theme.
///
/// Satisfies Requirement 9.3 (failure reason + retry control), 9.4 (retry
/// re-requests the data via [onRetry]), and 9.5 (teal brand palette in both
/// light and dark themes).
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = LucideIcons.refreshCw,
    this.title = 'Something went wrong',
    this.retryLabel = 'Retry',
    this.padding = const EdgeInsets.all(32),
  });

  /// The failure reason to present to the rider.
  final String message;

  /// Invoked when the rider activates the retry control.
  final VoidCallback onRetry;

  /// The icon illustrating the error state.
  final IconData icon;

  /// Emphasized heading rendered above [message].
  final String title;

  /// Label for the retry control.
  final String retryLabel;

  /// Outer padding around the content.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = AppColors.textSecondary;
    final primaryText = isDark ? AppColors.textInverse : AppColors.textOnLight;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.offline.withValues(alpha: isDark ? 0.20 : 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.circleAlert,
                size: 40,
                color: AppColors.offline,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(icon, size: 18, color: AppColors.primary),
              label: Text(
                retryLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
