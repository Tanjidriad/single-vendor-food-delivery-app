import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/countdown_state.dart';

/// A circular progress ring painted around a [child], used on the incoming
/// order screen to visualize the assignment response window.
///
/// The ring's arc length reflects [fraction] (`1.0` = full, `0.0` = empty,
/// clamped), running full -> empty as the remaining time decreases. When
/// [isWarning] is true the ring switches to the warning color treatment
/// (`AppColors.offline`) to signal the response window is nearly over.
///
/// The derivation of [fraction]/[isWarning] from the remaining/total seconds is
/// the pure [CountdownState.from] function; this widget only renders the
/// resulting view-state. Use [CountdownRing.fromState] to build directly from a
/// [CountdownState].
///
/// Satisfies Requirement 3.4 (ring animates full -> empty over the response
/// window), 3.5 (warning color treatment at/below the threshold), and 11.4
/// (themed via [AppColors] in both light and dark themes).
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.fraction,
    required this.isWarning,
    required this.child,
    this.size = 220,
    this.strokeWidth = 8,
  });

  /// Builds a [CountdownRing] from a derived [CountdownState].
  CountdownRing.fromState(
    CountdownState state, {
    super.key,
    required this.child,
    this.size = 220,
    this.strokeWidth = 8,
  })  : fraction = state.fraction,
        isWarning = state.isWarning;

  /// Ring fill in `[0, 1]`. `1.0` = full, `0.0` = empty. Values outside the
  /// range are clamped by the painter.
  final double fraction;

  /// Whether to render the warning color treatment.
  final bool isWarning;

  /// The widget centered inside the ring (typically the primary action).
  final Widget child;

  /// The overall width/height of the ring.
  final double size;

  /// The thickness of the ring stroke.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Subtle track behind the progress arc, derived from the theme so it reads
    // correctly in both light and dark modes.
    final Color trackColor =
        (isDark ? AppColors.borderDark : AppColors.borderLight)
            .withValues(alpha: isDark ? 0.6 : 1.0);

    // Normal treatment uses amber ("time ticking"); warning escalates to the
    // offline red. Amber is used rather than the brand red so the red warning
    // state stays visually distinct now that the brand itself is red.
    final Color progressColor =
        isWarning ? AppColors.offline : AppColors.busy;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _CountdownRingPainter(
              fraction: fraction,
              progressColor: progressColor,
              trackColor: trackColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.fraction,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double fraction;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  /// Start the arc at the top (12 o'clock) and sweep clockwise.
  static const double _startAngle = -math.pi / 2;
  static const double _fullSweep = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final double clamped = fraction.clamp(0.0, 1.0);
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = progressColor;

    // Track: a full circle behind the progress arc.
    canvas.drawCircle(center, radius, trackPaint);

    // Progress: an arc whose length reflects the remaining fraction.
    if (clamped > 0) {
      canvas.drawArc(
        arcRect,
        _startAngle,
        _fullSweep * clamped,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
