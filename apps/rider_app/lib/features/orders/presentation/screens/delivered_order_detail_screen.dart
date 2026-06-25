import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/feedback/error_state_view.dart';
import '../../../../core/widgets/feedback/tab_loading_view.dart';
import '../../../../core/widgets/layouts/app_card.dart';
import '../../../../core/widgets/layouts/rider_stack_scaffold.dart';
import '../../../../core/widgets/layouts/section_header.dart';
import '../../data/order_summary.dart';
import '../providers/order_providers.dart';
import '../widgets/order_status_chip.dart';

/// Receipt-style summary for a completed or cancelled delivery.
class DeliveredOrderDetailScreen extends StatelessWidget {
  const DeliveredOrderDetailScreen({super.key, required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RiderStackScaffold(
      title: order.orderNumber.isEmpty ? 'Order' : 'Order #${order.orderNumber}',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          AppSpacing.xxxl,
        ),
        children: [
          // --- HERO: status + total ---
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OrderStatusChip(status: order.status),
                    const Spacer(),
                    _PaymentBadge(method: order.paymentMethod),
                  ],
                ),
                if (order.grandTotal != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Order total',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatCurrency(order.grandTotal!),
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
                if (order.deliveredAt != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateTime(order.deliveredAt!),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (_hasTimeline) ...[
            const SizedBox(height: AppSpacing.section),
            const SectionHeader(title: 'Timeline', padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: [
                  if (order.pickedUpAt != null)
                    _TimelineStep(
                      icon: LucideIcons.packageCheck,
                      color: AppColors.inProgress,
                      label: 'Picked up',
                      time: _formatTime(order.pickedUpAt!),
                      showConnector: order.deliveredAt != null,
                    ),
                  if (order.deliveredAt != null)
                    _TimelineStep(
                      icon: LucideIcons.circleCheck,
                      color: AppColors.online,
                      label: order.isDelivered ? 'Delivered' : 'Completed',
                      time: _formatTime(order.deliveredAt!),
                      showConnector: false,
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Route', padding: EdgeInsets.zero),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                _RouteRow(
                  icon: LucideIcons.store,
                  iconColor: AppColors.primary,
                  label: 'Pickup',
                  value: order.restaurantName ?? '—',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(height: 1, color: AppColors.borderLight),
                ),
                _RouteRow(
                  icon: LucideIcons.mapPin,
                  iconColor: AppColors.textSecondary,
                  label: 'Drop-off',
                  value: order.deliveryAddress ?? '—',
                ),
              ],
            ),
          ),

          if (order.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(
              title: 'Items (${order.itemCount})',
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < order.items.length; i++) ...[
                    _ItemLine(item: order.items[i]),
                    if (i < order.items.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.section),
          const SectionHeader(title: 'Summary', padding: EdgeInsets.zero),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Items',
                  value: '${order.itemCount}',
                ),
                if (order.distanceKm != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SummaryRow(
                    label: 'Distance',
                    value: '${order.distanceKm!.toStringAsFixed(1)} km',
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _SummaryRow(
                  label: 'Payment',
                  value: order.paymentMethod,
                ),
                if (order.grandTotal != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Divider(height: 1, color: AppColors.borderLight),
                  ),
                  _SummaryRow(
                    label: 'Total',
                    value: formatCurrency(order.grandTotal!),
                    emphasized: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasTimeline =>
      order.pickedUpAt != null || order.deliveredAt != null;

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year} · ${_formatTime(local)}';
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        method,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.color,
    required this.label,
    required this.time,
    required this.showConnector,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String time;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.borderLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? AppSpacing.lg : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item});

  final OrderItemSummary item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            item.name,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '×${item.quantity}',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            fontSize: emphasized ? 16 : null,
          ),
        ),
      ],
    );
  }
}

/// Loads order detail by ID for deep links / notification taps.
class DeliveredOrderDetailLoader extends ConsumerWidget {
  const DeliveredOrderDetailLoader({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orderId.isEmpty) {
      return RiderStackScaffold(
        title: 'Order',
        body: ErrorStateView(
          message: 'Order not found.',
          onRetry: () => Navigator.of(context).pop(),
        ),
      );
    }

    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return orderAsync.when(
      loading: () => const RiderStackScaffold(
        title: 'Order',
        body: TabLoadingView(style: TabLoadingStyle.card),
      ),
      error: (err, _) => RiderStackScaffold(
        title: 'Order',
        body: ErrorStateView(
          message: err.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
      ),
      data: (raw) => DeliveredOrderDetailScreen(
        order: OrderSummary.fromJson(Map<String, dynamic>.from(raw)),
      ),
    );
  }
}
