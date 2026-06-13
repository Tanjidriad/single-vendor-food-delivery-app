/// Design token class for spacing values.
///
/// All values are positive multiples of the 4px base unit.
class SpacingTokens {
  const SpacingTokens();

  /// Base spacing unit (4px).
  static const double base = 4;

  // Named spacing constants (multiples of 4px)
  static const double xs = 4; // 1x base
  static const double sm = 8; // 2x base
  static const double md = 12; // 3x base
  static const double lg = 16; // 4x base
  static const double xl = 20; // 5x base
  static const double xxl = 24; // 6x base
  static const double xxxl = 32; // 8x base
  static const double xxxxl = 40; // 10x base
  static const double xxxxxl = 48; // 12x base

  /// Returns all named spacing values for validation/testing.
  static List<double> get allValues => [
        xs,
        sm,
        md,
        lg,
        xl,
        xxl,
        xxxl,
        xxxxl,
        xxxxxl,
      ];
}
