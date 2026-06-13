import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/rider_online_controller.dart';

/// The animated GO online/offline centerpiece of the Home_Sheet (Requirement 2).
///
/// A large circular "GO" button (Requirement 2.1) that toggles the rider's
/// availability through [RiderOnlineController]. The control itself is purely
/// presentational: all network sequencing (request-before-state, re-entrant
/// de-duplication, failure handling — Requirements 2.2–2.5) lives in the
/// controller. This widget renders the visual state derived from
/// [isOnlineProvider] and [riderOnlineControllerProvider]:
///
/// - Tap → `RiderOnlineController.toggle()`.
/// - While a toggle is in flight ([RiderOnlineState.isLoading]) → a loading
///   indicator is shown on the control and taps are ignored (Requirement 2.4).
/// - While online → online color treatment plus a continuous pulse-and-glow
///   animation (repeating [AnimationController] driving expanding glow rings
///   and a breathing shadow) over the map (Requirement 2.6).
/// - While offline → a dimmed/offline treatment (Requirement 2.7).
/// - On a false→true transition → a one-shot color-sweep animation
///   (Requirement 2.8), detected via [WidgetRef.listen] on [isOnlineProvider].
///
/// All colors are sourced from [AppColors] and resolved against the active
/// brightness, so the control honors both light and dark themes
/// (Requirement 11.4).
class GoControl extends ConsumerStatefulWidget {
  const GoControl({super.key});

  @override
  ConsumerState<GoControl> createState() => _GoControlState();
}

class _GoControlState extends ConsumerState<GoControl>
    with TickerProviderStateMixin {
  /// Diameter of the tappable GO button.
  static const double _buttonSize = 132;

  /// Maximum diameter the pulse glow rings expand to (also the widget's box).
  static const double _glowMaxSize = _buttonSize * 1.9;

  /// Continuous pulse-and-glow while online (Requirement 2.6).
  late final AnimationController _pulseController;

  /// One-shot color-sweep on a false→true transition (Requirement 2.8).
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    // Start the continuous pulse-and-glow immediately when the rider is
    // already online on first build (Requirement 2.6). The change listener in
    // [build] keeps it in sync afterwards.
    if (ref.read(isOnlineProvider)) {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  /// Keeps the pulse-and-glow running while online and stopped while offline.
  void _syncPulse(bool online) {
    if (online) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  /// Reacts to Online_Status changes coming from [isOnlineProvider].
  void _onOnlineChanged(bool? previous, bool next) {
    // false→true: play the one-shot color-sweep transition (Requirement 2.8).
    if (previous == false && next == true) {
      _sweepController.forward(from: 0);
    }
    _syncPulse(next);
  }

  /// Handles a tap on the GO button. Activations are ignored while a toggle is
  /// in flight (Requirement 2.4); the controller also de-duplicates re-entrant
  /// calls, but the widget disables visually too.
  void _onTap(bool isLoading) {
    if (isLoading) return;
    ref.read(riderOnlineControllerProvider.notifier).toggle();
  }

  @override
  Widget build(BuildContext context) {
    // Detect online-status transitions (drives the sweep + pulse lifecycle).
    ref.listen<bool>(isOnlineProvider, _onOnlineChanged);

    final bool isOnline = ref.watch(isOnlineProvider);
    final bool isLoading = ref.watch(
      riderOnlineControllerProvider.select((s) => s.isLoading),
    );

    // Online uses the emerald "online" token; offline is a dimmed brand tint
    // so the brand stays recognizable while reading as inactive (Requirements
    // 2.6, 2.7, 11.4).
    final Color onlineColor = AppColors.online;
    final Color offlineColor = AppColors.primaryDim;

    return Semantics(
      button: true,
      enabled: !isLoading,
      label: isOnline ? 'Go offline' : 'Go online',
      child: SizedBox(
        width: _glowMaxSize,
        height: _glowMaxSize,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _sweepController]),
          builder: (context, _) {
            final double sweepValue = _sweepController.value;
            final bool sweeping = _sweepController.isAnimating;

            // During the sweep the fill lerps offline→online; otherwise it is
            // the static color for the current status.
            final Color fillColor = (isOnline && sweepValue > 0 && sweepValue < 1)
                ? Color.lerp(offlineColor, onlineColor, sweepValue)!
                : (isOnline ? onlineColor : offlineColor);

            return Stack(
              alignment: Alignment.center,
              children: [
                if (isOnline) ..._buildGlowRings(onlineColor),
                _buildButton(
                  fillColor: fillColor,
                  onlineColor: onlineColor,
                  isOnline: isOnline,
                  isLoading: isLoading,
                  sweeping: sweeping,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Expanding, fading concentric rings that radiate from the button while
  /// online — the "glow" half of the pulse-and-glow (Requirement 2.6).
  List<Widget> _buildGlowRings(Color color) {
    const int ringCount = 2;
    final double t = _pulseController.value;
    return [
      for (int i = 0; i < ringCount; i++)
        Builder(
          builder: (_) {
            // Stagger each ring by a fraction of the cycle.
            final double phase = (t + i / ringCount) % 1.0;
            final double size =
                _buttonSize + (_glowMaxSize - _buttonSize) * phase;
            final double opacity = (1 - phase) * 0.35;
            return IgnorePointer(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: opacity),
                ),
              ),
            );
          },
        ),
    ];
  }

  Widget _buildButton({
    required Color fillColor,
    required Color onlineColor,
    required bool isOnline,
    required bool isLoading,
    required bool sweeping,
  }) {
    // Breathing shadow strengthens the glow while online (Requirement 2.6).
    final List<BoxShadow> shadow = isOnline
        ? [
            BoxShadow(
              color: onlineColor
                  .withValues(alpha: 0.40 + 0.20 * _pulseController.value),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];

    return GestureDetector(
      onTap: () => _onTap(isLoading),
      child: Container(
        key: const Key('go_control_button'),
        width: _buttonSize,
        height: _buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fillColor,
          boxShadow: shadow,
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating sweep highlight that reveals the online color during
              // the false→true transition (Requirement 2.8).
              if (sweeping)
                IgnorePointer(
                  child: Transform.rotate(
                    angle: _sweepController.value * 2 * math.pi,
                    child: Container(
                      key: const Key('go_control_sweep'),
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            onlineColor.withValues(alpha: 0.85),
                          ],
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              Center(child: _buildContent(isLoading, isOnline)),
            ],
          ),
        ),
      ),
    );
  }

  /// The button face: a loading spinner while a toggle is in flight
  /// (Requirement 2.4), otherwise the "GO" label and the current status word.
  Widget _buildContent(bool isLoading, bool isOnline) {
    if (isLoading) {
      return const SizedBox(
        key: Key('go_control_loading'),
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'GO',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isOnline ? 'ONLINE' : 'OFFLINE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.92),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
