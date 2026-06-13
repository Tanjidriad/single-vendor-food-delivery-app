import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/widgets/buttons/app_button.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/orders_repository.dart';

class ReorderButton extends ConsumerStatefulWidget {
  final String orderId;
  final bool compact;

  const ReorderButton({
    super.key,
    required this.orderId,
    this.compact = false,
  });

  @override
  ConsumerState<ReorderButton> createState() => _ReorderButtonState();
}

class _ReorderButtonState extends ConsumerState<ReorderButton> {
  bool _isLoading = false;

  Future<void> _handleReorder() async {
    setState(() => _isLoading = true);
    try {
      final newOrder = await ref.read(ordersRepositoryProvider).reorder(widget.orderId);
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        context.go(RoutePaths.orderSuccessWithId(newOrder['id'] as String));
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(context, title: 'Reorder failed', message: '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return TextButton.icon(
        onPressed: _isLoading ? null : _handleReorder,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: _isLoading 
            ? const SizedBox(
                width: 16, height: 16, 
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
              )
            : const Icon(Iconsax.refresh, size: 18),
        label: const Text('Reorder', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    return AppButton(
      label: 'Reorder',
      variant: AppButtonVariant.outline,
      isLoading: _isLoading,
      onPressed: _handleReorder,
    );
  }
}
