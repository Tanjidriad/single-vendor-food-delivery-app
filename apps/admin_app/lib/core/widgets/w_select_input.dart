import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens/app_tokens.dart';
import 'w_text_input.dart';

/// A selectable option for [WSelectInput].
///
/// [value] is the underlying identity used for equality and selection, while
/// [label] is the human-readable text displayed in the field and dropdown.
@immutable
class SelectOption {
  /// The underlying value used for equality and selection comparisons.
  final String value;

  /// The human-readable label shown in the field and dropdown overlay.
  final String label;

  const SelectOption({required this.value, required this.label});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectOption &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label);

  @override
  int get hashCode => Object.hash(value, label);
}

/// A standardized dropdown (select) input consuming the design token system.
///
/// Matches [WTextInput] styling (Requirement 14.2): 36px height, border radius
/// `md`, 1px resting border / 2px focus border, 12px horizontal padding, the
/// same label and error treatment, and the same disabled state (0.5 opacity,
/// `gray50` fill, no interaction).
///
/// The dropdown overlay displays a maximum of 6 visible items before
/// scrolling, as required by the component specification.
class WSelectInput extends StatelessWidget {
  /// Optional field label shown above the input.
  final String? label;

  /// The selectable options presented in the dropdown overlay.
  final List<SelectOption> options;

  /// The currently selected option, or `null` when nothing is selected.
  final SelectOption? value;

  /// Placeholder text shown when no option is selected.
  final String? placeholder;

  /// Validation error message shown below the input.
  final String? errorText;

  /// When `true`, the input renders at 0.5 opacity with a `gray50` fill and
  /// ignores all user interaction.
  final bool disabled;

  /// Called when the user selects an option from the dropdown.
  final ValueChanged<SelectOption>? onChanged;

  const WSelectInput({
    super.key,
    this.label,
    required this.options,
    this.value,
    this.placeholder,
    this.errorText,
    this.disabled = false,
    this.onChanged,
  });

  /// Maximum number of options visible in the dropdown overlay before the list
  /// becomes scrollable.
  static const int maxVisibleItems = 6;

  /// Height of a single dropdown menu item in logical pixels. Used to cap the
  /// overlay height at [maxVisibleItems] rows.
  static const double itemHeight = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final hasError = errorText != null && errorText!.trim().isNotEmpty;

    final field = _buildField(context, colors, typography);

    // Requirement 20.5: expose the select control with its label, current
    // value, and validation state to assistive technology.
    return Semantics(
      button: true,
      label: label,
      value: value?.label ?? placeholder,
      hint: hasError ? errorText : null,
      enabled: !disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: typography.style(
                size: TypographyTokens.sm,
                weight: TypographyTokens.medium,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs), // 4px bottom margin
          ],
          disabled
              ? Opacity(
                  opacity: WTextInput.disabledOpacity,
                  child: IgnorePointer(child: field),
                )
              : field,
          if (hasError) ...[
            const SizedBox(height: SpacingTokens.xs), // 4px top spacing
            // Requirement 20.7: announce validation errors via a live region.
            Semantics(
              liveRegion: true,
              child: Text(
                errorText!,
                maxLines: WTextInput.maxErrorLines,
                overflow: TextOverflow.ellipsis,
                style: typography.style(
                  size: TypographyTokens.xs,
                  color: colors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    ColorTokens colors,
    TypographyTokens typography,
  ) {
    final selectedLabel = value?.label;
    final hasSelection = selectedLabel != null;

    return Container(
      height: WTextInput.height,
      decoration: BoxDecoration(
        color: disabled ? colors.gray50 : colors.surface,
        borderRadius: RadiusTokens.borderRadiusMd,
        border: Border.all(color: colors.border, width: WTextInput.restingBorderWidth),
      ),
      // Constrain the popup menu height to at most [maxVisibleItems] rows.
      child: PopupMenuButton<SelectOption>(
        enabled: !disabled,
        tooltip: '',
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(
          maxHeight: maxVisibleItems * itemHeight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.borderRadiusMd,
          side: BorderSide(color: colors.border),
        ),
        color: colors.surface,
        onSelected: onChanged,
        itemBuilder: (context) => [
          for (final option in options)
            PopupMenuItem<SelectOption>(
              value: option,
              height: itemHeight,
              child: Text(
                option.label,
                style: typography.style(
                  size: TypographyTokens.base,
                  color: colors.textPrimary,
                ),
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasSelection ? selectedLabel : (placeholder ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.style(
                    size: TypographyTokens.base,
                    color: hasSelection
                        ? colors.textPrimary
                        : colors.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: WTextInput.prefixIconSize,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
