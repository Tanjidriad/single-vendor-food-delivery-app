import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/orders_repository.dart';
import '../providers/order_tracking_provider.dart';
import '../providers/tracking_route_provider.dart';
import '../widgets/delivery_otp_card.dart';
import '../widgets/enhanced_eta_card.dart';
import '../widgets/external_tracking_card.dart';
import '../widgets/order_chat_sheet.dart';
import '../widgets/order_status_timeline.dart';
import '../widgets/tracking_delivery_failed_card.dart';
import '../widgets/tracking_order_summary.dart';
import '../widgets/tracking_rider_card.dart';
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
                          child: TrackingDeliveryFailedCard(order: order),
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
                        TrackingRiderCard(
                          rider: rider,
                          onCall: () => _callRider(rider.phone),
                          onMessage: rider.isAssigned
                              ? () => OrderChatSheet.show(
                                    context,
                                    orderId: widget.orderId,
                                    riderName: rider.name ?? rider.title,
                                  )
                              : null,
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
                      TrackingOrderSummary(items: items, order: order),
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
