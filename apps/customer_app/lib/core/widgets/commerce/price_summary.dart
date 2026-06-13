import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters/formatter.dart';

class PriceSummary extends StatelessWidget {
  const PriceSummary({
    super.key,
    required this.subtotal,
    this.deliveryFee,
    this.tax,
    this.discount,
    this.packaging,
  });

  final double subtotal;
  final double? deliveryFee;
  final double? tax;
  final double? discount;
  final double? packaging;

  double get total =>
      subtotal +
      (deliveryFee ?? 0) +
      (tax ?? 0) +
      (packaging ?? 0) -
      (discount ?? 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(context, 'Subtotal', subtotal),
        if (deliveryFee != null) _row(context, 'Delivery fee', deliveryFee!),
        if (packaging != null && packaging! > 0) _row(context, 'Packaging', packaging!),
        if (tax != null && tax! > 0) _row(context, 'Tax', tax!),
        if (discount != null && discount! > 0)
          _row(context, 'Discount', -discount!, valueColor: AppColors.success),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.gray200, thickness: 1, height: 1),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Total',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const Spacer(),
            Text(
              AppFormatter.formatCurrency(total),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, double value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            AppFormatter.formatCurrency(value),
            style: AppTypography.price().copyWith(color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
