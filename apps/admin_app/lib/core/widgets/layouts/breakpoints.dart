/// Responsive layout modes for the Admin Panel.
///
/// - [compact]: viewport width below 768px (mobile / narrow).
/// - [medium]: viewport width from 768px up to (but not including) 1200px.
/// - [expanded]: viewport width of 1200px and above.
enum LayoutMode { compact, medium, expanded }

/// Responsive breakpoint thresholds and resolution.
///
/// Thresholds follow Requirement 16.1:
/// - compact  : width < 768
/// - medium   : 768 <= width < 1200
/// - expanded : width >= 1200
///
/// NOTE: This is the minimal implementation required by the design token /
/// breakpoint property tests. Task 7.1 builds the full responsive layout
/// system (AppShell) on top of this utility.
class Breakpoints {
  const Breakpoints._();

  /// Lower bound (in logical pixels) for the [LayoutMode.medium] range.
  /// Widths below this resolve to [LayoutMode.compact].
  static const double compact = 768;

  /// Lower bound (in logical pixels) for the [LayoutMode.expanded] range.
  /// Widths below this (but at or above [compact]) resolve to
  /// [LayoutMode.medium].
  static const double medium = 1200;

  /// Resolves a viewport [width] (in logical pixels) to a [LayoutMode].
  static LayoutMode fromWidth(double width) {
    if (width < compact) return LayoutMode.compact;
    if (width < medium) return LayoutMode.medium;
    return LayoutMode.expanded;
  }
}
