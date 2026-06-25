import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

class HomeFilterChip extends StatelessWidget {
  const HomeFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingEmoji,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? leadingEmoji;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.gray200,
            borderRadius: BorderRadius.circular(50),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingEmoji != null) ...[
                Text(leadingEmoji!, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
              ],
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13.5,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
