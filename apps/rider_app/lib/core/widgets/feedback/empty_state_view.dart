import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A brand-consistent view shown when a data set loads successfully but is
/// empty. Renders a teal-tinted [icon] above a [message], adapting to the
/// active light/dark theme.
///
/// Satisfies Requirement 9.2 (describe the absence of data) and 9.5 (teal
/// brand palette in both light and dark themes).
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.padding = const EdgeInsets.all(32),
  });

  /// The illustrative icon (rider app uses `lucide_icons_flutter` constants).
  final IconData icon;

  /// The primary line describing why the view is empty.
  final String message;

  /// Optional emphasized heading rendered above [message].
  final String? title;

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
                color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
            ],
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
          ],
        ),
      ),
    );
  }
}
