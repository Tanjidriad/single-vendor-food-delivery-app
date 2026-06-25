import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Banner shown on the tracking screen when a delivery failed or was returned,
/// with refund/charge messaging that depends on the payment method.
class TrackingDeliveryFailedCard extends StatelessWidget {
  const TrackingDeliveryFailedCard({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentMethod = order['paymentMethod'] as String? ?? 'COD';
    final paymentStatus = order['paymentStatus'] as String? ?? 'PENDING';
    final prepaid = paymentMethod == 'ONLINE' && paymentStatus == 'PAID';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Delivery issue',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            prepaid
                ? "We couldn't complete your delivery. Your refund is being processed — you'll hear from us within 24 hours."
                : "We couldn't complete your delivery. You were not charged for this order. Our team is resolving this now.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
