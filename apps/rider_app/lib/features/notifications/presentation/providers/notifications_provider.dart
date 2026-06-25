import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_model.dart';
import '../../data/notifications_repository.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() => _load();

  Future<List<AppNotification>> _load() async {
    return ref.read(notificationsRepositoryProvider).listNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> markRead(String id) async {
    final current = state.value;
    if (current != null) {
      // Optimistic: flip the row immediately so the badge and styling update
      // without waiting on the network round-trip.
      state = AsyncData([
        for (final n in current) n.id == id ? n.markedRead() : n,
      ]);
    }
    try {
      await ref.read(notificationsRepositoryProvider).markRead(id);
    } catch (_) {
      // Reconcile with the server on failure so the UI never lies.
      await refresh();
    }
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null) return;
    final unread = current.where((e) => !e.isRead).toList();
    if (unread.isEmpty) return;

    state = AsyncData([
      for (final n in current) n.isRead ? n : n.markedRead(),
    ]);
    try {
      await Future.wait(
        unread.map(
          (n) => ref.read(notificationsRepositoryProvider).markRead(n.id),
        ),
      );
    } catch (_) {
      await refresh();
    }
  }
}

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
