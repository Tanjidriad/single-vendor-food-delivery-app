import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/kds_kanban_board.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/mobile_tab_selector.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/premium_order_card.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/returned_food_panel.dart';
import '../../../../core/services/kitchen_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/order_workflow.dart';
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
    ref.listen(kdsEventStreamProvider, (a, b) {});

    final kdsState = ref.watch(kdsProvider);
    final newOrders = ref.watch(kdsNewOrdersProvider);
    final prepOrders = ref.watch(kdsPreparingOrdersProvider);
    final readyOrders = ref.watch(kdsReadyOrdersProvider);
    final returnedOrders = ref.watch(kdsReturnedOrdersProvider);
    final compact = ref.watch(kitchenPreferencesProvider).compactDensity;

    final width = MediaQuery.sizeOf(context).width;
    final useKanban = width >= 720;

    return Column(
      children: [
        ReturnedFoodPanel(orders: returnedOrders),
        if (!useKanban)
          MobileTabSelector(
            activeTab: _activeTab,
            onTabChange: (i) => setState(() => _activeTab = i),
            newCount: newOrders.length,
            prepCount: prepOrders.length,
            readyCount: readyOrders.length,
          ),
        Expanded(
          child: useKanban
              ? KdsKanbanBoard(
                  isLoading: kdsState.isLoading,
                  newOrders: newOrders,
                  prepOrders: prepOrders,
                  readyOrders: readyOrders,
                  compact: compact,
                  newCardBuilder: (order) => _buildOrderCard(
                    order,
                    section: KitchenSection.newOrders,
                    compact: compact,
                  ),
                  prepCardBuilder: (order) => _buildOrderCard(
                    order,
                    section: KitchenSection.preparing,
                    compact: compact,
                  ),
                  readyCardBuilder: (order) => _buildOrderCard(
                    order,
                    section: KitchenSection.ready,
                    compact: compact,
                  ),
                  onRefresh: () => ref.read(kdsProvider.notifier).fetchOrders(),
                )
              : _buildMobileList(newOrders, prepOrders, readyOrders, compact: compact),
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    dynamic order, {
    required KitchenSection section,
    bool compact = false,
  }) {
    String? nextStatus;
    String actionText = '';
    Color accentColor = AppColors.pandaPink;

    switch (section) {
      case KitchenSection.newOrders:
        accentColor = AppColors.pandaPink;
        if (order['status'] == 'PLACED') {
          nextStatus = 'ACCEPTED';
          actionText = 'Accept Order';
        } else {
          nextStatus = 'PREPARING';
          actionText = 'Start Preparing';
        }
      case KitchenSection.preparing:
        accentColor = AppColors.warning;
        nextStatus = 'READY_FOR_PICKUP';
        actionText = 'Mark Ready';
      case KitchenSection.ready:
        accentColor = AppColors.success;
        nextStatus = null;
        actionText = '';
      default:
        break;
    }

    final assignment = order['assignment'];
    final assignmentStatus = assignment is Map
        ? assignment['status']?.toString()
        : null;
    final canSendPathao = section == KitchenSection.ready &&
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
      accentColor: accentColor,
      compact: compact,
      secondaryActionText: canSendPathao ? 'Send to Pathao' : null,
      onSecondaryAction: canSendPathao
          ? () => _showPathaoDialog(context, order['id'] as String)
          : null,
      onReject: order['status'] == 'PLACED'
          ? () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reject Order?'),
                  content: const Text(
                      'Are you sure you want to reject this order?'),
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
                      child: const Text('Reject',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            }
          : null,
      onAction: () {
        if (nextStatus != null) {
          if (section == KitchenSection.newOrders ||
              nextStatus == 'READY_FOR_PICKUP') {
            HapticFeedback.lightImpact();
          }
          ref
              .read(kdsProvider.notifier)
              .updateOrderStatus(order['id'], nextStatus);
        }
      },
    );
  }

  Widget _buildMobileList(
    List<dynamic> newOrders,
    List<dynamic> prepOrders,
    List<dynamic> readyOrders, {
    bool compact = false,
  }) {
    final isLoading = ref.watch(kdsProvider).isLoading;

    if (isLoading &&
        newOrders.isEmpty &&
        prepOrders.isEmpty &&
        readyOrders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pandaPink),
      );
    }

    return RefreshIndicator(
      color: AppColors.pandaPink,
      onRefresh: () => ref.read(kdsProvider.notifier).fetchOrders(),
      child: _buildMobileTabContent(newOrders, prepOrders, readyOrders, compact: compact),
    );
  }

  Widget _buildMobileTabContent(
    List<dynamic> newOrders,
    List<dynamic> prepOrders,
    List<dynamic> readyOrders, {
    bool compact = false,
  }) {
    List<dynamic> currentOrders;

    if (_activeTab == 0) {
      currentOrders = newOrders;
    } else if (_activeTab == 1) {
      currentOrders = prepOrders;
    } else {
      currentOrders = readyOrders;
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
                    Icon(Icons.receipt_long,
                        size: 64, color: AppColors.gray400),
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
        final section = _activeTab == 0
            ? KitchenSection.newOrders
            : _activeTab == 1
                ? KitchenSection.preparing
                : KitchenSection.ready;
        return _buildOrderCard(order, section: section, compact: compact)
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
