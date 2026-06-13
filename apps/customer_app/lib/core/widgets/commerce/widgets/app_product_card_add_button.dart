import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/cart/domain/entities/cart_item.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_spacing.dart';

/// CWT [ProductCardAddToCartButton] for menu items.
class AppProductCardAddButton extends ConsumerWidget {
  const AppProductCardAddButton({
    super.key,
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    this.imageUrl,
    this.onNavigateToDetail,
  });

  final String menuItemId;
  final String name;
  final double unitPrice;
  final String? imageUrl;
  final VoidCallback? onNavigateToDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final qty = cart.items
        .where((i) => i.menuItemId == menuItemId)
        .fold<int>(0, (sum, i) => sum + i.quantity);

    return GestureDetector(
      onTap: () {
        if (onNavigateToDetail != null) {
          onNavigateToDetail!();
          return;
        }
        ref.read(cartProvider.notifier).addItem(
              CartItem(
                menuItemId: menuItemId,
                name: name,
                unitPrice: unitPrice,
                quantity: 1,
                imageUrl: imageUrl,
              ),
            );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubicEmphasized,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: qty > 0 ? AppColors.primary : AppColors.textPrimary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusMd),
            bottomRight: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Center(
          child: qty > 0
              ? Text(
                  '$qty',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                )
              : const Icon(AppIcons.add, color: AppColors.onPrimary, size: 20),
        ),
      ),
    );
  }
}
