/// Promo banner carousel — tweak sizes here.
abstract final class HomePromoBannerLayout {
  /// Card height (split text + image).
  static const cardHeight = 168.0;

  /// Rounded corners on the whole card (Uber-style).
  static const cardRadius = 20.0;

  /// How much of the screen each slide takes (0.88 = next card peeks).
  static const viewportFraction = 0.88;

  /// Gap between slides.
  static const slideGap = 10.0;

  static const titleFontSize = 17.0;
  static const ctaFontSize = 14.0;
}
