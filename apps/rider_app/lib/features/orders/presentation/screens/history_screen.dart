import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/empty_state_view.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../providers/rider_orders_provider.dart';
import '../widgets/order_summary_card.dart';
import 'delivered_order_detail_screen.dart';

/// Delivery History — past (delivered/cancelled) orders.
///
/// Lists terminal orders as tappable summary cards; tapping opens the
/// delivered-order detail with departure/arrival times and item thumbnails.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(pastOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(riderOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyStateView(
              icon: LucideIcons.clock,
              title: 'No deliveries yet',
              message: 'Your completed deliveries will show up here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(riderOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, i) {
                final order = orders[i];
                return OrderSummaryCard(
                  order: order,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DeliveredOrderDetailScreen(order: order),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
