import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../data/order_summary.dart';
import '../widgets/order_status_chip.dart';

/// Delivered Order Detail — the ZIPS-style summary of a completed delivery:
/// status, departure (`pickedUpAt`) / arrival (`deliveredAt`) times, the
/// pickup and delivery addresses, item thumbnails, and the order total.
class DeliveredOrderDetailScreen extends StatelessWidget {
  const DeliveredOrderDetailScreen({super.key, required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          order.orderNumber.isEmpty ? 'Order' : 'Order #${order.orderNumber}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // Status + total header
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    OrderStatusChip(status: order.status),
                    const Spacer(),
                    if (order.grandTotal != null)
                      Text(
                        formatCurrency(order.grandTotal!),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                _TimeRow(
                  icon: LucideIcons.circleArrowUp,
                  label: 'Departure time',
                  value: _formatTime(order.pickedUpAt),
                ),
                const SizedBox(height: AppSpacing.md),
                _TimeRow(
                  icon: LucideIcons.circleArrowDown,
                  label: 'Arrival time',
                  value: _formatTime(order.deliveredAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Locations
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LocationRow(
                  icon: LucideIcons.store,
                  color: AppColors.primary,
                  label: 'Pickup location',
                  value: order.restaurantName ?? '—',
                ),
                const SizedBox(height: AppSpacing.lg),
                _LocationRow(
                  icon: LucideIcons.mapPin,
                  color: AppColors.online,
                  label: 'Delivery location',
                  value: order.deliveryAddress ?? '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Items
          if (order.items.isNotEmpty)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items (${order.itemCount})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final item in order.items) ...[
                    _ItemRow(item: item),
                    if (item != order.items.last)
                      const Divider(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    return '$date · $h:$m $ampm';
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItemSummary item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: 44,
            height: 44,
            child: (item.imageUrl == null || item.imageUrl!.isEmpty)
                ? const ColoredBox(
                    color: AppColors.surfaceElevated,
                    child: Icon(LucideIcons.image,
                        size: 18, color: AppColors.textDisabled),
                  )
                : Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.surfaceElevated,
                      child: Icon(LucideIcons.image,
                          size: 18, color: AppColors.textDisabled),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            item.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '×${item.quantity}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}
