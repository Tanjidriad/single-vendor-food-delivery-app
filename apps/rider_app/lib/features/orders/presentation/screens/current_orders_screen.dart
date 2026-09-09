import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback/empty_state_view.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../../../core/widgets/layouts/app_card.dart';
import '../../../../core/widgets/layouts/rider_tab_scaffold.dart';
import '../../data/orders_repository.dart';
import '../providers/active_order_restore.dart';
import '../providers/order_providers.dart';
import '../providers/rider_orders_provider.dart';
import '../widgets/order_summary_card.dart';

class CurrentOrdersScreen extends ConsumerWidget {
  const CurrentOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(currentOrdersProvider);

    return RiderTabScaffold(
      title: 'Orders',
      subtitle: 'Active deliveries',
      onRefresh: () async => ref.invalidate(riderOrdersProvider),
      body: ordersAsync.when(
        loading: () => const TabLoadingView(style: TabLoadingStyle.card),
        error: (err, _) => ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(riderOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyStateView(
              icon: LucideIcons.packageOpen,
              title: 'No active orders',
              message:
                  'Accepted deliveries will appear here. Go online from Home to receive offers.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.xxxl,
            ),
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.package,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        '${orders.length} active delivery${orders.length == 1 ? '' : 'ies'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Text(
                      'Tap to continue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < orders.length; i++) ...[
                OrderSummaryCard(
                  order: orders[i],
                  onTap: () => _openActiveDelivery(context, ref, orders[i].id),
                ),
                if (i < orders.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
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
    unawaited(context.push(RoutePaths.activeDelivery, extra: fullOrder));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
      ),
    );
  }
}
