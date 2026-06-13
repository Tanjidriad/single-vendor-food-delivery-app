import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens/app_tokens.dart';
import 'a11y/focus_ring.dart';

/// Visual style variants for [WButton].
///
/// - [primary]: filled accent background with `onPrimary` text.
/// - [secondary]: transparent background, 1px border (border token), primary text.
/// - [ghost]: transparent background, primary text, no border.
/// - [destructive]: error-colored fill with `onPrimary` text.
enum WButtonVariant { primary, secondary, ghost, destructive }

/// Size variants for [WButton].
///
/// Each size resolves to a fixed height, horizontal padding, label text size,
/// and leading-icon size. See [WButtonSizeSpec] for the exact mapping.
enum WButtonSize { sm, md, lg }

/// Resolves the dimensional specification for each [WButtonSize].
///
/// Mapping (height / horizontalPadding / textSize / iconSize):
/// - sm → 32 / 12 / 12 / 16
/// - md → 36 / 16 / 13 / 18
/// - lg → 40 / 20 / 14 / 20
///
/// Horizontal padding consumes [SpacingTokens] and text size consumes
/// [TypographyTokens] so the component stays token-driven.
extension WButtonSizeSpec on WButtonSize {
  /// Fixed button height in logical pixels.
  double get height => switch (this) {
        WButtonSize.sm => 32,
        WButtonSize.md => 36,
        WButtonSize.lg => 40,
      };

  /// Horizontal content padding, sourced from [SpacingTokens].
  double get horizontalPadding => switch (this) {
        WButtonSize.sm => SpacingTokens.md, // 12
        WButtonSize.md => SpacingTokens.lg, // 16
        WButtonSize.lg => SpacingTokens.xl, // 20
      };

  /// Label text size, sourced from [TypographyTokens].
  double get textSize => switch (this) {
        WButtonSize.sm => TypographyTokens.sm, // 12
        WButtonSize.md => TypographyTokens.base, // 13
        WButtonSize.lg => TypographyTokens.md, // 14
      };

  /// Leading icon size in logical pixels.
  double get iconSize => switch (this) {
        WButtonSize.sm => 16,
        WButtonSize.md => 18,
        WButtonSize.lg => 20,
      };
}

/// A standardized button consuming the design token system.
///
/// Supports four [WButtonVariant]s, three [WButtonSize]s, disabled and loading
/// states, and an optional leading icon. All colors, radii, typography, and
/// spacing are sourced from [AppTokens]; no hardcoded visual values are used.
///
/// Accessibility (Requirement 20):
/// - Exposes a [Semantics] node with `button: true`, an `enabled` flag that
///   mirrors the interactive state (20.5), and a [label] describing the action
///   (20.1).
/// - Renders a 2px primary-colored focus outline with a 2px offset whenever it
///   holds keyboard focus, via [WFocusRing] (20.4).
/// - Guarantees a minimum 44x44px touch target while preserving the variant's
///   smaller visual height (20.3).
/// - Is activated by Enter/Space through the underlying [InkWell] focus
///   handling (20.2).
class WButton extends StatefulWidget {
  /// The button label text. Rendered alongside an optional [leadingIcon].
  final String label;

  /// Tap callback. When `null`, the button is treated as disabled.
  final VoidCallback? onPressed;

  /// The visual style variant. Defaults to [WButtonVariant.primary].
  final WButtonVariant variant;

  /// The size variant. Defaults to [WButtonSize.md].
  final WButtonSize size;

  /// When `true`, a 16px spinner replaces the label, the button keeps its
  /// original dimensions, and tap events are ignored.
  final bool isLoading;

  /// When `true`, the button renders at 0.5 opacity and ignores tap events.
  final bool isDisabled;

  /// Optional leading icon shown before the label with an 8px gap.
  final IconData? leadingIcon;

  /// Optional semantic label override. When omitted, [label] is used as the
  /// accessible name (Requirement 20.1).
  final String? semanticLabel;

  /// Diameter of the loading spinner, fixed at 16px per the component spec.
  static const double _spinnerSize = 16;

  /// Stroke width of the loading spinner.
  static const double _spinnerStrokeWidth = 2;

  const WButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = WButtonVariant.primary,
    this.size = WButtonSize.md,
    this.isLoading = false,
    this.isDisabled = false,
    this.leadingIcon,
    this.semanticLabel,
  });

  @override
  State<WButton> createState() => _WButtonState();
}

class _WButtonState extends State<WButton> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'WButton');

  /// Whether the button currently responds to taps.
  bool get _isInteractive =>
      !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final style = _resolveVariantStyle(colors);

    final content = widget.isLoading
        ? _buildLoadingContent(typography, style.foreground)
        : _buildLabelContent(typography, style.foreground);

    final visual = Container(
      height: widget.size.height,
      padding: EdgeInsets.symmetric(horizontal: widget.size.horizontalPadding),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: RadiusTokens.borderRadiusMd,
        border: style.borderColor != null
            ? Border.all(color: style.borderColor!, width: 1)
            : null,
      ),
      child: content,
    );

    // Expand the tap target to a minimum of 44x44 (Requirement 20.3) without
    // altering the variant's painted size. Vertical slop is added *inside* the
    // InkWell (so it is part of the hit region) and centers the shorter visual;
    // the minWidth constraint guarantees the horizontal target. Width-filling
    // (e.g. a full-width login button) is preserved because tight incoming
    // constraints still flow through to the visual.
    final verticalSlop = ((kMinTouchTarget - widget.size.height) / 2)
        .clamp(0.0, double.infinity);

    final interactive = Material(
      color: Colors.transparent,
      borderRadius: RadiusTokens.borderRadiusMd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: kMinTouchTarget),
        child: InkWell(
          focusNode: _focusNode,
          canRequestFocus: _isInteractive,
          onTap: _isInteractive ? widget.onPressed : null,
          borderRadius: RadiusTokens.borderRadiusMd,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalSlop),
            // The visible label/icon is excluded from semantics so it does not
            // duplicate the accessible name supplied by the outer [Semantics]
            // node. The InkWell's tap action (above) is preserved and merges
            // into that button node.
            child: ExcludeSemantics(child: visual),
          ),
        ),
      ),
    );

    Widget result = WFocusRing(
      focusNode: _focusNode,
      borderRadius: RadiusTokens.borderRadiusMd,
      child: interactive,
    );

    // Disabled state: reduce opacity and ignore pointer events entirely.
    if (widget.isDisabled) {
      result = Opacity(
        opacity: 0.5,
        child: IgnorePointer(child: result),
      );
    }

    return Semantics(
      button: true,
      enabled: _isInteractive,
      label: widget.semanticLabel ?? widget.label,
      child: result,
    );
  }

  /// Builds the label row (optional leading icon + text) with an 8px gap.
  Widget _buildLabelContent(TypographyTokens typography, Color foreground) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: widget.size.iconSize, color: foreground),
          const SizedBox(width: SpacingTokens.sm), // 8px gap
        ],
        Text(
          widget.label,
          style: typography.style(
            size: widget.size.textSize,
            weight: TypographyTokens.medium,
            color: foreground,
          ),
        ),
      ],
    );
  }

  /// Builds the loading content: a 16px spinner overlaid on the invisible
  /// label so the button retains its original dimensions.
  Widget _buildLoadingContent(TypographyTokens typography, Color foreground) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Reserve the label's footprint to maintain dimensions.
        Opacity(
          opacity: 0,
          child: _buildLabelContent(typography, foreground),
        ),
        SizedBox(
          width: WButton._spinnerSize,
          height: WButton._spinnerSize,
          child: CircularProgressIndicator(
            strokeWidth: WButton._spinnerStrokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(foreground),
          ),
        ),
      ],
    );
  }

  /// Resolves background, foreground, and border colors for the current
  /// [WButton.variant] from the active [ColorTokens].
  _VariantStyle _resolveVariantStyle(ColorTokens colors) {
    return switch (widget.variant) {
      WButtonVariant.primary => _VariantStyle(
          background: colors.primary,
          foreground: colors.onPrimary,
        ),
      WButtonVariant.secondary => _VariantStyle(
          background: Colors.transparent,
          foreground: colors.primary,
          borderColor: colors.border,
        ),
      WButtonVariant.ghost => _VariantStyle(
          background: Colors.transparent,
          foreground: colors.primary,
        ),
      WButtonVariant.destructive => _VariantStyle(
          background: colors.error,
          foreground: colors.onPrimary,
        ),
    };
  }
}

/// Resolved color set for a [WButtonVariant].
class _VariantStyle {
  final Color background;
  final Color foreground;
  final Color? borderColor;

  const _VariantStyle({
    required this.background,
    required this.foreground,
    this.borderColor,
  });
}
