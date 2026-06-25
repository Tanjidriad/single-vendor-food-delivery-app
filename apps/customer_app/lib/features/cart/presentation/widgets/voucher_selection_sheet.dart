import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers/helper_functions.dart';
import '../../../../core/utils/popups/loaders.dart';
import '../../../../core/widgets/cwt/empty_state_widget.dart';
import '../../../../core/widgets/shimmers/shimmer.dart';
import '../../../offers/presentation/providers/offers_providers.dart';
import '../../../offers/presentation/widgets/promo_ticket_card.dart';
import '../../../orders/data/orders_repository.dart';
import '../../../restaurant/data/restaurant_repository.dart';
import '../providers/cart_provider.dart';

class VoucherSelectionSheet extends ConsumerStatefulWidget {
  const VoucherSelectionSheet({super.key});

  @override
  ConsumerState<VoucherSelectionSheet> createState() => _VoucherSelectionSheetState();
}

class _VoucherSelectionSheetState extends ConsumerState<VoucherSelectionSheet> {
  bool _applying = false;
  String? _applyingCode;

  Future<void> _applyCoupon(String code) async {
    final cart = ref.read(cartProvider);
    final restaurantId = ref.read(restaurantIdProvider);
    if (restaurantId == null) return;

    setState(() {
      _applying = true;
      _applyingCode = code;
    });

    try {
      final res = await ref.read(ordersRepositoryProvider).validateCoupon({
        'restaurantId': restaurantId,
        'code': code,
        'subtotal': cart.subtotal,
      });
      final discount = (res['discount'] as num).toDouble();
      ref.read(cartProvider.notifier).setCoupon(code, discount);
      
      if (mounted) {
        AppLoaders.customToast(context, message: 'Voucher applied successfully!');
        context.pop(); // Close the sheet
      }
    } catch (e) {
      if (mounted) {
        AppLoaders.errorSnackBar(context, title: 'Invalid Voucher', message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _applying = false;
          _applyingCode = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(publicCouponsProvider);
    final isDark = AppHelperFunctions.isDarkMode(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.background : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select a voucher',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: couponsAsync.when(
              data: (coupons) {
                if (coupons.isEmpty) {
                  return const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: AppEmptyStateWidget(
                        title: 'No vouchers found',
                        subtitle: 'There are no active vouchers at the moment.',
                        animation: 'assets/images/72785-searching.json',
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: coupons.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final c = coupons[index] as Map<String, dynamic>;
                        final code = c['code'] as String;
                        final isCurrentlyApplying = _applying && _applyingCode == code;

                        return Opacity(
                          opacity: _applying && !isCurrentlyApplying ? 0.5 : 1.0,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PromoTicketCard(
                                coupon: c,
                                isDark: isDark,
                                actionText: isCurrentlyApplying ? '...' : 'APPLY',
                                onActionTap: _applying ? null : () => _applyCoupon(code),
                              ),
                              if (isCurrentlyApplying)
                                const CircularProgressIndicator(color: AppColors.primary),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, _) => const TShimmerEffect(
                  width: double.infinity,
                  height: 110,
                  radius: 16,
                ),
              ),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
