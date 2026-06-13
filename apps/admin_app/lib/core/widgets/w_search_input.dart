import 'dart:async';

import 'package:flutter/material.dart';

import 'w_text_input.dart';

/// A search input variant built on top of [WTextInput].
///
/// Per Requirement 14.5, it renders a leading search icon (20px) and applies a
/// 300ms debounce to the [onChanged] callback so downstream filtering is not
/// invoked on every keystroke. It inherits all [WTextInput] styling: 36px
/// height, border radius `md`, 1px resting / 2px focus border, 12px horizontal
/// padding, and the disabled state (0.5 opacity, `gray50` fill, no
/// interaction).
class WSearchInput extends StatefulWidget {
  /// Placeholder (hint) text shown when the field is empty.
  final String? placeholder;

  /// Called with the latest text value after the [debounce] period elapses
  /// without further input.
  final ValueChanged<String>? onChanged;

  /// When `true`, the input renders at 0.5 opacity with a `gray50` fill and
  /// ignores all user interaction.
  final bool disabled;

  /// Optional external controller for the input's text value.
  final TextEditingController? controller;

  /// The debounce duration applied before [onChanged] fires. Defaults to
  /// 300ms per the component specification.
  final Duration debounce;

  const WSearchInput({
    super.key,
    this.placeholder,
    this.onChanged,
    this.disabled = false,
    this.controller,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Default debounce applied to [onChanged], in milliseconds.
  static const int debounceMilliseconds = 300;

  @override
  State<WSearchInput> createState() => _WSearchInputState();
}

class _WSearchInputState extends State<WSearchInput> {
  Timer? _debounceTimer;

  void _handleChanged(String value) {
    final callback = widget.onChanged;
    if (callback == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () => callback(value));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WTextInput(
      controller: widget.controller,
      placeholder: widget.placeholder,
      disabled: widget.disabled,
      prefixIcon: Icons.search_rounded,
      onChanged: _handleChanged,
    );
  }
}
