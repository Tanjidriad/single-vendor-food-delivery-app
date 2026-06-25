import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Delivery-time + address row at the top of the cart list, with an
/// Add/Change action that opens address selection.
class CartDeliveryRow extends StatelessWidget {
  const CartDeliveryRow({
    super.key,
    required this.timeLabel,
    required this.addressLabel,
    required this.hasAddress,
    required this.onChangeAddress,
  });

  final String timeLabel;
  final String addressLabel;
  final bool hasAddress;
  final VoidCallback onChangeAddress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  addressLabel,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeAddress,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              hasAddress ? 'Change' : 'Add',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
