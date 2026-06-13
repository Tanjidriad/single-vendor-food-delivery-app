import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters/formatter.dart';
import '../../data/orders_repository.dart';
import '../providers/order_tracking_provider.dart';
import '../providers/tracking_route_provider.dart';
import '../widgets/delivery_otp_card.dart';
import '../widgets/enhanced_eta_card.dart';
import '../widgets/external_tracking_card.dart';
import '../widgets/order_status_timeline.dart';
import '../../../../core/widgets/feedback/app_error_state.dart';
import '../../../../core/widgets/map/app_map_view.dart';
import '../utils/tracking_map_markers.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _confirming = false;

  Future<void> _confirmDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delivery'),
        content: const Text(
          'Have you received your order? Once confirmed, the order will be marked as delivered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Yes, Received'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _confirming = true);
    try {
      await ref.read(ordersRepositoryProvider).confirmDelivery(widget.orderId);
      ref.invalidate(orderTrackingProvider(widget.orderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _callRider(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingAsync = ref.watch(orderTrackingProvider(widget.orderId));
    final routeAsync = ref.watch(trackingRouteProvider(widget.orderId));

    return trackingAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(),
        body: AppErrorState(
          message: friendlyErrorMessage(e),
          onRetry: () {
            ref.invalidate(orderTrackingProvider(widget.orderId));
            ref.invalidate(trackingRouteProvider(widget.orderId));
          },
        ),
      ),
      data: (state) {
        final order = state.order;
        if (order == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final status = order['status'] as String? ?? 'PLACED';
        final rider = riderInfoFromOrder(order);
        final isExternalDelivery = order['deliveryService'] != null &&
            (order['deliveryService'] as String).isNotEmpty;
        final items = order['items'] as List<dynamic>? ?? [];
        final riderLocation = state.riderLocation;

        final mapMarkers = buildTrackingMapMarkers(order, riderLocation);
        final (mapLat, mapLng) = trackingMapCenter(order, mapMarkers);
        final hasRiderPin = mapMarkers.any((m) => m.id == 'rider');
        final hasLiveGps = riderLocation != null &&
            coordFromJson(riderLocation['latitude']) != null;
        final showMapLegend =
            !isExternalDelivery && status != 'DELIVERED' && mapMarkers.isNotEmpty;
        final routePoints = routeAsync.valueOrNull ?? const [];

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // --- LIVE MAP (top) ---
              // Split layout keeps Mapbox from covering the details panel
              // (platform views often draw above DraggableScrollableSheet).
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.38,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: AppMapView(
                        initialLatitude: mapLat,
                        initialLongitude: mapLng,
                        markers: mapMarkers,
                        route: routePoints,
                        fitMarkersInView:
                            mapMarkers.length > 1 || routePoints.length > 1,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(RoutePaths.home);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isExternalDelivery && mapMarkers.isEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: const Text(
                            'No map pins yet — place a new order with a map '
                            'delivery address to see restaurant and home.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    if (showMapLegend)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasRiderPin
                                    ? Icons.delivery_dining
                                    : Icons.map_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hasRiderPin
                                      ? (hasLiveGps
                                          ? 'Red line = route · Green = rider · Orange = restaurant · Blue = you'
                                          : 'Red line = route · Green = rider (estimated) · Orange = restaurant · Blue = you')
                                      : 'Red line = route · Orange = restaurant · Blue = delivery address',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // --- ORDER DETAILS (always visible below map) ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      EnhancedEtaCard(order: order),
                      const SizedBox(height: 24),
                      if (status == 'DELIVERY_FAILED' ||
                          status == 'RETURNED_TO_RESTAURANT')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _DeliveryFailedCard(order: order),
                        ),
                      OrderStatusTimeline(currentStatus: status),
                      const SizedBox(height: 24),
                      if (status != 'DELIVERED' && !isExternalDelivery) ...[
                        const Text(
                          'Your Rider',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _RiderCard(
                          rider: rider,
                          onCall: () => _callRider(rider.phone),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (isExternalDelivery)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: ExternalTrackingCard(
                            deliveryService: order['deliveryService'] as String,
                            trackingId: order['trackingId'] as String? ?? '',
                            trackingUrl: order['trackingUrl'] as String?,
                          ),
                        ),
                      if (!isExternalDelivery &&
                          status == 'ON_THE_WAY' &&
                          order['deliveryOtp'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: DeliveryOtpCard(
                            otp: order['deliveryOtp'] as String,
                          ),
                        ),
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final raw in items)
                              if (raw is Map<String, dynamic>)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${raw['quantity']}x ${raw['name']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        AppFormatter.formatCurrency(
                                          orderItemLineTotal(raw),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            const Divider(height: 24, color: Color(0xFFF3F4F6)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  AppFormatter.formatCurrency(
                                    orderGrandTotal(order),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isExternalDelivery && status == 'ON_THE_WAY') ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _confirming ? null : _confirmDelivery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _confirming
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Mark as Received',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.rider, required this.onCall});

  final OrderRiderInfo rider;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final canContact = rider.isAssigned && rider.phone != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: rider.isAssigned
                ? AppColors.primary.withValues(alpha: 0.12)
                : const Color(0xFFE5E7EB),
            child: Icon(
              Icons.person,
              color: rider.isAssigned ? AppColors.primary : const Color(0xFF9CA3AF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  rider.subtitle,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: canContact ? onCall : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: canContact
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call,
                color: canContact ? AppColors.primary : const Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryFailedCard extends StatelessWidget {
  const _DeliveryFailedCard({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentMethod = order['paymentMethod'] as String? ?? 'COD';
    final paymentStatus = order['paymentStatus'] as String? ?? 'PENDING';
    final prepaid =
        paymentMethod == 'ONLINE' && paymentStatus == 'PAID';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Delivery issue',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            prepaid
                ? "We couldn't complete your delivery. Your refund is being processed — you'll hear from us within 24 hours."
                : "We couldn't complete your delivery. You were not charged for this order. Our team is resolving this now.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
