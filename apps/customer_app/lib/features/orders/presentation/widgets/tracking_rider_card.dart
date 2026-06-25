import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/order_tracking_provider.dart';

/// Rider contact card on the order-tracking screen (avatar, name, call/chat).
class TrackingRiderCard extends StatelessWidget {
  const TrackingRiderCard({
    super.key,
    required this.rider,
    required this.onCall,
    this.onMessage,
  });

  final OrderRiderInfo rider;
  final VoidCallback onCall;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final canContact = rider.isAssigned && rider.phone != null;
    final canMessage = rider.isAssigned && onMessage != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: rider.isAssigned
                ? AppColors.primary.withValues(alpha: 0.12)
                : const Color(0xFFE5E7EB),
            child: Icon(
              Icons.person,
              color: rider.isAssigned ? AppColors.primary : const Color(0xFF9CA3AF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  rider.subtitle,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          if (canMessage) ...[
            InkWell(
              onTap: onMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          InkWell(
            onTap: canContact ? onCall : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: canContact
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call,
                color: canContact ? AppColors.primary : const Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
