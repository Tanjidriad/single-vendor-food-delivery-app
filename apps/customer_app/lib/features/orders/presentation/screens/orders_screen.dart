import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../../../core/utils/helpers/helper_functions.dart';
import '../../../../core/widgets/cwt/empty_state_widget.dart';
import '../providers/orders_providers.dart';
import '../widgets/reorder_button.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersListProvider);
    final isDark = AppHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.gray100,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'My Orders',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.white50 : AppColors.textPrimary,
              ),
        ),
        backgroundColor: isDark ? AppColors.background : AppColors.gray100,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: orders.when(
        data: (list) {
          if (list.isEmpty) {
            return const AppEmptyStateWidget(
              title: 'No orders yet',
              subtitle: 'Your order history will appear here',
              animation: 'assets/images/53207-empty-file.json',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ordersListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final o = list[i];
                final status = o.status;

                final formattedDate = o.createdAt != null
                    ? AppHelperFunctions.formatDate(o.createdAt!)
                    : 'Today';

                // Soft status colors
                Color statusBg = AppColors.primary.withValues(alpha: 0.1);
                Color statusText = AppColors.primary;
                if (status.toUpperCase() == 'DELIVERED') {
                  statusBg = const Color(0xFFE8F5E9);
                  statusText = const Color(0xFF2E7D32);
                } else if (status.toUpperCase() == 'CANCELLED') {
                  statusBg = const Color(0xFFFFEBEE);
                  statusText = const Color(0xFFC62828);
                } else if (status.toUpperCase() == 'PROCESSING') {
                  statusBg = const Color(0xFFFFF8E1);
                  statusText = const Color(0xFFF57F17);
                }

                return GestureDetector(
                  onTap: () => context.push(RoutePaths.orderDetailWithId(o.id)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.black400 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Icon Container
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.black500 : AppColors.gray100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Iconsax.receipt_24,
                                  size: 24,
                                  color: isDark ? Colors.white70 : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Order Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Order #${o.orderNumber ?? ''}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppFormatter.formatCurrency(o.grandTotal),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      formattedDate,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Soft Status Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.replaceAll('_', ' ').toUpperCase(),
                                        style: TextStyle(
                                          color: statusText,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Bottom action area
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.black500 : const Color(0xFFF9FAFB),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => context.push(RoutePaths.orderDetailWithId(o.id)),
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                icon: const Text(
                                  'View Details',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                label: const Icon(Iconsax.arrow_right_3, size: 16),
                              ),
                              ReorderButton(orderId: o.id, compact: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.invalidate(ordersListProvider),
        ),
      ),
    );
  }
}
