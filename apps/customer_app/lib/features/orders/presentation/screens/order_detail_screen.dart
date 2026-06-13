import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_status_colors.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../../../core/utils/helpers/helper_functions.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../data/orders_repository.dart';
import '../providers/orders_providers.dart';
import '../widgets/reorder_button.dart';
import '../widgets/review_order_sheet.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final isDark = AppHelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.gray100,
      appBar: AppBar(
        title: orderAsync.when(
          data: (o) => Text('Order #${o['orderNumber']}'),
          loading: () => const Text('Order'),
          error: (_, __) => const Text('Order'),
        ),
      ),
      body: orderAsync.when(
        data: (order) => _OrderBody(order: order, orderId: orderId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
      ),
    );
  }
}

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order, required this.orderId});

  final Map<String, dynamic> order;
  final String orderId;

  bool get _canCancel {
    final s = order['status'] as String? ?? '';
    return s == 'PLACED' || s == 'ACCEPTED';
  }

  bool get _canReview => order['status'] == 'DELIVERED';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppHelperFunctions.isDarkMode(context);
    final textTheme = Theme.of(context).textTheme;
    final status = order['status'] as String? ?? 'PLACED';
    final items = order['items'] as List<dynamic>? ?? [];
    final statusColor = AppStatusColors.forStatus(status);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.black400 : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.replaceAll('_', ' '),
                            style: textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order['deliveryAddress'] as String? ?? 'Delivery',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatter.formatCurrency(
                        (order['grandTotal'] as num?)?.toDouble() ?? 0,
                      ),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ITEMS',
                style: textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              ...items.map((raw) {
                final item = raw as Map<String, dynamic>;
                final qty = item['quantity'] as int? ?? 1;
                final name = item['name'] as String? ?? 'Item';
                final total = (item['lineTotal'] as num?)?.toDouble() ??
                    (item['unitPrice'] as num?)?.toDouble() ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.black400 : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text('$qty×', style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          )),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name, style: textTheme.bodyMedium)),
                      Text(
                        AppFormatter.formatCurrency(total),
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              _feeRow('Subtotal', order['subtotal']),
              _feeRow('Delivery', order['deliveryFee']),
              if ((order['discountAmount'] as num?)?.toDouble() != null &&
                  (order['discountAmount'] as num).toDouble() > 0)
                _feeRow('Discount', order['discountAmount'], negative: true),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                AppButton(
                  label: 'Track order',
                  icon: const Icon(Iconsax.routing, size: 18, color: AppColors.onPrimary),
                  onPressed: () => context.push(RoutePaths.trackingWithId(orderId)),
                ),
                if (_canCancel) ...[
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Cancel order',
                    variant: AppButtonVariant.destructive,
                    onPressed: () => _cancel(context, ref),
                  ),
                ],
                const SizedBox(height: 10),
                ReorderButton(orderId: orderId),
                if (_canReview) ...[
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Rate order',
                    variant: AppButtonVariant.outline,
                    onPressed: () => ReviewOrderSheet.show(context, orderId),
                  ),
                ],
                const SizedBox(height: 10),
                AppButton(
                  label: 'Get help',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.push(
                    '${RoutePaths.support}?orderId=$orderId',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _feeRow(String label, dynamic value, {bool negative = false}) {
    final amount = (value as num?)?.toDouble() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            '${negative ? '- ' : ''}${AppFormatter.formatCurrency(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: negative ? AppColors.success : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('This cannot be undone if the kitchen has not started preparing.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel order')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(ordersRepositoryProvider).cancelOrder(orderId);
      ref.invalidate(orderDetailProvider(orderId));
      if (context.mounted) {
        AppLoaders.successSnackBar(context, title: 'Cancelled', message: 'Order was cancelled');
      }
    } catch (e) {
      if (context.mounted) {
        AppLoaders.errorSnackBar(context, title: 'Failed', message: '$e');
      }
    }
  }
}
