class AppMapMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String? title;
  final String? snippet;
  final String? iconAsset;

  /// Compass heading in degrees (0 = north). Used for the rider arrow marker.
  final double? headingDegrees;

  AppMapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.title,
    this.snippet,
    this.iconAsset,
    this.headingDegrees,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppMapMarker &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => id.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}
