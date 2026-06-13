import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/kitchen_preferences.dart';
import '../../domain/order_workflow.dart';

final dailyStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = ref.watch(kitchenPreferencesProvider);
  
  // Fetch today's completed orders
  final res = await apiClient.get('/orders/kitchen/history?includeTest=${prefs.showTestOrders}');
  final orders = res.data as List<dynamic>;
  
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  
  final todaysCompleted = orders.where((o) {
    final canonical = OrderWorkflowMapper.getCanonicalStatus(
      o,
      includeTestOrders: prefs.showTestOrders,
    );
    if (OrderWorkflowMapper.getSection(canonical) != KitchenSection.history) {
      return false;
    }
    
    final timeStr = o['deliveredAt'] ?? o['rejectedAt'] ?? o['cancelledAt'] ?? o['createdAt'];
    final actionTime = DateTime.tryParse(timeStr ?? '');
    if (actionTime == null) return false;
    return actionTime.isAfter(startOfDay);
  }).toList();

  int totalPrepMinutes = 0;
  int ordersWithPrepTime = 0;

  for (final o in todaysCompleted) {
    final acceptedAtStr = o['acceptedAt'];
    final readyAtStr = o['readyAt'];
    if (acceptedAtStr != null && readyAtStr != null) {
      final acceptedAt = DateTime.tryParse(acceptedAtStr);
      final readyAt = DateTime.tryParse(readyAtStr);
      if (acceptedAt != null && readyAt != null) {
        totalPrepMinutes += readyAt.difference(acceptedAt).inMinutes;
        ordersWithPrepTime++;
      }
    }
  }

  final avgPrepTime = ordersWithPrepTime > 0 
      ? (totalPrepMinutes / ordersWithPrepTime).round() 
      : 0;

  return {
    'completedOrders': todaysCompleted.length,
    'avgPrepTime': avgPrepTime,
    'orders': todaysCompleted,
  };
});

class DailyStatsView extends ConsumerWidget {
  const DailyStatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dailyStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading stats: $err')),
        data: (stats) {
          final prefs = ref.watch(kitchenPreferencesProvider);
          final completed = stats['completedOrders'] as int;
          final avgPrep = stats['avgPrepTime'] as int;
          
          return RefreshIndicator(
            onRefresh: () => ref.refresh(dailyStatsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Daily Kitchen Stats',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Orders Completed',
                        value: '$completed',
                        icon: Iconsax.tick_circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Avg Prep Time',
                        value: '$avgPrep min',
                        icon: Iconsax.clock,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Recent Completed Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                if (completed == 0)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No completed orders today.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...((stats['orders'] as List<dynamic>).take(10).map((order) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${order['orderNumber']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                OrderWorkflowMapper.getCanonicalStatus(
                                  order,
                                  includeTestOrders: prefs.showTestOrders,
                                ).name.replaceAll('ByKitchen', '').replaceAll('ByCustomer', '').replaceAll('BySystem', '').replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}').toUpperCase(),
                                style: TextStyle(
                                  color: order['status'] == 'REJECTED' || order['status'] == 'CANCELLED' ? AppColors.error : AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${order['grandTotal']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  })),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
