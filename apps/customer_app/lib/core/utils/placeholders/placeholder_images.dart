/// Stable network placeholder URLs when API images are missing.
abstract final class PlaceholderImages {
  PlaceholderImages._();

  /// Food / menu item photo (deterministic per [seed]).
  static String food({String? seed, int width = 400, int height = 400}) {
    final key = Uri.encodeComponent(seed ?? 'food-default');
    return 'https://picsum.photos/seed/$key/$width/$height';
  }

  /// Category tile on home (slightly smaller).
  static String category(String name, {int size = 128}) =>
      food(seed: 'category-${name.toLowerCase().replaceAll(' ', '-')}', width: size, height: size);

  /// Wide promo / banner.
  static String banner({String seed = 'special-offer', int width = 800, int height = 400}) =>
      food(seed: seed, width: width, height: height);

  /// Avatar / profile.
  static String avatar({String seed = 'user-profile', int size = 88}) =>
      food(seed: seed, width: size, height: size);
}
