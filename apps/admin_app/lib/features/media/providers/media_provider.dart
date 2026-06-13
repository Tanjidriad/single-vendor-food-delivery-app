import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/media_repository.dart';
import '../domain/media_item.dart';

class MediaCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'MENU';
  
  void setCategory(String category) {
    state = category;
  }
}

final mediaCategoryProvider = NotifierProvider<MediaCategoryNotifier, String>(() {
  return MediaCategoryNotifier();
});

final mediaListProvider =
    AsyncNotifierProvider<MediaListNotifier, List<MediaItem>>(() {
  return MediaListNotifier();
});

class MediaListNotifier extends AsyncNotifier<List<MediaItem>> {
  @override
  Future<List<MediaItem>> build() async {
    return _fetchMedia();
  }

  Future<List<MediaItem>> _fetchMedia() async {
    final repo = ref.read(mediaRepositoryProvider);
    final category = ref.watch(mediaCategoryProvider);
    return repo.getMedia(category: category);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMedia());
  }

  Future<void> uploadMedia(XFile file, String category) async {
    final repo = ref.read(mediaRepositoryProvider);
    await repo.uploadMedia(file, category);
    await refresh();
  }

  Future<void> deleteMedia(String id) async {
    final repo = ref.read(mediaRepositoryProvider);
    await repo.deleteMedia(id);
    await refresh();
  }
}
