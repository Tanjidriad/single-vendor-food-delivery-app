import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/riders_repository.dart';

class RidersState {
  final List<Map<String, dynamic>> activeRiders;
  final List<Map<String, dynamic>> pendingRiders;

  RidersState({this.activeRiders = const [], this.pendingRiders = const []});
}

class RidersNotifier extends AsyncNotifier<RidersState> {
  @override
  Future<RidersState> build() async {
    return _fetchBoth();
  }

  Future<RidersState> _fetchBoth() async {
    final repo = ref.read(ridersRepositoryProvider);
    final active = await repo.fetchActiveRiders();
    final pending = await repo.fetchPendingRiders();

    return RidersState(
      activeRiders: active,
      pendingRiders: pending,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBoth());
  }

  Future<void> approveRider(String id, String status) async {
    try {
      await ref.read(ridersRepositoryProvider).updateRiderApproval(id, status);
      // Refresh list after approval
      await refresh();
    } catch (e) {
      // Throw to let the UI catch it and show a snackbar
      rethrow;
    }
  }
}

final ridersProvider = AsyncNotifierProvider<RidersNotifier, RidersState>(() {
  return RidersNotifier();
});
