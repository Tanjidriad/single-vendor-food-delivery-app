import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens/app_tokens.dart';

/// Semantic color variants for the [WStatusBadge] component.
///
/// Each variant maps to a semantic color from the design system's
/// [ColorTokens]: success, warning, error, and info map to their matching
/// semantic colors, while [neutral] maps to a muted gray for unknown or
/// non-semantic states.
enum StatusBadgeVariant { success, warning, error, info, neutral }

/// A small, colored label widget indicating the state of an entity
/// (order status, rider approval, item availability).
///
/// The badge renders with a tinted background (the semantic color at 10%
/// alpha), the full semantic color as the text color, an uppercase label
/// truncated to [maxLabelLength] characters with an ellipsis, font size `xs`,
/// font weight `w600`, border radius `sm`, and 8px horizontal / 4px vertical
/// padding.
///
/// See Requirements 4.1, 4.2, 4.3 and design Properties 6 and 7.
class WStatusBadge extends StatelessWidget {
  /// The label text. Rendered uppercase and truncated to [maxLabelLength]
  /// characters with an ellipsis when it exceeds that length.
  final String label;

  /// The semantic color variant that determines the badge's colors.
  final StatusBadgeVariant variant;

  const WStatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.neutral,
  });

  /// Maximum number of characters displayed before truncation.
  static const int maxLabelLength = 20;

  /// Background tint alpha applied to the semantic color (10%).
  static const double backgroundAlpha = 0.1;

  /// Formats [label] for display: transforms it to uppercase and, when the
  /// result exceeds [maxLabelLength] characters, truncates it to
  /// [maxLabelLength] characters with an ellipsis appended.
  ///
  /// Validates design Property 7 (StatusBadge label formatting).
  static String formatLabel(String label) {
    final upper = label.toUpperCase();
    if (upper.length > maxLabelLength) {
      return '${upper.substring(0, maxLabelLength)}…';
    }
    return upper;
  }

  /// Resolves the full semantic [Color] for [variant] from the active
  /// [ColorTokens].
  ///
  /// The badge background is this color at [backgroundAlpha] and the text uses
  /// this color at full opacity (design Property 6).
  static Color resolveColor(StatusBadgeVariant variant, ColorTokens colors) {
    return switch (variant) {
      StatusBadgeVariant.success => colors.success,
      StatusBadgeVariant.warning => colors.warning,
      StatusBadgeVariant.error => colors.error,
      StatusBadgeVariant.info => colors.info,
      StatusBadgeVariant.neutral => colors.gray600,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final semanticColor = resolveColor(variant, tokens.colors);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: semanticColor.withValues(alpha: backgroundAlpha),
        borderRadius: RadiusTokens.borderRadiusSm,
      ),
      child: Text(
        formatLabel(label),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tokens.typography.style(
          size: TypographyTokens.xs,
          weight: TypographyTokens.semibold,
          color: semanticColor,
        ),
      ),
    );
  }
}
