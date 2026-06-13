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
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/map/app_map_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/swipe_action.dart';
import '../../data/active_order_view.dart';
import '../../data/orders_repository.dart';
import '../providers/delivery_progress_controller.dart';
import '../providers/location_provider.dart';
import '../assignment_navigation.dart';
import '../providers/assignment_sync_controller.dart';
import '../providers/order_providers.dart';
import '../providers/route_provider.dart';
import '../widgets/step_indicator.dart';

/// The redesigned active delivery screen (Requirements 4, 5).
///
/// Renders a horizontal [StepIndicator] for the current delivery step, hands
/// off turn-by-turn navigation to an external app via [NavigationLauncher], and
/// drives the step → order-status state machine through the
/// [DeliveryProgressController] behind a slide-to-confirm [SwipeAction]. The
/// existing [_ProofOfDeliverySheet] is retained for the final step. Real
/// contact actions are wired: a phone-gated call control and a distinct chat
/// entry.
///
/// Map data crosses the screen boundary as SDK-neutral [GeoPoint]/[MapMarker]
/// values only — this screen imports no map SDK and sources the live position
/// from [locationStreamProvider] (GeoPoint), satisfying Requirement 10.3.
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
      builder: (_) =>
          _ChatEntrySheet(orderId: order.id, customerName: order.customerName),
    );
  }

  Future<void> _showProofOfDelivery(
    String? dropoffPhotoUrl,
    String? pickupExperience,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ProofOfDeliverySheet(
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

    return Scaffold(
      body: Stack(
        children: [
          AppMapView(
            initialCamera: currentLocation ?? destination,
            route: route,
            markers: markers.isEmpty ? null : markers,
          ),
          _TopBar(
            etaMinutes: order.etaMinutes,
            onReportProblem: () => _reportDeliveryProblem(order.id),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _DeliveryPanel(
              order: order,
              currentStep: currentStep,
              swipeNonce: _swipeNonce,
              onNavigate: () => _handleNavigate(destination),
              onCall: order.hasPhone
                  ? () => _handleCall(order.customerPhone!)
                  : null,
              onMessage: () => _handleMessage(order),
              onSwipeConfirmed: _onSwipeConfirmed,
            ),
          ),
        ],
      ),
    );
  }
}

/// The top overlay: a back control and an optional ETA chip.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.etaMinutes,
    required this.onReportProblem,
  });

  final int? etaMinutes;
  final VoidCallback onReportProblem;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleIconButton(
              icon: LucideIcons.arrowLeft,
              onTap: () => context.go(RoutePaths.home),
            ),
            TextButton.icon(
              onPressed: onReportProblem,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.offline,
                backgroundColor: Colors.white,
              ),
              icon: const Icon(LucideIcons.triangleAlert, size: 18),
              label: const Text('Report'),
            ),
            if (etaMinutes != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.borderDark),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.navigation,
                      size: 16,
                      color: AppColors.inProgress,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$etaMinutes min away',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

/// The bottom delivery panel: step indicator, destination + contact actions,
/// navigate handoff, payment summary, and the confirm swipe.
class _DeliveryPanel extends StatefulWidget {
  const _DeliveryPanel({
    required this.order,
    required this.currentStep,
    required this.swipeNonce,
    required this.onNavigate,
    required this.onCall,
    required this.onMessage,
    required this.onSwipeConfirmed,
  });

  final ActiveOrderView order;
  final int currentStep;
  final int swipeNonce;
  final VoidCallback onNavigate;

  /// Null when the order has no phone, which hides the call control
  /// (Requirements 5.1, 5.5).
  final VoidCallback? onCall;
  final VoidCallback onMessage;
  final Future<void> Function(String? dropoffPhotoUrl, String? pickupExperience)
  onSwipeConfirmed;

  @override
  State<_DeliveryPanel> createState() => _DeliveryPanelState();
}

class _DeliveryPanelState extends State<_DeliveryPanel> {
  String? _dropoffPhotoUrl;
  String? _pickupExperience;

  bool get _atCustomer => widget.currentStep >= 2;

  String get _destinationName =>
      _atCustomer ? widget.order.customerName : widget.order.restaurantName;

  String get _destinationSubtitle =>
      _atCustomer ? widget.order.deliveryAddress : 'Pickup location';

  String get _swipeLabel {
    switch (widget.currentStep) {
      case 0:
        return 'Swipe — Arrived at Restaurant';
      case 1:
        return 'Swipe to Confirm Pickup';
      case 2:
        return 'Swipe — Start Delivery';
      case 3:
        return 'Swipe — Arrived at Customer';
      default:
        return 'Swipe to Complete';
    }
  }

  void _showSimulatedCamera() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Camera Simulator',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Simulating taking a photo...',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(
                () => _dropoffPhotoUrl = 'https://picsum.photos/400/400',
              );
            },
            child: const Text(
              'Take Photo',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCod = widget.order.paymentMethod == 'COD';
    final cashAmount = (isCod && widget.order.grandTotal != null)
        ? formatCurrency(widget.order.grandTotal!)
        : formatCurrency(0);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        border: Border(top: BorderSide(color: AppColors.borderDark)),
        boxShadow: [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BottomSheetHandle(),
                const SizedBox(height: AppSpacing.sm),

                // Horizontal step indicator (Requirements 4.1, 4.2).
                StepIndicator(currentStep: widget.currentStep),
                const SizedBox(height: AppSpacing.xxl),

                // Destination + contact actions.
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        _atCustomer ? LucideIcons.user : LucideIcons.store,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _destinationName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _destinationSubtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chat entry — distinct from the call control (Req 5.3, 5.4).
                    _RoundActionButton(
                      icon: LucideIcons.messageSquare,
                      color: AppColors.inProgress,
                      tooltip: 'Message customer',
                      onTap: widget.onMessage,
                    ),
                    // Call control — shown only when a phone is present
                    // (Requirements 5.1, 5.5).
                    if (widget.onCall != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      _RoundActionButton(
                        icon: LucideIcons.phone,
                        color: AppColors.online,
                        tooltip: 'Call customer',
                        onTap: widget.onCall!,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Collapsible order items
                if (widget.order.items.isNotEmpty)
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.primary,
                      title: Text(
                        '${widget.order.items.length} items',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      children: widget.order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item.addons.isNotEmpty)
                                      Text(
                                        item.addons.join(', '),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCurrency(item.unitPrice * item.quantity),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(color: AppColors.borderDark),
                const SizedBox(height: AppSpacing.md),

                // Payment summary
                if (!_atCustomer)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No payment at pickup',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (isCod)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            LucideIcons.checkCircle2,
                            color: AppColors.online,
                            size: 20,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Total payment',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 28,
                          top: 4,
                          bottom: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Collect cash from customer',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  cashAmount,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        LucideIcons.penLine,
                                        size: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "I don't have change",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                if (_atCustomer)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Row(
                      children: [
                        Icon(
                          _dropoffPhotoUrl != null
                              ? LucideIcons.checkCircle2
                              : LucideIcons.camera,
                          color: _dropoffPhotoUrl != null
                              ? AppColors.online
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dropoffPhotoUrl != null
                                    ? 'Photo attached'
                                    : "Photo at the customer's door",
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_dropoffPhotoUrl == null)
                                const Text(
                                  'Add a photo as proof of drop-off',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_dropoffPhotoUrl == null)
                          InkWell(
                            onTap: _showSimulatedCamera,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    LucideIcons.camera,
                                    size: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add photo',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                if (!_atCustomer)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'How is the pick up experience?',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_atCustomer)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Customer unavailable',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                // External navigation handoff (Requirements 4.3, 4.4, 4.5).
                OutlinedButton.icon(
                  onPressed: widget.onNavigate,
                  icon: const Icon(LucideIcons.navigation, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  label: const Text(
                    'Navigate',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Confirm swipe driving the DeliveryProgressController
                SwipeAction(
                  key: ValueKey(
                    'confirm-swipe-${widget.currentStep}-${widget.swipeNonce}',
                  ),
                  label: _swipeLabel,
                  icon: LucideIcons.chevronsRight,
                  onConfirmed: () => widget.onSwipeConfirmed(
                    _dropoffPhotoUrl,
                    _pickupExperience,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small circular icon button used in the top overlay.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDark),
          boxShadow: AppShadows.soft,
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}

/// A round, tinted contact-action button (call / message).
class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

/// A minimal, self-contained chat entry surface for the active order.
///
/// Defines the chat entry point (Requirement 5.4) keyed by the order id while
/// the backend chat contract remains out of scope. Kept deliberately distinct
/// from the call control.
class _ChatEntrySheet extends StatelessWidget {
  const _ChatEntrySheet({required this.orderId, required this.customerName});

  final String orderId;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.inProgress.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.messageSquare,
                    color: AppColors.inProgress,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message $customerName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (orderId.isNotEmpty)
                        Text(
                          'Order #$orderId',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              'In-app messaging is coming soon. You can reach the customer by '
              'phone in the meantime.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              text: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofOfDeliverySheet extends ConsumerStatefulWidget {
  final String orderId;
  final VoidCallback onComplete;
  final String? dropoffPhotoUrl;
  final String? pickupExperience;

  const _ProofOfDeliverySheet({
    required this.orderId,
    required this.onComplete,
    this.dropoffPhotoUrl,
    this.pickupExperience,
  });

  @override
  ConsumerState<_ProofOfDeliverySheet> createState() =>
      _ProofOfDeliverySheetState();
}

class _ProofOfDeliverySheetState extends ConsumerState<_ProofOfDeliverySheet> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndComplete() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the delivery PIN');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(ordersRepositoryProvider)
          .verifyDeliveryOtp(
            widget.orderId,
            otp,
            dropoffPhotoUrl: widget.dropoffPhotoUrl,
            pickupExperience: widget.pickupExperience,
          );

      if (mounted) {
        Navigator.pop(context); // Close sheet
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            // Lock badge to signal a secure handoff step.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shieldCheck,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Proof of Delivery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Enter the 4-digit PIN from the customer to complete',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // PIN input
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 12,
              ),
              decoration: const InputDecoration(
                hintText: '----',
                hintStyle: TextStyle(
                  fontSize: 28,
                  letterSpacing: 12,
                  color: AppColors.textDisabled,
                ),
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.offline,
                    fontSize: 13,
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              text: 'Verify & Complete',
              icon: LucideIcons.check,
              isLoading: _isVerifying,
              onPressed: _isVerifying ? null : _verifyAndComplete,
            ),
          ],
        ),
      ),
    );
  }
}
