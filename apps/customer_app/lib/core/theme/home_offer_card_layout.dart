/// Tunable layout for [HomeOfferCard] — change numbers here only.
abstract final class HomeOfferCardLayout {
  /// Image corners. Uber uses 0 (square). Try 8 or 12 for rounded.
  static const imageCornerRadius = 10.0;

  /// Image height vs width. 16/9 = wide. Smaller number = shorter image.
  static const imageAspectRatio = 16 / 9;

  /// Space between image and title.
  static const gapBelowImage = 12.0;

  static const titleFontSize = 16.0;
  static const subtitleFontSize = 13.0;

  static const heartIconSize = 24.0;
  static const heartTapPadding = 8.0;

  static const ratingSize = 36.0;
  static const promoFontSize = 11.0;
}
