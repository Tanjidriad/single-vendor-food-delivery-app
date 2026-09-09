import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/formatters/formatter.dart';
import 'package:lottie/lottie.dart';
import '../../../orders/data/orders_repository.dart';

/// Shown after a successful checkout before order tracking.
class OrderSuccessScreen extends ConsumerStatefulWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrderDetails());
  }

  Future<void> _loadOrderDetails() async {
    try {
      final data = await ref.read(ordersRepositoryProvider).getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data.raw;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatEta(Map<String, dynamic>? order) {
    if (order == null) return '—';
    final prep = (order['prepMinutes'] as num?)?.toInt() ?? 0;
    final route = (order['routeEtaMinutes'] as num?)?.toInt() ?? 0;
    final total = prep + route;
    if (total <= 0) return '—';
    final low = (total * 0.85).round();
    final high = (total * 1.15).round();
    return '$low–$high min';
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 22),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Default to BDT 0 if the call hasn't finished, or use the loaded order details
    final grandTotal = (_order?['grandTotal'] as num?)?.toDouble() ?? 0.0;
    final deliverTo = _order?['deliveryAddress'] as String? ?? '—';
    final etaLabel = _isLoading ? '—' : _formatEta(_order);

    return Scaffold(
      backgroundColor: AppColors.surface, // Pure white clean background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Close Button ---
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 28),
                  onPressed: () => context.go(RoutePaths.home),
                ),
              ),
              const Spacer(flex: 1),

              // --- Lottie Delivery Animation ---
              SizedBox(
                width: 250,
                height: 250,
                child: Lottie.asset(
                  'assets/images/order-complete-car-delivery-animation.json',
                  fit: BoxFit.contain,
                  repeat: false,
                ),
              ),
              const SizedBox(height: 16),

              // --- Main Celebration Headline ---
              Text(
                'Yay! Your order\nhas been placed.',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),

              // --- Subtext ---
              Text(
                _isLoading
                    ? 'We\'re confirming your delivery estimate.'
                    : etaLabel == '—'
                        ? 'We\'ll share an ETA once the restaurant accepts your order.'
                        : 'Your order should arrive in about $etaLabel.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const Spacer(flex: 1),

              // --- Order Info Summary Cards ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      icon: Icons.access_time_outlined,
                      label: 'Estimated time',
                      value: _isLoading ? 'Loading…' : etaLabel,
                    ),
                    const SizedBox(height: 20),
                    _buildSummaryRow(
                      icon: AppIcons.location,
                      label: 'Deliver to',
                      value: deliverTo,
                    ),
                    const SizedBox(height: 20),
                    _buildSummaryRow(
                      icon: Icons.credit_card_outlined,
                      label: 'Amount Paid',
                      value: _isLoading
                          ? 'Loading...'
                          : AppFormatter.formatCurrency(grandTotal),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              // --- Track Order Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go(RoutePaths.trackingWithId(widget.orderId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Track my order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
