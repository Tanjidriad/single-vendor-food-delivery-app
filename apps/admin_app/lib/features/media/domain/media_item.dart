class MediaItem {
  final String id;
  final String url;
  final String publicId;
  final String filename;
  final String category;
  final DateTime createdAt;

  MediaItem({
    required this.id,
    required this.url,
    required this.publicId,
    required this.filename,
    required this.category,
    required this.createdAt,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      url: json['url'] as String,
      publicId: json['publicId'] as String,
      filename: json['filename'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
