/// Pure-logic view-state for the assignment countdown ring.
///
/// Derives the ring fill [fraction] and the [isWarning] flag from the remaining
/// and total seconds of the assignment response window. Keeping this derivation
/// in a pure function lets it be property-tested independently of the animation
/// (see Correctness Property 7).
library;

/// The threshold (in seconds) at or below which the countdown enters the
/// warning treatment.
const int kCountdownWarningThresholdSeconds = 10;

/// Immutable countdown view-state for the [CountdownRing].
class CountdownState {
  /// Ring fill in `[0, 1]`. `1.0` = full (just started), `0.0` = empty (expired).
  final double fraction;

  /// Whether the remaining time has reached the warning threshold.
  final bool isWarning;

  const CountdownState({required this.fraction, required this.isWarning});

  /// Derives the countdown state from [remainingSeconds] out of [totalSeconds].
  ///
  /// - `fraction == clamp(remainingSeconds / totalSeconds, 0, 1)` when
  ///   [totalSeconds] `> 0`, so the ring runs full -> empty monotonically as the
  ///   remaining time decreases.
  /// - `isWarning == (remainingSeconds <= 10)`.
  ///
  /// When [totalSeconds] `<= 0` there is no meaningful window, so [fraction]
  /// degrades to `0.0` (empty) rather than dividing by zero.
  factory CountdownState.from(int remainingSeconds, int totalSeconds) {
    final double fraction = totalSeconds > 0
        ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    return CountdownState(
      fraction: fraction,
      isWarning: remainingSeconds <= kCountdownWarningThresholdSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CountdownState &&
      other.fraction == fraction &&
      other.isWarning == isWarning;

  @override
  int get hashCode => Object.hash(fraction, isWarning);

  @override
  String toString() =>
      'CountdownState(fraction: $fraction, isWarning: $isWarning)';
}
