import 'package:flutter/material.dart';

import 'tokens/app_tokens.dart';

/// A [ThemeExtension] that exposes the design system [AppTokens] through
/// Flutter's theming mechanism.
///
/// Registering this extension on a [ThemeData] allows any widget to access the
/// active design tokens via `Theme.of(context).extension<AppThemeExtension>()`
/// or, more conveniently, through the `context.tokens` extension defined below.
///
/// The light and dark token sets are swapped by registering the matching
/// [AppThemeExtension] instance on the corresponding [ThemeData]. Smooth
/// transitions between the two are handled by [lerp], which interpolates every
/// color token.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  /// The design tokens (colors, typography, spacing, elevation, radii) that are
  /// active for the current theme.
  final AppTokens tokens;

  const AppThemeExtension({required this.tokens});

  /// Pre-configured extension carrying the light token set.
  static const AppThemeExtension light = AppThemeExtension(tokens: AppTokens.light);

  /// Pre-configured extension carrying the dark token set.
  static const AppThemeExtension dark = AppThemeExtension(tokens: AppTokens.dark);

  @override
  AppThemeExtension copyWith({AppTokens? tokens}) {
    return AppThemeExtension(tokens: tokens ?? this.tokens);
  }

  @override
  AppThemeExtension lerp(covariant ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      tokens: _lerpTokens(tokens, other.tokens, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppThemeExtension &&
          runtimeType == other.runtimeType &&
          tokens == other.tokens);

  @override
  int get hashCode => tokens.hashCode;
}

/// Interpolates between two [AppTokens] sets.
///
/// Only color tokens carry instance state that differs between light and dark
/// themes, so they are interpolated field by field. Typography, spacing,
/// elevation, and radius tokens are stateless constant scales and are taken
/// from the destination set.
AppTokens _lerpTokens(AppTokens a, AppTokens b, double t) {
  return AppTokens(
    colors: _lerpColorTokens(a.colors, b.colors, t),
    typography: b.typography,
    spacing: b.spacing,
    elevation: b.elevation,
    radii: b.radii,
  );
}

/// Interpolates every color in a [ColorTokens] set.
ColorTokens _lerpColorTokens(ColorTokens a, ColorTokens b, double t) {
  Color l(Color x, Color y) => Color.lerp(x, y, t) ?? y;
  return ColorTokens(
    gray50: l(a.gray50, b.gray50),
    gray100: l(a.gray100, b.gray100),
    gray200: l(a.gray200, b.gray200),
    gray300: l(a.gray300, b.gray300),
    gray400: l(a.gray400, b.gray400),
    gray500: l(a.gray500, b.gray500),
    gray600: l(a.gray600, b.gray600),
    gray700: l(a.gray700, b.gray700),
    gray800: l(a.gray800, b.gray800),
    gray900: l(a.gray900, b.gray900),
    primary: l(a.primary, b.primary),
    primaryLight: l(a.primaryLight, b.primaryLight),
    primaryDark: l(a.primaryDark, b.primaryDark),
    success: l(a.success, b.success),
    successLight: l(a.successLight, b.successLight),
    warning: l(a.warning, b.warning),
    warningLight: l(a.warningLight, b.warningLight),
    error: l(a.error, b.error),
    errorLight: l(a.errorLight, b.errorLight),
    info: l(a.info, b.info),
    infoLight: l(a.infoLight, b.infoLight),
    surface: l(a.surface, b.surface),
    background: l(a.background, b.background),
    border: l(a.border, b.border),
    borderStrong: l(a.borderStrong, b.borderStrong),
    textPrimary: l(a.textPrimary, b.textPrimary),
    textSecondary: l(a.textSecondary, b.textSecondary),
    textDisabled: l(a.textDisabled, b.textDisabled),
    onPrimary: l(a.onPrimary, b.onPrimary),
  );
}

/// Convenience accessors for the active design tokens from a [BuildContext].
extension AppThemeContextX on BuildContext {
  /// The active [AppTokens] for the current theme.
  ///
  /// Falls back to [AppTokens.light] if the extension has not been registered
  /// on the current [ThemeData], so token access is always safe.
  AppTokens get tokens =>
      Theme.of(this).extension<AppThemeExtension>()?.tokens ?? AppTokens.light;

  /// Shortcut to the active [ColorTokens].
  ColorTokens get colors => tokens.colors;
}
