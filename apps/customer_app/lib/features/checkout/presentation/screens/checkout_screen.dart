import '../../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../../../core/utils/popups/full_screen_loader.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../orders/data/orders_repository.dart';
import '../../../profile/presentation/providers/addresses_providers.dart';
import '../../../profile/presentation/providers/checkout_address_provider.dart';
import '../../../restaurant/data/restaurant_repository.dart';
import '../../../../core/widgets/map/app_map_view.dart';
import '../../../../core/widgets/map/models/app_map_marker.dart';
import '../../../../core/widgets/feedback/premium_stepper.dart';
import '../../../cart/presentation/widgets/coupon_section.dart';
import '../../data/payments_repository.dart';
import 'bkash_payment_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _couponController = TextEditingController();
  final _instructionsController = TextEditingController();
  double? _deliveryFee;
  double? _tax;
  double? _packaging;
  bool _quoteLoading = false;
  bool _placing = false;
  String _paymentMethod = 'COD';
  late final String _placeOrderIdempotencyKey = createPlaceOrderIdempotencyKey();

  @override
  void dispose() {
    _couponController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(addressesListProvider);
      _quote();
    });
  }

  Map<String, dynamic>? _deliveryAddress() => ref.read(checkoutAddressProvider);

  double? _coord(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatAddressLine(Map<String, dynamic> a) {
    final line1 = a['line1'] as String? ?? '';
    final city = a['city'] as String?;
    return city != null && city.isNotEmpty ? '$line1, $city' : line1;
  }

  Future<void> _quote() async {
    final restaurantId = ref.read(restaurantIdProvider);
    final address = _deliveryAddress();
    if (restaurantId == null || address == null) return;
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
      setState(() {
        _deliveryFee = (quote['deliveryFee'] as num?)?.toDouble();
        _tax = (quote['tax'] as num?)?.toDouble();
        _packaging = (quote['packagingFee'] as num?)?.toDouble();
        _quoteLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _quoteLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load delivery fee. Pull to refresh or change address.',
          ),
        ),
      );
    }
  }

  Future<void> _place() async {
    final restaurantId = ref.read(restaurantIdProvider);
    final address = _deliveryAddress();
    if (restaurantId == null) return;

    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a delivery address before placing your order.'),
        ),
      );
      context.push('${RoutePaths.addresses}?select=true');
      return;
    }

    final lat = _coord(address['latitude']);
    final lng = _coord(address['longitude']);
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selected address is missing coordinates. Re-save the address.',
          ),
        ),
      );
      context.push('${RoutePaths.addresses}?select=true');
      return;
    }

    final cart = ref.read(cartProvider);
    setState(() => _placing = true);
    AppFullScreenLoader.openLoadingDialog(
      context, 
      'Placing order...', 
      'assets/images/141397-loading-juggle.json'
    );

    final instructions = _instructionsController.text.trim();

    try {
      final order = await ref.read(ordersRepositoryProvider).placeOrder({
        'restaurantId': restaurantId,
        'orderType': 'DELIVERY',
        'paymentMethod': _paymentMethod,
        'deliveryAddress': _formatAddressLine(address),
        'deliveryLat': lat,
        'deliveryLng': lng,
        if (instructions.isNotEmpty) 'deliveryNote': instructions,
        if (cart.couponCode != null) 'couponCode': cart.couponCode,
        'items': cart.items.map((i) => i.toOrderItemJson()).toList(),
        'idempotencyKey': _placeOrderIdempotencyKey,
      });
      final orderId = order['id'] as String;

      if (_paymentMethod == 'ONLINE') {
        final payment = await ref
            .read(paymentsRepositoryProvider)
            .initiateOnline(orderId);
        if (!mounted) return;
        AppFullScreenLoader.stopLoading(context);

        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => BkashPaymentScreen(
              orderId: orderId,
              paymentId: payment['paymentId'] as String,
              checkoutUrl: payment['checkoutUrl'] as String,
              callbackUrlPrefix: payment['callbackUrl'] as String,
            ),
          ),
        );

        if (paid != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Payment was not completed. Your order is saved as unpaid.',
                ),
              ),
            );
          }
          return;
        }
      } else {
        if (!mounted) return;
        AppFullScreenLoader.stopLoading(context);
      }

      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      context.go(RoutePaths.orderSuccessWithId(orderId));
    } catch (e) {
      if (mounted) {
        AppFullScreenLoader.stopLoading(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Map<String, dynamic>?>(checkoutAddressProvider, (prev, next) {
      if (next != null && next != prev) _quote();
    });

    final cart = ref.watch(cartProvider);
    final deliveryAddress = ref.watch(checkoutAddressProvider);
    final addressesAsync = ref.watch(addressesListProvider);
    final hasAddress = deliveryAddress != null;
    final addressesLoading = addressesAsync.isLoading;

    final total =
        cart.subtotal +
        (_deliveryFee ?? 0) +
        (_tax ?? 0) +
        (_packaging ?? 0) -
        cart.discount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header & Stepper
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1F2937),
                          ),
                          onPressed: () => context.pop(),
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checkout',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                'Golpo - Mirpur 06',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Premium Progress Stepper
                  const PremiumStepper(currentStep: 3),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // Delivery Address Section
                  const Text(
                    'Delivery address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child:
                                  hasAddress &&
                                      _coord(deliveryAddress['latitude']) !=
                                          null
                                  ? AppMapView(
                                      initialLatitude: _coord(
                                        deliveryAddress['latitude'],
                                      )!,
                                      initialLongitude: _coord(
                                        deliveryAddress['longitude'],
                                      )!,
                                      markers: [
                                        AppMapMarker(
                                          id: 'dest',
                                          latitude: _coord(
                                            deliveryAddress['latitude'],
                                          )!,
                                          longitude: _coord(
                                            deliveryAddress['longitude'],
                                          )!,
                                        ),
                                      ],
                                    )
                                  : Container(
                                      color: const Color(0xFFF3F4F6),
                                      child: const Icon(
                                        Icons.add_location_alt,
                                        color: AppColors.primary,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasAddress
                                        ? (deliveryAddress['label']
                                                  as String? ??
                                              'Delivery')
                                        : 'No address selected',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hasAddress
                                        ? _formatAddressLine(deliveryAddress)
                                        : 'Add an address for delivery',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF4B5563),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!hasAddress)
                              TextButton(
                                onPressed: () => context.push(
                                  '${RoutePaths.addresses}?select=true',
                                ),
                                child: const Text(
                                  'Add Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF9CA3AF),
                                ),
                                onPressed: () => context.push(
                                  '${RoutePaths.addresses}?select=true',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            TextField(
                              controller: _instructionsController,
                              decoration: InputDecoration(
                                hintText:
                                    '(Optional) Floor or Apt No or tell us ...',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                            Positioned(
                              left: 12,
                              top: -8,
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: const Text(
                                  'Delivery instructions',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- PAYMENT METHOD ---
                  const Text(
                    'Payment method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PaymentMethodTile(
                    title: 'Cash on delivery',
                    subtitle: 'Pay when your order arrives',
                    selected: _paymentMethod == 'COD',
                    onTap: () => setState(() => _paymentMethod = 'COD'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentMethodTile(
                    title: 'bKash',
                    subtitle: 'Pay now with bKash (sandbox test)',
                    selected: _paymentMethod == 'ONLINE',
                    onTap: () => setState(() => _paymentMethod = 'ONLINE'),
                  ),
                  const SizedBox(height: 24),
                  const Text('Promo Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const CouponSection(),
                  const SizedBox(height: 24),

                  // Order Items Summary
                  for (var item in cart.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.quantity}x ${item.name}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            AppFormatter.formatCurrency(
                              item.unitPrice * item.quantity,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFFE5E7EB)),
                  ),

                  // Pricing Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        AppFormatter.formatCurrency(cart.subtotal),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Fee',
                        style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                      ),
                      Text(
                        _quoteLoading && _deliveryFee == null
                            ? 'Calculating…'
                            : AppFormatter.formatCurrency(_deliveryFee ?? 0),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                  if ((_tax ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tax',
                          style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                        ),
                        Text(
                          AppFormatter.formatCurrency(_tax!),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                  ],
                  if ((_packaging ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Packaging Fee',
                          style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                        ),
                        Text(
                          AppFormatter.formatCurrency(_packaging!),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                  ],
                  if (cart.discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Discount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          '-${AppFormatter.formatCurrency(cart.discount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '(incl. fees and tax)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        AppFormatter.formatCurrency(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Footer
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (_placing || addressesLoading || !hasAddress)
                ? null
                : _place,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _placing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _paymentMethod == 'ONLINE' ? 'Place order & pay' : 'Place order',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AppColors.primary : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
