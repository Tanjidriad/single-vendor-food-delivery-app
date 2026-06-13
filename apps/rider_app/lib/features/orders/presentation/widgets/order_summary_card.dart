import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../data/order_summary.dart';
import 'order_status_chip.dart';

/// A ZIPS-style order card: header (order # + status chip), a row of item
/// thumbnails, a pickup→drop timeline, and a footer (item count + total).
///
/// Used by the Current Orders and History lists. [onTap] is optional so the
/// same card works as a tappable history row or a static current-order card.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.order, this.onTap});

  final OrderSummary order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.soft,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber.isEmpty
                          ? 'Order'
                          : 'Order #${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Item thumbnails
              if (order.items.isNotEmpty) ...[
                _ItemThumbStrip(items: order.items),
                const SizedBox(height: AppSpacing.md),
              ],

              // Pickup → drop timeline
              _AddressRail(
                pickup: order.restaurantName ?? 'Pickup location',
                drop: order.deliveryAddress ?? 'Delivery location',
              ),

              const Divider(height: AppSpacing.xl),

              // Footer
              Row(
                children: [
                  Icon(LucideIcons.package,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (order.distanceKm != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Icon(LucideIcons.mapPin,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      '${order.distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (order.grandTotal != null)
                    Text(
                      formatCurrency(order.grandTotal!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontal strip of up to 4 item thumbnails, with a "+N" overflow chip.
class _ItemThumbStrip extends StatelessWidget {
  const _ItemThumbStrip({required this.items});

  final List<OrderItemSummary> items;

  @override
  Widget build(BuildContext context) {
    const max = 4;
    final shown = items.take(max).toList();
    final overflow = items.length - shown.length;
    return Row(
      children: [
        for (final item in shown)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _Thumb(url: item.imageUrl),
          ),
        if (overflow > 0)
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              '+$overflow',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 44,
        height: 44,
        child: (url == null || url!.isEmpty)
            ? const ColoredBox(
                color: AppColors.surfaceElevated,
                child: Icon(LucideIcons.image,
                    size: 18, color: AppColors.textDisabled),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.surfaceElevated,
                  child: Icon(LucideIcons.image,
                      size: 18, color: AppColors.textDisabled),
                ),
              ),
      ),
    );
  }
}

/// A compact two-stop rail: pickup (store) → drop (pin), connected by a line.
class _AddressRail extends StatelessWidget {
  const _AddressRail({required this.pickup, required this.drop});

  final String pickup;
  final String drop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(LucideIcons.store, size: 16, color: AppColors.primary),
            Container(
              width: 2,
              height: 22,
              margin: const EdgeInsets.symmetric(vertical: 2),
              color: AppColors.borderLight,
            ),
            const Icon(LucideIcons.mapPin,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RailLine(label: pickup),
              const SizedBox(height: AppSpacing.md),
              _RailLine(label: drop),
            ],
          ),
        ),
      ],
    );
  }
}

class _RailLine extends StatelessWidget {
  const _RailLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
