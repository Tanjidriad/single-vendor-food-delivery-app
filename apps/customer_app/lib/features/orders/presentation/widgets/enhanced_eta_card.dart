import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class EnhancedEtaCard extends StatefulWidget {
  final Map<String, dynamic> order;

  const EnhancedEtaCard({super.key, required this.order});

  @override
  State<EnhancedEtaCard> createState() => _EnhancedEtaCardState();
}

class _EnhancedEtaCardState extends State<EnhancedEtaCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update every minute to keep ETA fresh
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _calculateEta() {
    final status = widget.order['status'] as String? ?? 'PLACED';
    if (status == 'DELIVERED') return 'Delivered';
    if (status == 'CANCELLED' || status == 'REJECTED') return 'Cancelled';

    final createdAtStr = widget.order['createdAt'] as String?;
    if (createdAtStr == null) return 'Calculating...';

    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return 'Calculating...';

    // Base delivery time estimate
    int baseMinutes = 20; 
    
    // Add specific prep time if the kitchen provided it
    final prepMinutes = widget.order['prepMinutes'] as int?;
    if (prepMinutes != null) {
      baseMinutes = prepMinutes + 15; // Prep + 15 mins for delivery
    }

    final estimatedDeliveryTime = createdAt.add(Duration(minutes: baseMinutes));
    
    // If it's already past the estimated time but not delivered, just show "Arriving soon"
    if (_now.isAfter(estimatedDeliveryTime)) {
      return 'Arriving soon';
    }

    final diff = estimatedDeliveryTime.difference(_now);
    final minutesLeft = diff.inMinutes;
    
    if (minutesLeft < 2) return 'Arriving now';
    if (minutesLeft < 10) return '$minutesLeft min';
    
    // Range format: e.g. "12-17 min"
    return '${minutesLeft - 2}-${minutesLeft + 3} min';
  }

  String _getSubtitle() {
    final status = widget.order['status'] as String? ?? 'PLACED';
    switch (status) {
      case 'PLACED': return 'Waiting for restaurant to accept';
      case 'ACCEPTED': return 'Restaurant is reviewing your order';
      case 'PREPARING': return 'The kitchen is preparing your food';
      case 'READY_FOR_PICKUP': return 'Waiting for rider to pick up';
      case 'PICKED_UP': return 'Rider has picked up your order';
      case 'ON_THE_WAY': return 'Your order is on the way';
      case 'DELIVERED': return 'Enjoy your meal!';
      case 'CANCELLED':
      case 'REJECTED': return 'Order was cancelled';
      default: return 'Processing your order';
    }
  }

  @override
  Widget build(BuildContext context) {
    final eta = _calculateEta();
    final subtitle = _getSubtitle();
    final isDelivered = widget.order['status'] == 'DELIVERED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDelivered 
              ? [AppColors.success, const Color(0xFF2E7D32)]
              : [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDelivered ? AppColors.success : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDelivered ? 'Status' : 'Estimated Delivery',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: 
                  FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#${widget.order['orderNumber']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            eta,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
