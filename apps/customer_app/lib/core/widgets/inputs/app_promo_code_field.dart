import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';

import '../../theme/app_colors.dart';

/// Promo / coupon pill (Figma — Search Input Rounded: tag + "Enter Promo code").
class AppPromoCodeField extends StatelessWidget {
  const AppPromoCodeField({
    super.key,
    required this.controller,
    this.hint = 'Enter Promo code',
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(99),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(AppIcons.tag, size: 22, color: AppColors.black500),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 20 / 16,
                    color: AppColors.textPrimary,
                  ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 20 / 16,
                      color: AppColors.textPrimary,
                    ),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}
