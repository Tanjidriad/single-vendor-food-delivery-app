import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing scale (logical pixels). Use these instead of scattering raw numbers
/// so vertical rhythm stays consistent across screens.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Corner-radius scale. Pills use [full]; cards use [lg]/[xl]; sheets use [xxl].
class AppRadius {
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double sheet = 28;

  /// Effectively fully-rounded (for pills and circular handles).
  static const double full = 999;
}

/// Reusable layered shadows. On a dark canvas, depth comes from a combination
/// of a soft ambient shadow plus the surface lightness steps in [AppColors].
class AppShadows {
  /// Subtle lift for cards and tiles on a light surface.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Stronger lift for floating sheets, headers, and modals.
  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Brand-crimson glow for primary actions (primary buttons, swipe handle).
  /// Kept lighter than the dark theme so it reads as a soft tint on white.
  static List<BoxShadow> glow(Color color, {double strength = 0.28}) => [
        BoxShadow(
          color: color.withValues(alpha: strength),
          blurRadius: 18,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];
}
