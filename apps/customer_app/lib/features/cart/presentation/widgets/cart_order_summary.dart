import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../providers/cart_provider.dart';
import 'coupon_section.dart';

/// Order-summary block on the cart screen: subtotal, standard delivery,
/// optional discount, and the coupon entry.
class CartOrderSummary extends StatelessWidget {
  const CartOrderSummary({super.key, required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subtotal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              AppFormatter.formatCurrency(cart.subtotal),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Standard delivery',
              style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
            Text(
              'Tk 19',
              style: TextStyle(fontSize: 14, color: Color(0xFF111827)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (cart.discount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discount',
                style: TextStyle(fontSize: 14, color: AppColors.success),
              ),
              Text(
                '-${AppFormatter.formatCurrency(cart.discount)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else ...[
          const SizedBox(height: 16),
        ],

        // Interactive Voucher Section
        const CouponSection(),
      ],
    );
  }
}
