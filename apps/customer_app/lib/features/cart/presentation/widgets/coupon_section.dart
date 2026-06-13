import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers/helper_functions.dart';
import '../providers/cart_provider.dart';
import 'voucher_selection_sheet.dart';

class CouponSection extends ConsumerWidget {
  const CouponSection({super.key});

  void _openVoucherSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoucherSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final isDark = AppHelperFunctions.isDarkMode(context);

    if (cart.couponCode != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code: ${cart.couponCode}', 
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14)
                  ),
                  Text(
                    '- ৳${cart.discount.toStringAsFixed(0)}', 
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12)
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.primary),
              onPressed: () => ref.read(cartProvider.notifier).setCoupon(null, 0),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _openVoucherSheet(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.confirmation_num_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Apply a voucher',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w700, 
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black54),
          ],
        ),
      ),
    );
  }
}
