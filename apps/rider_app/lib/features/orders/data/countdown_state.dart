/// Pure-logic view-state for the assignment countdown ring.
///
/// Derives the ring fill [fraction] and urgency flags from the remaining
/// and total seconds of the assignment response window. Keeping this derivation
/// in a pure function lets it be property-tested independently of the animation
/// (see Correctness Property 7).
library;

/// Amber warning threshold (seconds remaining).
const int kCountdownWarningThresholdSeconds = 15;

/// Critical red threshold (seconds remaining).
const int kCountdownCriticalThresholdSeconds = 5;

/// Immutable countdown view-state for the [CountdownRing].
class CountdownState {
  /// Ring fill in `[0, 1]`. `1.0` = full (just started), `0.0` = empty (expired).
  final double fraction;

  /// Amber treatment when `<= 15s` and still above critical.
  final bool isWarning;

  /// Red treatment when `<= 5s`.
  final bool isCritical;

  const CountdownState({
    required this.fraction,
    required this.isWarning,
    required this.isCritical,
  });

  /// Derives the countdown state from [remainingSeconds] out of [totalSeconds].
  factory CountdownState.from(int remainingSeconds, int totalSeconds) {
    final double fraction = totalSeconds > 0
        ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    return CountdownState(
      fraction: fraction,
      isWarning: remainingSeconds <= kCountdownWarningThresholdSeconds &&
          remainingSeconds > kCountdownCriticalThresholdSeconds,
      isCritical: remainingSeconds <= kCountdownCriticalThresholdSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CountdownState &&
      other.fraction == fraction &&
      other.isWarning == isWarning &&
      other.isCritical == isCritical;

  @override
  int get hashCode => Object.hash(fraction, isWarning, isCritical);

  @override
  String toString() =>
      'CountdownState(fraction: $fraction, isWarning: $isWarning, isCritical: $isCritical)';
}
