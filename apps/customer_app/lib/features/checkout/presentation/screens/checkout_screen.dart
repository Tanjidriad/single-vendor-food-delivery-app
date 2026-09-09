import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../../../core/utils/popups/full_screen_loader.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/feedback/premium_stepper.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/presentation/widgets/coupon_section.dart';
import '../../../orders/data/orders_repository.dart';
import '../../../profile/presentation/providers/addresses_providers.dart';
import '../../../profile/presentation/providers/checkout_address_provider.dart';
import '../../../restaurant/data/restaurant_repository.dart';
import '../../data/payments_repository.dart';
import '../utils/checkout_format.dart';
import '../widgets/checkout_address_card.dart';
import '../widgets/checkout_payment_section.dart';
import '../widgets/checkout_price_summary.dart';
import 'bkash_payment_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _instructionsController = TextEditingController();
  double? _deliveryFee;
  double? _tax;
  double? _packaging;
  bool _quoteLoading = false;
  bool _placing = false;
  String? _quoteError;
  String _paymentMethod = 'COD';
  late final String _placeOrderIdempotencyKey = createPlaceOrderIdempotencyKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(addressesListProvider);
      _quote();
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _deliveryAddress() => ref.read(checkoutAddressProvider);

  void _goToAddressSelection() {
    unawaited(context.push('${RoutePaths.addresses}?select=true'));
  }

  Future<void> _quote() async {
    final restaurantId = ref.read(restaurantIdProvider);
    final address = _deliveryAddress();
    if (restaurantId == null || address == null) return;
    final lat = coord(address['latitude']);
    final lng = coord(address['longitude']);
    if (lat == null || lng == null) return;

    setState(() {
      _quoteLoading = true;
      _quoteError = null;
    });
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
      setState(() {
        _quoteLoading = false;
        _quoteError = friendlyErrorMessage(e);
      });
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
      _goToAddressSelection();
      return;
    }

    final lat = coord(address['latitude']);
    final lng = coord(address['longitude']);
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selected address is missing coordinates. Re-save the address.',
          ),
        ),
      );
      _goToAddressSelection();
      return;
    }

    final cart = ref.read(cartProvider);
    setState(() => _placing = true);
    AppFullScreenLoader.openLoadingDialog(
      context,
      'Placing order...',
      'assets/images/141397-loading-juggle.json',
    );

    final instructions = _instructionsController.text.trim();

    try {
      final order = await ref.read(ordersRepositoryProvider).placeOrder({
        'restaurantId': restaurantId,
        'orderType': 'DELIVERY',
        'paymentMethod': _paymentMethod,
        'deliveryAddress': formatAddressLine(address),
        'deliveryLat': lat,
        'deliveryLng': lng,
        if (instructions.isNotEmpty) 'deliveryNote': instructions,
        if (cart.couponCode != null) 'couponCode': cart.couponCode,
        'items': cart.items.map((i) => i.toOrderItemJson()).toList(),
        'idempotencyKey': _placeOrderIdempotencyKey,
      });
      final orderId = order['id'] as String;

      if (_paymentMethod == 'ONLINE') {
        final payment =
            await ref.read(paymentsRepositoryProvider).initiateOnline(orderId);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Map<String, dynamic>?>(checkoutAddressProvider, (prev, next) {
      if (next != null && next != prev) {
        setState(() => _quoteError = null);
        _quote();
      }
    });

    final cart = ref.watch(cartProvider);
    final deliveryAddress = ref.watch(checkoutAddressProvider);
    final addressesAsync = ref.watch(addressesListProvider);
    final hasAddress = deliveryAddress != null;
    final addressesLoading = addressesAsync.isLoading;

    final total = cart.subtotal +
        (_deliveryFee ?? 0) +
        (_tax ?? 0) +
        (_packaging ?? 0) -
        cart.discount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              restaurantName:
                  ref.watch(restaurantProvider).valueOrNull?['name'] as String? ??
                      '',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  const Text(
                    'Delivery address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  CheckoutAddressCard(
                    address: deliveryAddress,
                    instructionsController: _instructionsController,
                    onSelectAddress: _goToAddressSelection,
                  ),
                  const SizedBox(height: 12),
                  if (_quoteError != null) _QuoteErrorBanner(message: _quoteError!),
                  const SizedBox(height: 12),
                  CheckoutPaymentSection(
                    selectedMethod: _paymentMethod,
                    onSelect: (method) => setState(() => _paymentMethod = method),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Promo Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const CouponSection(),
                  const SizedBox(height: 24),
                  CheckoutPriceSummary(
                    cart: cart,
                    deliveryFee: _deliveryFee,
                    tax: _tax,
                    packaging: _packaging,
                    quoteLoading: _quoteLoading,
                    total: total,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PlaceOrderBar(
        paymentMethod: _paymentMethod,
        placing: _placing,
        enabled: !_placing && !addressesLoading && hasAddress && _quoteError == null,
        onPlace: _place,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.restaurantName});

  final String restaurantName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                      Text(
                        restaurantName,
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
          const SizedBox(height: 16),
          const PremiumStepper(currentStep: 3),
        ],
      ),
    );
  }
}

class _QuoteErrorBanner extends StatelessWidget {
  const _QuoteErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_off_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB91C1C),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({
    required this.paymentMethod,
    required this.placing,
    required this.enabled,
    required this.onPlace,
  });

  final String paymentMethod;
  final bool placing;
  final bool enabled;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? onPlace : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: placing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  paymentMethod == 'ONLINE' ? 'Place order & pay' : 'Place order',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
