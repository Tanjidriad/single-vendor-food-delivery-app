import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// A pill describing an order's current status, in the ZIPS visual language:
/// a tinted background + icon + label, colored by lifecycle stage
/// (in-progress amber, picked-up/on-the-way blue, delivered green ✓,
/// cancelled red ✕).
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  /// Backend OrderStatus value (PLACED, ACCEPTED, …, DELIVERED, CANCELLED).
  final String status;

  ({Color color, IconData icon, String label}) get _style {
    switch (status) {
      case 'DELIVERED':
        return (
          color: AppColors.online,
          icon: LucideIcons.circleCheck,
          label: 'Delivered',
        );
      case 'CANCELLED':
      case 'REJECTED':
      case 'IGNORED_TEST':
        return (
          color: AppColors.offline,
          icon: LucideIcons.circleX,
          label: status == 'CANCELLED' ? 'Cancelled' : status == 'REJECTED' ? 'Rejected' : 'Test Order',
        );
      case 'PICKED_UP':
        return (
          color: AppColors.inProgress,
          icon: LucideIcons.packageCheck,
          label: 'Picked up',
        );
      case 'ON_THE_WAY':
        return (
          color: AppColors.inProgress,
          icon: LucideIcons.navigation,
          label: 'On the way',
        );
      case 'READY_FOR_PICKUP':
        return (
          color: AppColors.primary,
          icon: LucideIcons.package,
          label: 'Pickup',
        );
      default:
        return (
          color: AppColors.busy,
          icon: LucideIcons.clock,
          label: 'In progress',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: s.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 14, color: s.color),
          const SizedBox(width: 5),
          Text(
            s.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: s.color,
            ),
          ),
        ],
      ),
    );
  }
}
