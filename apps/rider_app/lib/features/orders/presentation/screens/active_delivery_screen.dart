import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rider_app/features/earnings/presentation/providers/earnings_summary_provider.dart';

import '../../../../core/map/geo_math.dart';
import '../../../../core/map/geo_point.dart';
import '../../../../core/map/map_marker.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/services/location_broadcast.dart';
import '../../../../core/services/navigation_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/map/app_map_view.dart';
import '../../../../core/websockets/socket_service.dart';
import '../../data/active_order_view.dart';
import '../../data/orders_repository.dart';
import '../providers/delivery_progress_controller.dart';
import '../providers/location_provider.dart';
import '../assignment_navigation.dart';
import '../providers/assignment_sync_controller.dart';
import '../providers/order_providers.dart';
import '../providers/route_provider.dart';
import '../widgets/delivery_chat_sheet.dart';
import '../widgets/delivery_panel.dart';
import '../widgets/delivery_status_banner.dart';
import '../widgets/delivery_top_bar.dart';
import '../widgets/proof_of_delivery_sheet.dart';

/// The active delivery screen (Requirements 4, 5).
///
/// Owns the map, the live GPS / heading derivation, and the step →
/// order-status state machine (via [DeliveryProgressController]); hands off
/// turn-by-turn navigation to an external app via [NavigationLauncher]. The UI
/// is composed from [DeliveryTopBar], [DeliveryPanel], [DeliveryStatusBanner],
/// [ProofOfDeliverySheet], and [DeliveryChatSheet].
///
/// Map data crosses the screen boundary as SDK-neutral [GeoPoint]/[MapMarker]
/// values only — this screen imports no map SDK and sources the live position
/// from the location stream, satisfying Requirement 10.3.
class ActiveDeliveryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? orderData;

  const ActiveDeliveryScreen({super.key, this.orderData});

  @override
  ConsumerState<ActiveDeliveryScreen> createState() =>
      _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends ConsumerState<ActiveDeliveryScreen> {
  /// Hands off navigation and dialing to external apps. Defaults are fine for
  /// the screen; the launcher reports success as a bool rather than throwing.
  final NavigationLauncher _launcher = const NavigationLauncher();

  /// Bumped to force a fresh [SwipeAction] (resetting the handle to the start)
  /// when the proof-of-delivery sheet is dismissed without completing, so the
  /// rider can swipe again. Step advances reset the control via the step key.
  int _swipeNonce = 0;

  /// The previous live position, used to derive the rider's heading from
  /// consecutive fixes. [GeoPoint] carries no heading, so the directional
  /// rider marker's [MapMarker.headingDegrees] (Requirement 6.6) is computed
  /// from the bearing between the last two distinct positions.
  GeoPoint? _previousLocation;

  /// The most recently computed heading in degrees `[0, 360)`, retained so the
  /// marker keeps a stable facing direction when the rider is stationary (a
  /// repeated position yields no new bearing).
  double? _lastHeading;

  /// Updates the tracked heading from a freshly received position.
  ///
  /// When the new position differs from the previous one, the bearing
  /// previous→current becomes the new heading; identical positions leave the
  /// last heading untouched. Returns the heading to use for the current frame.
  double? _updateHeading(GeoPoint current) {
    final previous = _previousLocation;
    if (previous != null) {
      final bearing = bearingBetween(previous, current);
      if (bearing != null) _lastHeading = bearing;
    }
    _previousLocation = current;
    return _lastHeading;
  }

  Map<String, dynamic> get _orderMap =>
      widget.orderData ?? ref.read(activeOrderProvider) ?? const {};

  /// Confirms the current delivery step via the [DeliveryProgressController].
  ///
  /// - `advanced`  → the step advances; the keyed [SwipeAction] is recreated.
  /// - `proofOfDelivery` → present the retained POD sheet; on dismissal the
  ///   swipe is reset so the rider can retry (Requirement 4.8).
  /// - `failed`    → surface the controller error and rethrow so the
  ///   [SwipeAction] handle springs back and re-enables, while
  ///   `deliveryStepProvider` is left unchanged (Requirement 4.10).
  Future<void> _onSwipeConfirmed(
    String? dropoffPhotoUrl,
    String? pickupExperience,
  ) async {
    final result = await ref
        .read(deliveryProgressControllerProvider.notifier)
        .confirmCurrentStep();

    if (!mounted) return;

    switch (result) {
      case DeliveryConfirmResult.advanced:
        // Step advanced (Req 4.6/4.7); the SwipeAction is keyed by the step so
        // a fresh control is built for the next stage.
        break;
      case DeliveryConfirmResult.proofOfDelivery:
        await _showProofOfDelivery(dropoffPhotoUrl, pickupExperience);
        // POD sheet closed without completing the order: reset the swipe so
        // the rider can attempt confirmation again.
        if (mounted) setState(() => _swipeNonce++);
        break;
      case DeliveryConfirmResult.failed:
        final error =
            ref.read(deliveryProgressControllerProvider).error ??
            'Could not update order status';
        _showSnack(error, isError: true);
        // Throw so the SwipeAction springs the handle back and re-enables
        // (Requirement 4.10); the step is retained by the controller.
        throw Exception(error);
      case DeliveryConfirmResult.ignored:
        break;
    }
  }

  /// Opens the current destination in an external navigation app (Req 4.4); if
  /// no app can handle it, shows a "no navigation app found" message (Req 4.5).
  Future<void> _handleNavigate(GeoPoint? destination) async {
    if (destination == null) {
      _showSnack('Destination location is unavailable', isError: true);
      return;
    }
    final launched = await _launcher.openExternalNavigation(destination);
    if (!launched && mounted) {
      _showSnack('No navigation app found', isError: true);
    }
  }

  /// Launches the device dialer with a `tel:` URI for the customer phone
  /// (Req 5.2); if the dialer cannot launch, shows a failure message (Req 5.6).
  Future<void> _handleCall(String phone) async {
    final launched = await _launcher.dial(phone);
    if (!launched && mounted) {
      _showSnack('Could not start the call', isError: true);
    }
  }

  /// Opens the defined chat entry for the active order (Req 5.3, 5.4).
  ///
  /// Backend chat contracts are out of scope, so this opens a minimal,
  /// self-contained chat surface keyed by the order id. It is deliberately a
  /// separate affordance from the call control.
  void _handleMessage(ActiveOrderView order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryChatSheet(
        orderId: order.id,
        customerName: order.customerName,
      ),
    );
  }

  Future<void> _showProofOfDelivery(
    String? dropoffPhotoUrl,
    String? pickupExperience,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProofOfDeliverySheet(
      orderId: _orderMap['id'] as String? ?? '',
      dropoffPhotoUrl: dropoffPhotoUrl,
      pickupExperience: pickupExperience,
      onComplete: _onDeliveryComplete,
    ),
  );

  Future<void> _onDeliveryComplete() async {
    clearRiderDeliveryState(ref);
    ref.invalidate(earningsSummaryProvider);

    if (!mounted) return;
    context.go(RoutePaths.home);

    final pending = await ref
        .read(assignmentSyncControllerProvider.notifier)
        .syncNow();
    if (!mounted) return;

    for (final assignment in pending) {
      presentIncomingAssignmentIfIdle(ref, context, assignment);
      break;
    }
    tryPresentPendingAssignment(ref, context);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.offline : AppColors.primary,
      ),
    );
  }

  Future<void> _reportDeliveryProblem(String orderId) async {
    const reasons = <String, String>{
      'CUSTOMER_UNREACHABLE': 'Customer unreachable',
      'WRONG_ADDRESS': 'Wrong address',
      'ACCIDENT_EMERGENCY': 'Accident / emergency',
      'CUSTOMER_REFUSED': 'Customer refused',
      'APP_CRASH_MANUAL': 'App issue / manual report',
    };

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BottomSheetHandle(),
                const SizedBox(height: 12),
                Text(
                  'Report a problem',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This releases the order so support can help.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                for (final entry in reasons.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, entry.key),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(entry.value),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    final foodReturned = ref.read(deliveryStepProvider) > 0;

    try {
      await ref.read(ordersRepositoryProvider).reportDeliveryException(
            orderId,
            reason: selected,
            foodReturned: foodReturned,
          );
      clearRiderDeliveryState(ref);
      if (!mounted) return;
      _showSnack('Problem reported. You can accept new orders.');
      context.go(RoutePaths.home);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ActiveOrderView.fromJson(_orderMap);
    final currentStep = ref.watch(deliveryStepProvider);

    // Activate the live GPS broadcast coordinator for the duration of the
    // active delivery (Requirements 6.2–6.5, 6.7). The provider is otherwise
    // inert; watching it here keeps it alive while this screen is mounted so
    // each new position is broadcast via `SocketService.sendLocation` (with a
    // reconnect on a disconnected socket) while an order is active, and it is
    // torn down — stopping broadcasts — once the screen is left after the
    // order clears. The coordinator itself decides per-position whether to
    // emit, so no order means no broadcast.
    ref.watch(locationBroadcastProvider);

    ref.watch(socketConnectedStreamProvider);
    final socketConnected = ref.read(socketServiceProvider).isConnected;

    final destination = order.destinationForStep(currentStep);
    final currentLocation = ref.watch(locationStreamProvider).value;

    // Derive the rider's heading from consecutive positions; GeoPoint carries
    // no heading, so the directional rider marker (Req 6.6) uses the bearing
    // between the last two distinct fixes.
    final heading = currentLocation == null
        ? _lastHeading
        : _updateHeading(currentLocation);

    // Live route from the rider to the current destination, in GeoPoint only.
    List<GeoPoint>? route;
    if (currentLocation != null && destination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(liveRouteProvider.notifier)
            .updateLocation(currentLocation, destination);
      });
      route = ref.watch(liveRouteProvider).route;
    }

    // Pickup/dropoff markers plus the directional rider marker, all as
    // SDK-neutral MapMarkers. The rider marker reflects the live position and
    // derived heading (Requirement 6.6).
    final markers = <MapMarker>[
      if (order.restaurantPoint != null)
        MapMarker(point: order.restaurantPoint!, kind: MapMarkerKind.pickup),
      if (order.dropoffPoint != null)
        MapMarker(point: order.dropoffPoint!, kind: MapMarkerKind.dropoff),
      if (currentLocation != null)
        MapMarker(
          point: currentLocation,
          kind: MapMarkerKind.rider,
          headingDegrees: heading,
        ),
    ];

    final gpsWeak = currentLocation == null;

    return Scaffold(
      body: Stack(
        children: [
          AppMapView(
            initialCamera: currentLocation ?? destination,
            route: route,
            markers: markers.isEmpty ? null : markers,
          ),
          DeliveryTopBar(
            etaMinutes: order.etaMinutes,
            onReportProblem: () => _reportDeliveryProblem(order.id),
          ),
          if (!socketConnected || gpsWeak)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 52,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              child: Column(
                children: [
                  if (!socketConnected)
                    const DeliveryStatusBanner(
                      icon: LucideIcons.wifiOff,
                      message: 'Reconnecting — updates may be delayed',
                      color: AppColors.busy,
                    ),
                  if (!socketConnected && gpsWeak)
                    const SizedBox(height: AppSpacing.sm),
                  if (gpsWeak)
                    const DeliveryStatusBanner(
                      icon: LucideIcons.mapPinOff,
                      message: 'GPS signal weak — enable location for live tracking',
                      color: AppColors.offline,
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DeliveryPanel(
              order: order,
              currentStep: currentStep,
              swipeNonce: _swipeNonce,
              onNavigate: () => _handleNavigate(destination),
              onCall: order.hasPhone
                  ? () => _handleCall(order.customerPhone!)
                  : null,
              onMessage: () => _handleMessage(order),
              onCustomerUnavailable: () => _reportDeliveryProblem(order.id),
              onSwipeConfirmed: _onSwipeConfirmed,
            ),
          ),
        ],
      ),
    );
  }
}
