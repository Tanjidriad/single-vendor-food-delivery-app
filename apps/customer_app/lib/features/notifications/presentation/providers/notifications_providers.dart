import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications_repository.dart';

final notificationsListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).list();
});
