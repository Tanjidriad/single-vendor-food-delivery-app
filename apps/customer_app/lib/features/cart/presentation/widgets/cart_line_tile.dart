import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../domain/entities/cart_item.dart';
import '../providers/cart_provider.dart';

class CartLineTile extends ConsumerWidget {
  const CartLineTile({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: item.imageUrl != null
              ? CachedNetworkImage(imageUrl: item.imageUrl!, width: 72, height: 72, fit: BoxFit.cover)
              : Container(width: 72, height: 72, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              if (item.addons.isNotEmpty)
                Text(
                  item.addons.map((a) => a.name).join(', '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    iconSize: 20,
                    onPressed: () => ref.read(cartProvider.notifier).updateQuantity(
                          item.menuItemId,
                          item.quantity - 1,
                        ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${item.quantity}'),
                  IconButton(
                    iconSize: 20,
                    onPressed: () => ref.read(cartProvider.notifier).updateQuantity(
                          item.menuItemId,
                          item.quantity + 1,
                        ),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  Text(AppFormatter.formatCurrency(item.lineTotal), style: AppTypography.price()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
