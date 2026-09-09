import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/map/geo_point.dart';
import '../../../../core/map/map_marker.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/websockets/socket_service.dart';
import '../../../../core/widgets/map/app_map_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/swipe_action.dart';
import '../../data/assignment_view.dart';
import '../../data/countdown_state.dart';
import '../../data/orders_repository.dart';
import '../providers/location_provider.dart';
import '../providers/order_providers.dart';
import '../providers/route_provider.dart';
import '../providers/rider_orders_provider.dart';
import '../widgets/countdown_ring.dart';


/// The redesigned incoming order screen (Requirement 3).
///
/// Earnings-first: the estimated payout is the most visually prominent value
/// (3.2). A two-leg [_TripLegSummary] shows the restaurant pickup leg and the
/// customer dropoff leg, each with its own distance (3.3). A [CountdownRing]
/// wraps the accept [SwipeAction] and animates full → empty over the response
/// window derived from `expiresAt`, switching to the warning treatment at
/// `≤ 10s` (3.4, 3.5). Completing the swipe accepts the assignment, joins the
/// order room (6.1), and navigates to the active delivery screen (3.6); a
/// distinct secondary control rejects and returns home (3.7, 3.8); expiry
/// clears the assignment and returns home (3.9); an accept failure re-enables
/// the swipe (3.10).
///
/// Map data crosses the screen boundary as SDK-neutral [GeoPoint]/[MapMarker]
/// values only — this screen imports no map SDK and sources the live position
/// from [locationStreamProvider] (GeoPoint), satisfying Requirement 10.2.
class IncomingOrderScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? assignmentData;

  const IncomingOrderScreen({super.key, this.assignmentData});

  @override
  ConsumerState<IncomingOrderScreen> createState() =>
      _IncomingOrderScreenState();
}

class _IncomingOrderScreenState extends ConsumerState<IncomingOrderScreen> {
  Timer? _countdownTimer;

  /// Seconds remaining in the response window; ticks down each second.
  int _remainingSeconds = 45;

  /// The full response window in seconds, derived from `expiresAt` at mount so
  /// the ring runs full → empty over it.
  int _totalSeconds = 45;

  bool _isAccepting = false;
  bool _isRejecting = false;

  Map<String, dynamic> get _data =>
      widget.assignmentData ?? ref.read(activeAssignmentProvider) ?? const {};

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    // Derive the remaining window from `expiresAt` when available; the initial
    // remaining seconds become the total so the ring starts full.
    final expiresAt = AssignmentView.fromJson(_data).expiresAt;
    if (expiresAt != null) {
      final diff = expiresAt.difference(DateTime.now()).inSeconds;
      _remainingSeconds = diff > 0 ? diff : 0;
    }
    _totalSeconds = _remainingSeconds > 0 ? _remainingSeconds : 45;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onExpired();
      }
    });
  }

  /// Response window expired before the rider responded: clear the active
  /// assignment and return home (Requirement 3.9). Skipped while an
  /// accept/reject is in flight so it never races those flows.
  void _onExpired() {
    if (!mounted || _isAccepting || _isRejecting) return;
    ref.read(activeAssignmentProvider.notifier).set(null);
    ref.read(pendingAssignmentProvider.notifier).set(null);
    context.pop();
  }

  /// The server expired/reassigned this offer before the local countdown ran
  /// out (e.g. the rider's clock drifted, or dispatch moved it on). Tear the
  /// screen down immediately rather than letting the rider accept a dead offer.
  void _onServerExpired(Map<String, dynamic> payload) {
    if (!mounted || _isAccepting || _isRejecting) return;
    final expiredId = payload['assignmentId']?.toString();
    final myId = AssignmentView.fromJson(_data).assignmentId;
    // Only react to expiry of the offer this screen is showing.
    if (expiredId == null || expiredId.isEmpty || expiredId != myId) return;

    _countdownTimer?.cancel();
    ref.read(activeAssignmentProvider.notifier).set(null);
    ref.read(pendingAssignmentProvider.notifier).set(null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('This offer expired before you responded.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    context.pop();
  }

  /// Accepts the assignment behind the slide-to-confirm control (Requirement
  /// 3.6, 6.1).
  ///
  /// On success: calls the accept endpoint, fetches the full order, sets
  /// [activeOrderProvider], clears [activeAssignmentProvider], resets
  /// [deliveryStepProvider] to 0, joins the order room via
  /// [SocketService.joinOrderRoom] (6.1), and `pushReplacement`s to the active
  /// delivery screen. On failure it surfaces an error and rethrows so the
  /// [SwipeAction] handle springs back and re-enables (Requirement 3.10).
  Future<void> _acceptOrder() async {
    if (_isAccepting || _isRejecting) return;
    final assignment = AssignmentView.fromJson(_data);
    final assignmentId = assignment.assignmentId;
    if (assignmentId.isEmpty) {
      _showError('This assignment is no longer available');
      throw Exception('Missing assignment id');
    }

    setState(() => _isAccepting = true);
    unawaited(HapticFeedback.mediumImpact());
    try {
      final repo = ref.read(ordersRepositoryProvider);
      debugPrint('[AssignTrace] accept start assignmentId=$assignmentId');
      final result = await repo.acceptAssignment(assignmentId);

      final orderId = (result['orderId'] as String?) ?? assignment.orderId;

      // Fetch full order details. Do not proceed with a synthetic fallback:
      // Active delivery status updates require a real order row.
      if (orderId == null || orderId.isEmpty) {
        throw Exception('Assignment accepted but order id is missing');
      }

      Map<String, dynamic> orderData;
      try {
        orderData = await repo.getOrder(orderId);
      } catch (e) {
        throw Exception(
          'Assignment accepted, but full order could not be loaded. Please refresh assignments.',
        );
      }

      final existingActiveOrder = ref.read(activeOrderProvider);

      ref.read(activeAssignmentProvider.notifier).set(null);
      ref.read(pendingAssignmentProvider.notifier).set(null);
      ref.read(lastAcceptedAssignmentIdProvider.notifier).set(assignmentId);
      ref.invalidate(riderOrdersProvider);
      debugPrint(
        '[AssignTrace] accept success assignmentId=$assignmentId orderId=$orderId',
      );

      // Join the order room so the rider receives live updates (Req 6.1).
      ref.read(socketServiceProvider).joinOrderRoom(orderId);

      _countdownTimer?.cancel();

      if (mounted) {
        if (existingActiveOrder == null) {
          ref.read(activeOrderProvider.notifier).set(orderData);
          ref.read(deliveryStepProvider.notifier).set(0);
          context.pushReplacement(RoutePaths.activeDelivery, extra: orderData);
        } else {
          context.pop();
        }
      }
    } catch (e) {
      debugPrint('[AssignTrace] accept failed assignmentId=$assignmentId error=$e');
      // Re-enable the swipe and surface the error (Requirement 3.10).
      if (mounted) {
        setState(() => _isAccepting = false);
        final message = e.toString().replaceAll('Exception: ', '');
        final stale = message.contains('not pending') ||
            message.contains('already') ||
            message.contains('expired');
        if (stale) {
          ref.read(activeAssignmentProvider.notifier).set(null);
          ref.read(pendingAssignmentProvider.notifier).set(null);
          _showError('This offer is no longer available.');
          context.pop();
        } else {
          _showError(e);
        }
      }
      // Rethrow so the SwipeAction handle springs back to the start.
      rethrow;
    }
  }

  /// Rejects the assignment via the distinct secondary control (Requirement
  /// 3.7) and returns home (Requirement 3.8).
  Future<void> _rejectOrder() async {
    if (_isAccepting || _isRejecting) return;

    final assignmentId = AssignmentView.fromJson(_data).assignmentId;
    _countdownTimer?.cancel();
    setState(() => _isRejecting = true);

    if (assignmentId.isNotEmpty) {
      try {
        await ref.read(ordersRepositoryProvider).rejectAssignment(assignmentId);
      } catch (e) {
        debugPrint('Reject failed: $e');
        if (mounted) {
          setState(() => _isRejecting = false);
          _showError(e);
        }
        return;
      }
    }

    ref.read(activeAssignmentProvider.notifier).set(null);
    ref.read(pendingAssignmentProvider.notifier).set(null);
    if (mounted) context.pop();
  }

  void _showError(Object error) {
    final message = error.toString().replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.offline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // React to a server-side expiry of this offer (Requirement 3.9, realtime
    // path). The backend now also emits `assignment:expired` to the rider's
    // personal room, so a pending offer is torn down even before the local
    // countdown reaches zero.
    ref.listen(assignmentExpiredStreamProvider, (previous, next) {
      final data = next.value;
      if (data != null) _onServerExpired(data);
    });

    final assignment = AssignmentView.fromJson(_data);
    final countdown = CountdownState.from(_remainingSeconds, _totalSeconds);

    // --- Map layer: GeoPoint / MapMarker only (Requirement 10.2) ---
    final currentLocation = ref.watch(locationStreamProvider).value;
    final pickup = assignment.pickupPoint;
    final dropoff = assignment.dropoffPoint;

    List<GeoPoint>? route;
    if (currentLocation != null && pickup != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(liveRouteProvider.notifier).updateLocation(currentLocation, pickup);
      });
      route = ref.watch(liveRouteProvider).route;
    }

    final markers = <MapMarker>[
      if (pickup != null) MapMarker(point: pickup, kind: MapMarkerKind.pickup),
      if (dropoff != null) MapMarker(point: dropoff, kind: MapMarkerKind.dropoff),
    ];

    return Scaffold(
      body: Stack(
        children: [
          AppMapView(
            initialCamera: currentLocation ?? pickup ?? dropoff,
            route: route,
            markers: markers.isEmpty ? null : markers,
          ),
          // Gradient scrim so the offer card reads clearly while keeping the
          // map visible up top.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66000000), Color(0xE6000000)],
                    stops: [0.0, 0.55],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _CountdownPill(
                    remainingSeconds: _remainingSeconds,
                    isWarning: countdown.isWarning,
                    isCritical: countdown.isCritical,
                  ),
                  // The card is bottom-anchored and scrolls only if it cannot
                  // fit, so the layout never overflows on small screens.
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          // Fade only — a slide transform would shift the
                          // bottom-pinned controls and can leave them
                          // off-screen mid-animation.
                          child: _buildCard(context, assignment, countdown)
                              .animate()
                              .fadeIn(duration: 300.ms),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    AssignmentView assignment,
    CountdownState countdown,
  ) {
    final payout = assignment.estimatedPayout != null
        ? formatCurrency(assignment.estimatedPayout!)
        : '--';
    final cash = assignment.cashToCollect != null
        ? formatCurrency(assignment.cashToCollect!)
        : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StatusChip(status: RiderStatus.busy),
          const SizedBox(height: AppSpacing.lg),

          // --- Earnings-first: payout is the most prominent value (3.2) ---
          const Text(
            "YOU'LL EARN",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            payout,
            style: const TextStyle(
              fontSize: 46,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryBright,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Cash to collect + payment method (secondary).
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.wallet,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${assignment.paymentMethod} · Collect $cash',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(height: 1),
          ),

          // --- Two-leg trip summary (3.3) ---
          _TripLegSummary(
            pickupName: assignment.pickupName,
            pickupLegKm: assignment.pickupLegKm,
            dropoffLegKm: assignment.dropoffLegKm,
          ),

          const SizedBox(height: AppSpacing.xl),

          // --- Countdown ring around the accept primary action (3.4, 3.6) ---
          LayoutBuilder(
            builder: (context, constraints) {
              final double ringSize =
                  math.min(constraints.maxWidth, 200.0);
              final double swipeWidth = ringSize - 28;
              return CountdownRing.fromState(
                countdown,
                size: ringSize,
                child: SizedBox(
                  width: swipeWidth,
                  child: SwipeAction(
                    label: 'Swipe to accept',
                    icon: LucideIcons.check,
                    enabled: !_isRejecting,
                    onConfirmed: _acceptOrder,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // --- Distinct reject control (3.7) ---
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_isAccepting || _isRejecting) ? null : _rejectOrder,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                side: const BorderSide(color: AppColors.borderDark, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              icon: _isRejecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.x,
                      size: 18, color: AppColors.textSecondary),
              label: const Text(
                'Reject',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The numeric countdown pill at the top of the screen. Switches to the warning
/// (red) treatment when the response window is nearly over (Requirement 3.5).
class _CountdownPill extends StatelessWidget {
  const _CountdownPill({
    required this.remainingSeconds,
    required this.isWarning,
    required this.isCritical,
  });

  final int remainingSeconds;
  final bool isWarning;
  final bool isCritical;

  Color get _color {
    if (isCritical) return AppColors.offline;
    if (isWarning) return AppColors.busy;
    return AppColors.inProgress;
  }

  String get _formatted {
    final safe = remainingSeconds < 0 ? 0 : remainingSeconds;
    final mins = (safe ~/ 60).toString().padLeft(2, '0');
    final secs = (safe % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.timer, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            _formatted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact two-leg trip summary: the restaurant pickup leg and the customer
/// dropoff leg, each with its own distance (Requirement 3.3).
class _TripLegSummary extends StatelessWidget {
  const _TripLegSummary({
    required this.pickupName,
    required this.pickupLegKm,
    required this.dropoffLegKm,
  });

  final String pickupName;
  final num? pickupLegKm;
  final num? dropoffLegKm;

  static String _km(num? value) =>
      value != null ? '${value.toStringAsFixed(1)} km' : '--';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connector rail: pickup dot → line → dropoff pin.
        Column(
          children: [
            const Icon(LucideIcons.store, color: AppColors.primary, size: 20),
            Container(width: 2, height: 28, color: AppColors.borderDark),
            const Icon(LucideIcons.mapPin,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegRow(
                title: pickupName,
                subtitle: 'Pickup',
                distance: _km(pickupLegKm),
              ),
              const SizedBox(height: 20),
              _LegRow(
                title: 'Customer drop-off',
                subtitle: 'Delivery',
                distance: _km(dropoffLegKm),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single leg of the [_TripLegSummary]: a title/subtitle on the left and the
/// leg distance on the right.
class _LegRow extends StatelessWidget {
  const _LegRow({
    required this.title,
    required this.subtitle,
    required this.distance,
  });

  final String title;
  final String subtitle;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          distance,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
