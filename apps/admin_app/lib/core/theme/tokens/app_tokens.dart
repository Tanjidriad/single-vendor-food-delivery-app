import 'color_tokens.dart';
import 'elevation_tokens.dart';
import 'radius_tokens.dart';
import 'spacing_tokens.dart';
import 'typography_tokens.dart';

export 'color_tokens.dart';
export 'elevation_tokens.dart';
export 'radius_tokens.dart';
export 'spacing_tokens.dart';
export 'typography_tokens.dart';

/// Barrel class composing all design token classes.
///
/// Provides a single access point for the entire design token system.
/// Use [AppTokens.light] or [AppTokens.dark] for pre-configured instances.
class AppTokens {
  final ColorTokens colors;
  final TypographyTokens typography;
  final SpacingTokens spacing;
  final ElevationTokens elevation;
  final RadiusTokens radii;

  const AppTokens({
    required this.colors,
    this.typography = const TypographyTokens(),
    this.spacing = const SpacingTokens(),
    this.elevation = const ElevationTokens(),
    this.radii = const RadiusTokens(),
  });

  /// Light theme token set.
  static const AppTokens light = AppTokens(
    colors: lightColorTokens,
  );

  /// Dark theme token set.
  static const AppTokens dark = AppTokens(
    colors: darkColorTokens,
  );
}
