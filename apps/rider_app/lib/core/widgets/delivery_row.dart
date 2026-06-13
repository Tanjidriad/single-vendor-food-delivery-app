import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// A single delivery / earnings line item: a tinted leading icon, a
/// [title]/[subtitle] block, and a trailing [amount].
///
/// Unifies the previously divergent `_DeliveryRow` (home sheet) and
/// `_HistoryTile` (earnings) into one component. By default it reads as a
/// positive earning (green amount, no sign); set [signed] to prefix `+`/`-`
/// and [isPositive] to flip the color for debits.
class DeliveryRow extends StatelessWidget {
  const DeliveryRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.icon = LucideIcons.bike,
    this.isPositive = true,
    this.signed = false,
  });

  final String title;
  final String subtitle;

  /// Pre-formatted amount (e.g. `"Tk 125.50"`).
  final String amount;
  final IconData icon;
  final bool isPositive;

  /// When true, prefixes the amount with `+`/`-` per [isPositive].
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final Color accent = isPositive ? AppColors.online : AppColors.offline;
    final String displayAmount =
        signed ? '${isPositive ? '+' : '-'} $amount' : amount;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            displayAmount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
