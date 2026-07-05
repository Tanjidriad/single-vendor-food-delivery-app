import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/kds_kanban_board.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/new_order_square_card.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/accepted_order_list_tile.dart';
import 'package:kitchen_app/features/kds/presentation/screens/order_detail_screen.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/premium_order_card.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/returned_food_panel.dart';
import 'package:kitchen_app/features/kds/presentation/widgets/new_order_alert_overlay.dart';
import '../../../../core/services/kitchen_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/order_workflow.dart';
import '../providers/kds_provider.dart';
import '../widgets/dispatch_action_sheet.dart';
import '../widgets/pathao_suggestion_banner.dart';

class ActiveOrdersView extends ConsumerStatefulWidget {
  const ActiveOrdersView({super.key});

  @override
  ConsumerState<ActiveOrdersView> createState() => _ActiveOrdersViewState();
}

class _ActiveOrdersViewState extends ConsumerState<ActiveOrdersView> {
  bool _showAlertOverlay = false;

  @override
  Widget build(BuildContext context) {
    // Keep the stream active so it can process socket events reactively
    ref.listen(kdsEventStreamProvider, (a, b) {});

    // Listen for new orders to show the overlay
    ref.listen(kdsNewOrdersProvider, (previous, next) {
      if (previous != null && next.length > previous.length) {
        if (mounted) {
          setState(() {
            _showAlertOverlay = true;
          });
        }
      }
    });

    final kdsState = ref.watch(kdsProvider);
    final newOrders = ref.watch(kdsNewOrdersProvider);
    final prepOrders = ref.watch(kdsPreparingOrdersProvider);
    final readyOrders = ref.watch(kdsReadyOrdersProvider);
    final returnedOrders = ref.watch(kdsReturnedOrdersProvider);
    final compact = ref.watch(kitchenPreferencesProvider).compactDensity;
    final exhaustedAlerts = kdsState.dispatchAlerts
        .where((a) => a.type == DispatchAlertType.exhausted)
        .toList();

    final width = MediaQuery.sizeOf(context).width;
    final useKanban = width >= 720;

    return Stack(
      children: [
        Column(
          children: [
            ReturnedFoodPanel(orders: returnedOrders),

            PathaoSuggestionBanner(
              alerts: exhaustedAlerts,
              onSendToPathao: (orderId) => _showPathaoDialog(context, orderId),
              onRetryAssign: (orderId) async {
                try {
                  await ref.read(kdsProvider.notifier).autoAssignRider(orderId);
                  ref.read(kdsProvider.notifier).dismissDispatchAlert(orderId);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No riders available. Try again later.'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              onDismiss: (orderId) {
                ref.read(kdsProvider.notifier).dismissDispatchAlert(orderId);
              },
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
                      onRefresh: () =>
                          ref.read(kdsProvider.notifier).fetchOrders(),
                    )
                  : _buildMobileList(
                      newOrders,
                      prepOrders,
                      readyOrders,
                      compact: compact,
                    ),
            ),
          ],
        ),
        if (_showAlertOverlay)
          Positioned.fill(
            child: NewOrderAlertOverlay(
              count: newOrders.length,
              onDismiss: () {
                setState(() {
                  _showAlertOverlay = false;
                });
              },
            ),
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
        accentColor = AppColors.primary;
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
    final hasActiveAssignment =
        assignmentStatus == 'NOTIFIED' || assignmentStatus == 'ACCEPTED';
    final needsDispatch =
        (section == KitchenSection.ready ||
            section == KitchenSection.preparing) &&
        order['deliveryService'] == null &&
        !hasActiveAssignment;

    final canSendPathao =
        section == KitchenSection.ready &&
        order['status'] == 'READY_FOR_PICKUP' &&
        order['deliveryService'] == null &&
        (assignmentStatus == null ||
            assignmentStatus == 'EXPIRED' ||
            assignmentStatus == 'REJECTED' ||
            assignmentStatus == 'CANCELLED');

    final userRole = ref.read(authProvider).user?['role']?.toString();
    final canDispatch =
        userRole == 'OWNER' || userRole == 'MANAGER' || userRole == 'CASHIER';

    // Show "Assign Rider" when user has dispatch permissions and order needs a rider.
    // Show "Send to Pathao" as secondary for ready orders without a rider.
    String? secondaryText;
    VoidCallback? secondaryAction;
    if (canDispatch && needsDispatch) {
      secondaryText = 'Assign Rider';
      secondaryAction = () => _showDispatchSheet(context, order);
    } else if (canSendPathao) {
      secondaryText = 'Send to Pathao';
      secondaryAction = () => _showPathaoDialog(context, order['id'] as String);
    }

    return PremiumOrderCard(
      order: order,
      nextStatus: nextStatus,
      actionText: actionText,
      accentColor: accentColor,
      compact: compact,
      secondaryActionText: secondaryText,
      onSecondaryAction: secondaryAction,
      onReject: order['status'] == 'PLACED'
          ? () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reject Order?'),
                  content: const Text(
                    'Are you sure you want to reject this order?',
                  ),
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
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: AppColors.error),
                      ),
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

    final acceptedOrders = [...prepOrders, ...readyOrders];

    return RefreshIndicator(
      color: AppColors.pandaPink,
      onRefresh: () => ref.read(kdsProvider.notifier).fetchOrders(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text(
                          'New',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.black500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${newOrders.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (newOrders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'No new orders',
                        style: TextStyle(
                          color: AppColors.gray700,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 132,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        scrollDirection: Axis.horizontal,
                        itemCount: newOrders.length,
                        itemBuilder: (context, index) {
                          final order = newOrders[index];
                          return NewOrderSquareCard(
                            order: order,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderDetailScreen(order: order),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.gray300,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Accepted',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${acceptedOrders.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (acceptedOrders.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: const Text(
                    'No accepted orders',
                    style: TextStyle(color: AppColors.gray700, fontSize: 16),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final order = acceptedOrders[index];
                  return AcceptedOrderListTile(
                        order: order,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(order: order),
                            ),
                          );
                        },
                      )
                      .animate(key: ValueKey(order['id']))
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0);
                }, childCount: acceptedOrders.length),
              ),
            ),

          SliverToBoxAdapter(child: const SizedBox(height: 64)),
        ],
      ),
    );
  }

  void _showDispatchSheet(BuildContext context, dynamic order) {
    final assignment = order['assignment'];
    final hasActive =
        assignment is Map &&
        (assignment['status'] == 'NOTIFIED' ||
            assignment['status'] == 'ACCEPTED');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DispatchActionSheet(
        orderId: order['id'] as String,
        orderNumber: order['orderNumber']?.toString() ?? '',
        hasActiveAssignment: hasActive,
      ),
    );
  }

  Future<void> _showPathaoDialog(BuildContext context, String orderId) async {
    // Capture before any await — required by use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Send to Pathao'),
          ],
        ),
        content: const Text(
          'Pathao will automatically create a parcel and assign a tracking ID. '
          'The customer will be notified with a live tracking link.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Confirm & Send'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show a loading snackbar while the API call is in flight
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Creating Pathao parcel…'),
          ],
        ),
        duration: Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await ref
          .read(kdsProvider.notifier)
          .dispatchToPathao(
            orderId,
            trackingId: '', // backend auto-generates via Pathao API
          );
      ref.read(kdsProvider.notifier).dismissDispatchAlert(orderId);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ Order dispatched via Pathao — tracking ID assigned'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not dispatch to Pathao. Try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
