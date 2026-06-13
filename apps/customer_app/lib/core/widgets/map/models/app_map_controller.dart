abstract class AppMapController {
  /// Animates the map camera to the specified coordinates.
  Future<void> animateTo(double latitude, double longitude, {double zoom = 15.0});

  /// Fits the camera to the specified bounds.
  Future<void> fitBounds(double minLat, double minLng, double maxLat, double maxLng);
}
