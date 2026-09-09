import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Visual tone for a [StatTile].
enum StatTone {
  /// Default — a bordered card on a dark surface (e.g. the home-sheet
  /// breakdown grid). Brand-red icon, white value, secondary label.
  surface,

  /// White card on the light app canvas (performance, earnings grids).
  card,

  /// For sitting on top of a brand-colored / gradient header (e.g. the
  /// earnings balance header). Translucent white fill, all-white content.
  onAccent,
}

/// A single stat card: an icon, a prominent [value], and a [label] beneath it.
///
/// Unifies the previously divergent `_StatTile` (home sheet) and `_StatCard`
/// (earnings) into one premium component.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tone = StatTone.surface,
  });

  final IconData icon;
  final String value;
  final String label;
  final StatTone tone;

  @override
  Widget build(BuildContext context) {
    final bool onAccent = tone == StatTone.onAccent;
    final bool onCard = tone == StatTone.card;

    final Color fill = onAccent
        ? Colors.white.withValues(alpha: 0.16)
        : onCard
            ? AppColors.surfaceLight
            : AppColors.surfaceElevated;
    final Color iconColor = onAccent ? Colors.white : AppColors.primary;
    final Color valueColor = onAccent ? Colors.white : AppColors.textPrimary;
    final Color labelColor =
        onAccent ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: onAccent
            ? null
            : Border.all(
                color: onCard ? AppColors.borderLight : AppColors.borderDark,
              ),
        boxShadow: onCard ? AppShadows.soft : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
