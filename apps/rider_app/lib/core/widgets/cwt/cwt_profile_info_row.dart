import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// Read-only title → value row (CWT ecommerce profile menu style).
class CwtProfileInfoRow extends StatelessWidget {
  const CwtProfileInfoRow({
    super.key,
    required this.title,
    required this.value,
    this.showDivider = true,
    this.showChevron = false,
  });

  final String title;
  final String value;
  final bool showDivider;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '—' : value;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  display,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showChevron)
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.textDisabled,
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.borderLight),
      ],
    );
  }
}
