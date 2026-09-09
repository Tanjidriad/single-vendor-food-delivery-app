import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/presentation/providers/orders_providers.dart';

class FloatingActiveOrderCard extends ConsumerWidget {
  const FloatingActiveOrderCard({super.key});

  String _formatStatus(String status) {
    switch (status) {
      case 'PLACED':
        return 'Waiting for confirmation...';
      case 'ACCEPTED':
        return 'Order accepted';
      case 'PREPARING':
        return 'Preparing your food';
      case 'READY_FOR_PICKUP':
        return 'Ready for pickup';
      case 'PICKED_UP':
      case 'ON_THE_WAY':
        return 'On the way';
      default:
        return 'Processing...';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PLACED':
        return Iconsax.timer_1;
      case 'ACCEPTED':
        return Iconsax.tick_circle;
      case 'PREPARING':
        return Iconsax.reserve;
      case 'READY_FOR_PICKUP':
        return Iconsax.bag_tick;
      case 'PICKED_UP':
      case 'ON_THE_WAY':
        return Iconsax.truck_fast;
      default:
        return Iconsax.box;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrderAsync = ref.watch(activeOrderProvider);

    return activeOrderAsync.when(
      data: (order) {
        if (order == null) return const SizedBox.shrink();

        final status = order.status;
        final restaurant = order.raw['restaurant'];
        final restaurantName =
            (restaurant is Map ? restaurant['name'] as String? : null) ??
                'Restaurant';
        final orderId = order.id;

        return Positioned(
          left: 16,
          right: 16,
          bottom: 24, // Floats above the bottom navigation bar
          child: GestureDetector(
            onTap: () {
              context.push(RoutePaths.trackingWithId(orderId));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatStatus(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          restaurantName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ).animate()
             .slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOutBack)
             .fadeIn(duration: 400.ms),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
