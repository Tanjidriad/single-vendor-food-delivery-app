import 'package:flutter/material.dart';

import '../../theme/app_theme_extension.dart';

/// The minimum interactive touch-target dimension in logical pixels.
///
/// Requirement 20.3: all interactive elements SHALL have a minimum touch
/// target size of 44x44 pixels. Components expand their hit area to at least
/// this size while preserving their smaller visual footprint.
const double kMinTouchTarget = 44.0;

/// The width of the focus outline (Requirement 20.4).
const double kFocusRingWidth = 2.0;

/// The gap between the focused element's edge and its outline (Requirement
/// 20.4: a 2px offset).
const double kFocusRingOffset = 2.0;

/// A reusable focus indicator that draws a 2px primary-colored outline with a
/// 2px offset around [child] whenever [focusNode] (or one of its descendants)
/// holds focus.
///
/// Requirement 20.4: focus indicators SHALL be visible on all focusable
/// elements using a 2px primary-colored outline with a 2px offset from the
/// element edge. The outline color is sourced from the active design tokens
/// (`context.colors.primary`), which maintains the required contrast against
/// the surrounding surface in both light and dark themes.
///
/// The outline and its offset are reserved in the layout at all times (the
/// border is simply transparent while unfocused), so focusing an element never
/// shifts surrounding content.
///
/// Callers pass the same [FocusNode] that drives the wrapped interactive
/// element (e.g. an [InkWell]'s `focusNode`) so the ring reflects the element's
/// real focus state without introducing an extra tab stop.
class WFocusRing extends StatefulWidget {
  const WFocusRing({
    super.key,
    required this.focusNode,
    required this.child,
    this.borderRadius,
  });

  /// The focus node of the wrapped interactive element. The ring becomes
  /// visible while this node has focus.
  final FocusNode focusNode;

  /// The widget the ring is drawn around.
  final Widget child;

  /// Border radius of the wrapped element. The outline uses a slightly larger
  /// radius so it stays concentric with the element's corners.
  final BorderRadius? borderRadius;

  @override
  State<WFocusRing> createState() => _WFocusRingState();
}

class _WFocusRingState extends State<WFocusRing> {
  late bool _focused;

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant WFocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      _focused = widget.focusNode.hasFocus;
    }
  }

  void _handleFocusChange() {
    if (!mounted) return;
    if (_focused != widget.focusNode.hasFocus) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final innerRadius = widget.borderRadius ?? BorderRadius.zero;
    // Keep the outline concentric with the element corners by inflating the
    // radius by the offset + outline width.
    final outerRadius = _inflate(innerRadius, kFocusRingOffset + kFocusRingWidth);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: outerRadius,
        border: Border.all(
          color: _focused ? colors.primary : Colors.transparent,
          width: kFocusRingWidth,
        ),
      ),
      padding: const EdgeInsets.all(kFocusRingOffset),
      child: widget.child,
    );
  }

  BorderRadius _inflate(BorderRadius radius, double delta) {
    Radius bump(Radius r) => Radius.elliptical(r.x + delta, r.y + delta);
    return BorderRadius.only(
      topLeft: bump(radius.topLeft),
      topRight: bump(radius.topRight),
      bottomLeft: bump(radius.bottomLeft),
      bottomRight: bump(radius.bottomRight),
    );
  }
}
