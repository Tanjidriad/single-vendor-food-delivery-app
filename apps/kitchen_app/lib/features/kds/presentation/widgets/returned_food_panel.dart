import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/kds_provider.dart';

class ReturnedFoodPanel extends ConsumerWidget {
  const ReturnedFoodPanel({super.key, required this.orders});

  final List<dynamic> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.warning_2, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Returned food (${orders.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.black500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Food returned from a failed delivery must be discarded. '
            'Confirm once disposed for food safety compliance.',
            style: TextStyle(color: AppColors.gray700, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          ...orders.map((order) {
            final id = order['id']?.toString() ?? '';
            final disposition = order['foodDisposition']?.toString();
            final discarded = disposition == 'DISCARDED';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order['orderNumber'] ?? '---'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.black500,
                      ),
                    ),
                  ),
                  if (discarded)
                    const Text(
                      'Discarded',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: id.isEmpty
                          ? null
                          : () => _confirmDiscard(context, ref, id),
                      child: const Text('Confirm discarded'),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm food discarded?'),
        content: const Text(
          'This records that returned food was safely disposed and cannot be redispatched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(kdsProvider.notifier)
          .setFoodDisposition(orderId, 'DISCARDED');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food discard recorded.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not record discard. Try again.')),
      );
    }
  }
}
