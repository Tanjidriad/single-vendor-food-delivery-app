import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_icons.dart';

import '../../../features/cart/presentation/providers/cart_provider.dart';
import '../../router/route_paths.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../utils/formatters/formatter.dart';

class FloatingCartBar extends ConsumerWidget {
  const FloatingCartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.itemCount == 0) return const SizedBox.shrink();

    return Animate(
      effects: [
        SlideEffect(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
          duration: 350.ms,
          curve: Curves.easeOut,
        ),
        FadeEffect(duration: 350.ms),
      ],
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () => context.push(RoutePaths.cart),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: AppShadows.floatingBar,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(AppIcons.bag, color: AppColors.onPrimary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'View cart · ${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    AppFormatter.formatCurrency(cart.subtotal),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
