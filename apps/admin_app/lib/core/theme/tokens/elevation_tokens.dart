import 'package:flutter/material.dart';

/// Design token class for elevation (shadow) values.
///
/// All shadow colors use alpha values below 0.08 (approximately 20/255 max).
/// The hex alpha values used:
/// - 0x0A = 10/255 ≈ 0.039
/// - 0x0D = 13/255 ≈ 0.051
/// - 0x12 = 18/255 ≈ 0.071
class ElevationTokens {
  const ElevationTokens();

  /// No elevation.
  static const List<BoxShadow> none = [];

  /// Small elevation — subtle lift for cards and buttons.
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000), // alpha ≈ 0.039
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Medium elevation — moderate lift for dropdowns and popovers.
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0D000000), // alpha ≈ 0.051
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Large elevation — prominent lift for modals and dialogs.
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x12000000), // alpha ≈ 0.071
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Returns all non-empty elevation token lists for validation/testing.
  static List<List<BoxShadow>> get allElevations => [sm, md, lg];
}
