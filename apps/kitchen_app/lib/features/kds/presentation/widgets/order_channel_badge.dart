import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';

/// A small pill showing the order channel: Delivery or Pickup.
class OrderChannelBadge extends StatelessWidget {
  final dynamic order;

  const OrderChannelBadge({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderType = (order['orderType'] ?? order['deliveryType'])?.toString().toUpperCase();
    final isPickup = orderType == 'PICKUP' || order['isPickup'] == true;

    final label = isPickup ? 'Pickup' : 'Delivery';
    final icon = isPickup ? Iconsax.shop : Iconsax.truck_fast;
    final color = isPickup ? AppColors.info : AppColors.pandaPink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
