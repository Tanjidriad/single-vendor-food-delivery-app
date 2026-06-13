import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/order_workflow.dart';
import 'kds_kanban_column.dart';

/// Foodpanda-style KDS kanban board.
///
/// On wide screens shows 3 columns side-by-side; on medium screens shows
/// a 2-column layout; on narrow screens falls back to the caller's choice.
class KdsKanbanBoard extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> newOrders;
  final List<dynamic> prepOrders;
  final List<dynamic> readyOrders;
  final Widget Function(dynamic order) newCardBuilder;
  final Widget Function(dynamic order) prepCardBuilder;
  final Widget Function(dynamic order) readyCardBuilder;
  final Future<void> Function() onRefresh;

  const KdsKanbanBoard({
    super.key,
    required this.isLoading,
    required this.newOrders,
    required this.prepOrders,
    required this.readyOrders,
    required this.newCardBuilder,
    required this.prepCardBuilder,
    required this.readyCardBuilder,
    required this.onRefresh,
  });

  bool get _hasOrders =>
      newOrders.isNotEmpty || prepOrders.isNotEmpty || readyOrders.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1100;
    final isMedium = width >= 720 && width < 1100;

    if (isLoading && !_hasOrders) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pandaPink),
      );
    }

    return RefreshIndicator(
      color: AppColors.pandaPink,
      onRefresh: onRefresh,
      child: isWide
          ? _buildThreeColumnLayout()
          : isMedium
              ? _buildTwoColumnLayout()
              : _buildSingleColumnLayout(),
    );
  }

  Widget _buildThreeColumnLayout() {
    return Row(
      children: [
        Expanded(
          child: KdsKanbanColumn(
            title: 'New orders',
            section: KitchenSection.newOrders,
            count: newOrders.length,
            accentColor: AppColors.pandaPink,
            orders: newOrders,
            cardBuilder: newCardBuilder,
          ),
        ),
        Expanded(
          child: KdsKanbanColumn(
            title: 'Preparing',
            section: KitchenSection.preparing,
            count: prepOrders.length,
            accentColor: AppColors.warning,
            orders: prepOrders,
            cardBuilder: prepCardBuilder,
          ),
        ),
        Expanded(
          child: KdsKanbanColumn(
            title: 'Ready',
            section: KitchenSection.ready,
            count: readyOrders.length,
            accentColor: AppColors.success,
            orders: readyOrders,
            cardBuilder: readyCardBuilder,
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      children: [
        Expanded(
          child: KdsKanbanColumn(
            title: 'New orders',
            section: KitchenSection.newOrders,
            count: newOrders.length,
            accentColor: AppColors.pandaPink,
            orders: newOrders,
            cardBuilder: newCardBuilder,
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: KdsKanbanColumn(
                  title: 'Preparing',
                  section: KitchenSection.preparing,
                  count: prepOrders.length,
                  accentColor: AppColors.warning,
                  orders: prepOrders,
                  cardBuilder: prepCardBuilder,
                ),
              ),
              Expanded(
                child: KdsKanbanColumn(
                  title: 'Ready',
                  section: KitchenSection.ready,
                  count: readyOrders.length,
                  accentColor: AppColors.success,
                  orders: readyOrders,
                  cardBuilder: readyCardBuilder,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    // Single-column kanban is the same as the mobile list view. Since the
    // caller decides whether to show tabs vs. board, this path should rarely
    // be used. We render new orders as a sensible default.
    return KdsKanbanColumn(
      title: 'Active orders',
      section: KitchenSection.newOrders,
      count: newOrders.length + prepOrders.length + readyOrders.length,
      accentColor: AppColors.pandaPink,
      orders: [...newOrders, ...prepOrders, ...readyOrders],
      cardBuilder: (order) {
        final status = order['status']?.toString();
        if (status == 'PLACED' || status == 'ACCEPTED') {
          return newCardBuilder(order);
        }
        if (status == 'PREPARING') {
          return prepCardBuilder(order);
        }
        return readyCardBuilder(order);
      },
    );
  }
}
