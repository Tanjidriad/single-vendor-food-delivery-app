import 'package:flutter/material.dart';

/// The rider app palette — a premium **light** theme with a crimson-red brand
/// accent, matching the "ZIPS" delivery-partner reference (white cards on a
/// light-grey canvas, soft shadows, generous rounding).
///
/// Field names are kept stable so existing screens/widgets cascade to the new
/// look without edits. Some names still read `*Dark` for historical reasons —
/// during the light flip these are repointed to their light-hero values and
/// behave as legacy aliases (cleaned up as screens migrate to the `*Light`
/// names). New semantic tokens (`primaryBright`, `primaryDim`,
/// `surfaceElevated`) tune emphasis.
class AppColors {
  // ── Brand (crimson) ────────────────────────────────────────────────────────
  /// The signature brand crimson. Means "primary / active". White text on it
  /// clears AA for buttons and chips.
  static const Color primary = Color(0xFFE0334B);

  /// A brighter crimson for highlights, gradients, and emphasis numbers.
  static const Color primaryBright = Color(0xFFF04358);

  /// A deeper crimson for pressed fills and gradient ends.
  static const Color primaryDark = Color(0xFFC42B41);

  /// A soft, desaturated brand tint for the OFFLINE state / low-emphasis brand.
  static const Color primaryDim = Color(0xFFF5C2CB);

  /// A very subtle brand wash for tinted backgrounds and icon chips on white.
  static const Color primaryLight = Color(0xFFFCE7EB);

  // ── Surfaces & backgrounds ──────────────────────────────────────────────────
  // The hero is light: a light-grey canvas with white cards. Depth comes from
  // soft shadows + the subtle elevated fill, not lightness inversion.
  /// App canvas (light grey).
  static const Color backgroundLight = Color(0xFFF4F4F6);

  /// Card / sheet surface (white).
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Legacy alias → light canvas (repointed during the light flip).
  static const Color backgroundDark = Color(0xFFF4F4F6);

  /// Legacy alias → white card surface (repointed during the light flip).
  static const Color surfaceDark = Color(0xFFFFFFFF);

  /// A subtly raised fill for nested chips, tiles, and inputs on white.
  static const Color surfaceElevated = Color(0xFFF3F3F6);

  // ── Text ────────────────────────────────────────────────────────────────────
  /// Primary text on light surfaces (~16:1 on white).
  static const Color textPrimary = Color(0xFF1A1A1F);

  /// Secondary/supporting text (passes AA on white at ~4.9:1).
  static const Color textSecondary = Color(0xFF6B7280);

  /// Disabled/placeholder text.
  static const Color textDisabled = Color(0xFF9CA3AF);

  /// Text/icon color that sits on top of brand or colored fills (white).
  static const Color textInverse = Color(0xFFFFFFFF);

  /// Explicit dark text token (same as [textPrimary]); kept for call sites that
  /// asked for "text on a light surface".
  static const Color textOnLight = Color(0xFF1A1A1F);

  // ── Borders / hairlines ─────────────────────────────────────────────────────
  /// Hairline divider/border on light surfaces.
  static const Color borderLight = Color(0xFFECECEF);

  /// Legacy alias → light hairline (repointed during the light flip).
  static const Color borderDark = Color(0xFFECECEF);

  // ── Semantics / status ──────────────────────────────────────────────────────
  static const Color online = Color(0xFF16A34A); // Green — online / delivered
  static const Color busy = Color(0xFFF59E0B); // Amber — pending / in progress
  static const Color offline = Color(0xFFEF4444); // Red — error / cancelled
  static const Color inProgress = Color(0xFF2563EB); // Blue — info

  /// Neutral "inactive" tone — used for the offline status dot so brand crimson
  /// stays reserved for "active / primary".
  static const Color neutral = Color(0xFF9CA3AF);

  // ── Specific elements ───────────────────────────────────────────────────────
  /// Scrim behind modal map overlays / bottom sheets (≈60% black).
  static const Color overlay = Color(0x99000000);
}
