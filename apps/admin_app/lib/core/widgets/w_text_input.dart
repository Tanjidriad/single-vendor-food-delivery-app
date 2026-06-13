import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/tokens/app_tokens.dart';

/// A standardized single-line text input consuming the design token system.
///
/// Visual specification (Requirement 14.1, 14.3, 14.4, 14.6):
/// - Height 36px, border radius `md`, 1px border using the `border` token.
/// - On focus, a 2px border using the `primary` token.
/// - Horizontal content padding of 12px (`SpacingTokens.md`).
/// - Placeholder text styled with size `base` and the `textSecondary` color.
/// - Optional [label] rendered with size `sm`, weight `w500`, and a 4px bottom
///   margin from the input.
/// - Optional [errorText] rendered below the input with a 4px top spacing,
///   in the `error` color, size `xs`, limited to a maximum of 2 lines.
/// - When [disabled], the input renders at 0.5 opacity with a `gray50` fill and
///   ignores all user interaction.
///
/// All colors, radii, typography, and spacing are sourced from [AppTokens];
/// no hardcoded visual values leak into screen-level code.
class WTextInput extends StatefulWidget {
  /// Optional field label shown above the input.
  final String? label;

  /// Placeholder (hint) text shown when the field is empty.
  final String? placeholder;

  /// Validation error message shown below the input. When non-null and
  /// non-empty, the error block is rendered.
  final String? errorText;

  /// Optional external controller for the input's text value.
  final TextEditingController? controller;

  /// When `true`, the input renders at 0.5 opacity with a `gray50` fill and
  /// ignores all user interaction.
  final bool disabled;

  /// Called whenever the input's text value changes.
  final ValueChanged<String>? onChanged;

  /// Optional leading icon rendered inside the field (sized 20px). Primarily
  /// used by [WSearchInput] to render its search glyph.
  final IconData? prefixIcon;

  /// The keyboard type to use for editing the text.
  final TextInputType? keyboardType;

  /// Whether to hide the text being edited (e.g. for passwords).
  final bool obscureText;

  /// Optional external focus node. When omitted, an internal node is created
  /// and disposed automatically.
  final FocusNode? focusNode;

  const WTextInput({
    super.key,
    this.label,
    this.placeholder,
    this.errorText,
    this.controller,
    this.disabled = false,
    this.onChanged,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.focusNode,
  });

  /// Fixed input height in logical pixels.
  static const double height = 36;

  /// Opacity applied while [disabled].
  static const double disabledOpacity = 0.5;

  /// Leading-icon size in logical pixels.
  static const double prefixIconSize = 20;

  /// Maximum number of lines the error message may occupy.
  static const int maxErrorLines = 2;

  /// Border width when the field is unfocused.
  static const double restingBorderWidth = 1;

  /// Border width when the field is focused.
  static const double focusedBorderWidth = 2;

  @override
  State<WTextInput> createState() => _WTextInputState();
}

class _WTextInputState extends State<WTextInput> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant WTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
  }

  void _attachFocusNode(FocusNode? external) {
    _focusNode = external ?? FocusNode();
    _ownsFocusNode = external == null;
    _focused = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChange);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
  }

  void _handleFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _detachFocusNode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.tokens.typography;
    final hasError =
        widget.errorText != null && widget.errorText!.trim().isNotEmpty;

    final field = _buildField(colors, typography);

    // Requirement 20.5: form controls expose their associated label and
    // validation state (valid / invalid with the error description) to
    // assistive technology. The wrapper carries the label/hint so the field is
    // announced with its name; the error description is exposed via `value`.
    return Semantics(
      textField: true,
      label: widget.label,
      hint: widget.placeholder,
      value: hasError ? widget.errorText : null,
      enabled: !widget.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: typography.style(
                size: TypographyTokens.sm,
                weight: TypographyTokens.medium,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs), // 4px bottom margin
          ],
          widget.disabled
              ? Opacity(
                  opacity: WTextInput.disabledOpacity,
                  child: IgnorePointer(child: field),
                )
              : field,
          if (hasError) ...[
            const SizedBox(height: SpacingTokens.xs), // 4px top spacing
            // Requirement 20.7: validation errors are announced to assistive
            // technology via a live region without requiring navigation.
            Semantics(
              liveRegion: true,
              child: Text(
                widget.errorText!,
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

  Widget _buildField(ColorTokens colors, TypographyTokens typography) {
    final borderColor = _focused ? colors.primary : colors.border;
    final borderWidth = _focused
        ? WTextInput.focusedBorderWidth
        : WTextInput.restingBorderWidth;

    return Container(
      height: WTextInput.height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
      decoration: BoxDecoration(
        color: widget.disabled ? colors.gray50 : colors.surface,
        borderRadius: RadiusTokens.borderRadiusMd,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Row(
        children: [
          if (widget.prefixIcon != null) ...[
            Icon(
              widget.prefixIcon,
              size: WTextInput.prefixIconSize,
              color: colors.textSecondary,
            ),
            const SizedBox(width: SpacingTokens.sm),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: !widget.disabled,
              onChanged: widget.onChanged,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              cursorColor: colors.primary,
              style: typography.style(
                size: TypographyTokens.base,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: typography.style(
                  size: TypographyTokens.base,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
