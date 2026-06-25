import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cwt/empty_state_widget.dart';
import '../../../../core/widgets/feedback/premium_stepper.dart';
import '../../../orders/data/orders_repository.dart';
import '../../../profile/presentation/providers/checkout_address_provider.dart';
import '../../../restaurant/data/restaurant_repository.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_delivery_row.dart';
import '../widgets/cart_order_summary.dart';
import '../widgets/cart_total_row.dart';
import '../widgets/premium_cart_item_card.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  double? _deliveryFee;
  int? _etaMinutes;
  bool _quoteLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _quote());
  }

  double? _coord(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _quote() async {
    final restaurantId = ref.read(restaurantIdProvider);
    final address = ref.read(checkoutAddressProvider);
    if (restaurantId == null || address == null) {
      setState(() {
        _deliveryFee = null;
        _etaMinutes = null;
      });
      return;
    }

    final lat = _coord(address['latitude']);
    final lng = _coord(address['longitude']);
    if (lat == null || lng == null) return;

    setState(() => _quoteLoading = true);
    final cart = ref.read(cartProvider);
    try {
      final quote = await ref.read(ordersRepositoryProvider).deliveryFeeQuote({
        'restaurantId': restaurantId,
        'deliveryLat': lat,
        'deliveryLng': lng,
        'subtotal': cart.subtotal,
      });
      if (!mounted) return;
      setState(() {
        _deliveryFee = (quote['deliveryFee'] as num?)?.toDouble();
        _etaMinutes = (quote['etaMinutes'] as num?)?.toInt();
        _quoteLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _deliveryFee = null;
          _etaMinutes = null;
          _quoteLoading = false;
        });
      }
    }
  }

  String _addressLabel(Map<String, dynamic>? address) {
    if (address == null) return 'Add delivery address';
    final line1 = address['line1'] as String? ?? '';
    final city = address['city'] as String?;
    if (line1.isEmpty) return 'Add delivery address';
    return city != null && city.isNotEmpty ? '$line1, $city' : line1;
  }

  String _deliveryRowLabel() {
    if (_quoteLoading) return 'Calculating delivery time…';
    if (_etaMinutes != null && _etaMinutes! > 0) {
      final low = (_etaMinutes! * 0.85).round();
      final high = (_etaMinutes! * 1.15).round();
      return 'Delivery: $low–$high min';
    }
    return 'Delivery time unavailable';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Map<String, dynamic>?>(checkoutAddressProvider, (prev, next) {
      if (next != prev) _quote();
    });

    final cart = ref.watch(cartProvider);
    final deliveryAddress = ref.watch(checkoutAddressProvider);
    final deliveryFee = _deliveryFee ?? 0;
    final total = cart.subtotal - cart.discount + deliveryFee;

    if (cart.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Cart',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: AppEmptyStateWidget(
          title: 'Your cart is empty',
          subtitle: 'Browse the menu and add something tasty',
          animation: 'assets/images/lady-adding-product-in-cart-animation.json',
          actionText: 'Browse menu',
          onActionPressed: () => context.go(RoutePaths.home),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header & Stepper
            Container(
              padding: const EdgeInsets.only(
                top: 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.primary),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Cart',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                                height: 1.2,
                              ),
                            ),
                            Text(
                              ref.watch(restaurantProvider).valueOrNull?['name'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // balance back button
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  // Premium Progress Stepper
                  const PremiumStepper(currentStep: 2),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  // Delivery Time
                  CartDeliveryRow(
                    timeLabel: _deliveryRowLabel(),
                    addressLabel: _addressLabel(deliveryAddress),
                    hasAddress: deliveryAddress != null,
                    onChangeAddress: () => context.push(
                      '${RoutePaths.addresses}?select=true',
                    ),
                  ),
                  Container(height: 8, color: const Color(0xFFF3F4F6)),

                  // Cart Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var item in cart.items)
                          PremiumCartItemCard(item: item),
                        TextButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.add,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          label: const Text(
                            'Add more items',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 8, color: const Color(0xFFF3F4F6)),

                  // Order Summary
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CartOrderSummary(cart: cart),
                  ),
                  Container(height: 8, color: const Color(0xFFF3F4F6)),

                  // Final Total
                  CartTotalRow(total: total),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.push(RoutePaths.checkout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Review payment and address',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
