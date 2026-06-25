import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DispatchStatusChip extends StatelessWidget {
  final dynamic order;

  const DispatchStatusChip({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _resolve(order as Map<String, dynamic>);
    if (label.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static (String label, Color color, IconData icon) _resolve(
    Map<String, dynamic> order,
  ) {
    if (order['deliveryService'] != null) {
      return ('Pathao dispatched', AppColors.info, Icons.local_shipping_rounded);
    }

    final assignment = order['assignment'];
    if (assignment is! Map) {
      final status = order['status']?.toString();
      if (status == 'ACCEPTED' || status == 'PREPARING' || status == 'READY_FOR_PICKUP') {
        return ('Finding rider...', AppColors.warning, Icons.search_rounded);
      }
      return ('', AppColors.gray700, Icons.circle);
    }

    final aStatus = assignment['status']?.toString();
    final riderName = assignment['rider']?['fullName']?.toString() ??
        assignment['courier']?['name']?.toString();

    return switch (aStatus) {
      'NOTIFIED' => ('Finding rider...', AppColors.warning, Icons.search_rounded),
      'ACCEPTED' when riderName != null => (
          'Rider: $riderName',
          AppColors.success,
          Icons.pedal_bike_rounded,
        ),
      'ACCEPTED' => ('Rider assigned', AppColors.success, Icons.pedal_bike_rounded),
      'ARRIVED' => ('Rider arrived', AppColors.success, Icons.place_rounded),
      'REJECTED' => ('Rejected — reassigning', AppColors.warning, Icons.replay_rounded),
      'EXPIRED' => ('Timed out — reassigning', AppColors.warning, Icons.timer_off_rounded),
      'CANCELLED' => ('Unassigned', AppColors.gray700, Icons.cancel_rounded),
      _ => ('Finding rider...', AppColors.warning, Icons.search_rounded),
    };
  }
}
