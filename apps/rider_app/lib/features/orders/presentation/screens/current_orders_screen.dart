import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/empty_state_view.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../data/orders_repository.dart';
import '../providers/active_order_restore.dart';
import '../providers/order_providers.dart';
import '../providers/rider_orders_provider.dart';
import '../widgets/order_summary_card.dart';

/// Current Orders — the rider's operational hub (center FAB tab).
///
/// Lists the rider's active (non-terminal) orders as ZIPS-style cards with a
/// status chip, item thumbnails, and pickup/drop addresses. Pull to refresh.
class CurrentOrdersScreen extends ConsumerWidget {
  const CurrentOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(currentOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Current Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(riderOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyStateView(
              icon: LucideIcons.packageOpen,
              title: 'No active orders',
              message: 'Accepted deliveries will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(riderOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: orders.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, i) {
                final summary = orders[i];
                return OrderSummaryCard(
                  order: summary,
                  onTap: () => _openActiveDelivery(context, ref, summary.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

Future<void> _openActiveDelivery(
  BuildContext context,
  WidgetRef ref,
  String orderId,
) async {
  try {
    final fullOrder = await ref.read(ordersRepositoryProvider).getOrder(orderId);
    ref.read(activeOrderProvider.notifier).set(fullOrder);
    ref.read(deliveryStepProvider.notifier).set(
          deliveryStepForOrderStatus(fullOrder['status'] as String?),
        );
    if (!context.mounted) return;
    context.push(RoutePaths.activeDelivery, extra: fullOrder);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceAll('Exception: ', ''),
        ),
      ),
    );
  }
}
