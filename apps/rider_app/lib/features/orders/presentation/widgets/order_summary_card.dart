import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/layouts/app_card.dart';
import '../../data/order_summary.dart';
import 'order_status_chip.dart';

/// Clean, premium order card: order number + status, a simple pickup→drop
/// summary, and a footer with time and total. Used by the Orders and History
/// tabs.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.order, this.onTap});

  final OrderSummary order;
  final VoidCallback? onTap;

  String? get _stepHint {
    if (!order.isActive) return null;
    return switch (order.status) {
      'READY_FOR_PICKUP' => 'Head to pickup',
      'PICKED_UP' => 'Confirm pickup complete',
      'ON_THE_WAY' => 'On the way to customer',
      _ => 'Tap to open delivery',
    };
  }

  DateTime? get _timestamp => order.deliveredAt ?? order.placedAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: order number + status ---
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber.isEmpty
                      ? 'Order'
                      : 'Order #${order.orderNumber}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OrderStatusChip(status: order.status),
            ],
          ),
          if (_stepHint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _stepHint!,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // --- ROUTE: pickup → drop ---
          _RouteLine(
            icon: LucideIcons.store,
            iconColor: AppColors.primary,
            label: order.restaurantName ?? 'Pickup location',
          ),
          const SizedBox(height: AppSpacing.sm),
          _RouteLine(
            icon: LucideIcons.mapPin,
            iconColor: AppColors.textSecondary,
            label: order.deliveryAddress ?? 'Delivery location',
            muted: true,
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: AppSpacing.md),

          // --- FOOTER: time + total ---
          Row(
            children: [
              if (_timestamp != null) ...[
                const Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  formatRelativeTime(_timestamp!),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              if (order.grandTotal != null)
                Text(
                  formatCurrency(order.grandTotal!),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single pickup/drop line: small leading icon + ellipsized label.
class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.muted = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                  color: muted ? AppColors.textSecondary : AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
