import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

/// Order line items and the price breakdown (subtotal, fees, discount, total)
/// shown at the bottom of the checkout screen.
class CheckoutPriceSummary extends StatelessWidget {
  const CheckoutPriceSummary({
    super.key,
    required this.cart,
    required this.deliveryFee,
    required this.tax,
    required this.packaging,
    required this.quoteLoading,
    required this.total,
  });

  final CartState cart;
  final double? deliveryFee;
  final double? tax;
  final double? packaging;
  final bool quoteLoading;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in cart.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.quantity}x ${item.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  AppFormatter.formatCurrency(item.unitPrice * item.quantity),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                ),
              ],
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Color(0xFFE5E7EB)),
        ),
        _row('Subtotal', AppFormatter.formatCurrency(cart.subtotal),
            boldLabel: true),
        const SizedBox(height: 8),
        _row(
          'Delivery Fee',
          quoteLoading && deliveryFee == null
              ? 'Calculating…'
              : AppFormatter.formatCurrency(deliveryFee ?? 0),
          labelColor: const Color(0xFF374151),
        ),
        if ((tax ?? 0) > 0) ...[
          const SizedBox(height: 8),
          _row('Tax', AppFormatter.formatCurrency(tax!),
              labelColor: const Color(0xFF374151)),
        ],
        if ((packaging ?? 0) > 0) ...[
          const SizedBox(height: 8),
          _row('Packaging Fee', AppFormatter.formatCurrency(packaging!),
              labelColor: const Color(0xFF374151)),
        ],
        if (cart.discount > 0) ...[
          const SizedBox(height: 8),
          _row(
            'Discount',
            '-${AppFormatter.formatCurrency(cart.discount)}',
            boldLabel: true,
            labelColor: AppColors.success,
            valueColor: AppColors.success,
            boldValue: true,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '(incl. fees and tax)',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            Text(
              AppFormatter.formatCurrency(total),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(
    String label,
    String value, {
    bool boldLabel = false,
    bool boldValue = false,
    Color labelColor = const Color(0xFF111827),
    Color valueColor = const Color(0xFF111827),
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: boldLabel ? FontWeight.bold : FontWeight.normal,
            color: labelColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: boldValue ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
