import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/mobile_tab_selector.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/premium_order_card.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/returned_food_panel.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/kds_provider.dart';

class ActiveOrdersView extends ConsumerStatefulWidget {
  const ActiveOrdersView({super.key});

  @override
  ConsumerState<ActiveOrdersView> createState() => _ActiveOrdersViewState();
}

class _ActiveOrdersViewState extends ConsumerState<ActiveOrdersView> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    // Keep the stream active so it can process socket events reactively
    ref.listen(kdsEventStreamProvider, (_, __) {});

    final kdsState = ref.watch(kdsProvider);
    final newOrders = ref.watch(kdsNewOrdersProvider);
    final prepOrders = ref.watch(kdsPreparingOrdersProvider);
    final readyOrders = ref.watch(kdsReadyOrdersProvider);
    final returnedOrders = ref.watch(kdsReturnedOrdersProvider);

    return Column(
      children: [
        ReturnedFoodPanel(orders: returnedOrders),
        MobileTabSelector(
          activeTab: _activeTab,
          onTabChange: (i) => setState(() => _activeTab = i),
          newCount: newOrders.length,
          prepCount: prepOrders.length,
          readyCount: readyOrders.length,
        ),
        Expanded(
          child:
              kdsState.isLoading &&
                  newOrders.isEmpty &&
                  prepOrders.isEmpty &&
                  readyOrders.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.pandaPink),
                )
              : RefreshIndicator(
                  color: AppColors.pandaPink,
                  onRefresh: () => ref.read(kdsProvider.notifier).fetchOrders(),
                  child: _buildList(newOrders, prepOrders, readyOrders),
                ),
        ),
      ],
    );
  }

  Widget _buildList(
    List<dynamic> newOrders,
    List<dynamic> prepOrders,
    List<dynamic> readyOrders,
  ) {
    List<dynamic> currentOrders;
    String? defaultNextStatus;
    String defaultActionText = '';

    if (_activeTab == 0) {
      currentOrders = newOrders;
      // Handled dynamically per order
    } else if (_activeTab == 1) {
      currentOrders = prepOrders;
      defaultNextStatus = 'READY_FOR_PICKUP';
      defaultActionText = 'Mark Ready';
    } else {
      currentOrders = readyOrders;
      defaultNextStatus = null; // Handled by rider
    }

    if (currentOrders.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: AppColors.gray400),
                    const SizedBox(height: 16),
                    const Text(
                      'No orders here',
                      style: TextStyle(
                        color: AppColors.gray700,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: currentOrders.length,
      itemBuilder: (context, index) {
        final order = currentOrders[index];
        
        String? nextStatus = defaultNextStatus;
        String actionText = defaultActionText;
        
        if (_activeTab == 0) {
          if (order['status'] == 'PLACED') {
            nextStatus = 'ACCEPTED';
            actionText = 'Accept Order';
          } else {
            nextStatus = 'PREPARING';
            actionText = 'Start Preparing';
          }
        }
        
        final assignment = order['assignment'];
        final assignmentStatus = assignment is Map
            ? assignment['status']?.toString()
            : null;
        final canSendPathao = _activeTab == 2 &&
            order['status'] == 'READY_FOR_PICKUP' &&
            order['deliveryService'] == null &&
            (assignmentStatus == null ||
                assignmentStatus == 'EXPIRED' ||
                assignmentStatus == 'REJECTED' ||
                assignmentStatus == 'CANCELLED');

        return PremiumOrderCard(
              order: order,
              nextStatus: nextStatus,
              actionText: actionText,
              accentColor: AppColors.pandaPink,
              secondaryActionText:
                  canSendPathao ? 'Send to Pathao' : null,
              onSecondaryAction: canSendPathao
                  ? () => _showPathaoDialog(context, order['id'] as String)
                  : null,
              onReject: order['status'] == 'PLACED'
                  ? () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reject Order?'),
                          content: const Text('Are you sure you want to reject this order?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref
                                    .read(kdsProvider.notifier)
                                    .rejectOrder(order['id'], 'Rejected by kitchen');
                              },
                              child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
              onAction: () {
                if (nextStatus != null) {
                  ref
                      .read(kdsProvider.notifier)
                      .updateOrderStatus(order['id'], nextStatus);
                }
              },
            )
            .animate(key: ValueKey(order['id']))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Future<void> _showPathaoDialog(BuildContext context, String orderId) async {
    final trackingController = TextEditingController();
    final urlController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send to Pathao'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the Pathao consignment / tracking ID. The customer will see updates through the app.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Tracking URL (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (trackingController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(kdsProvider.notifier).dispatchToPathao(
            orderId,
            trackingId: trackingController.text.trim(),
            trackingUrl: urlController.text.trim().isEmpty
                ? null
                : urlController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order sent via Pathao')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not dispatch to Pathao. Try again.'),
          ),
        );
      }
    }
  }
}
