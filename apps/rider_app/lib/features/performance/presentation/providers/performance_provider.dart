import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/performance_repository.dart';
import '../../data/performance_summary.dart';

/// The currently selected performance period.
class PerformancePeriodNotifier extends Notifier<String> {
  @override
  String build() => 'week';

  void setPeriod(String newPeriod) => state = newPeriod;
}

final performancePeriodProvider =
    NotifierProvider<PerformancePeriodNotifier, String>(
  PerformancePeriodNotifier.new,
);

/// Exposes the rider [PerformanceSummary] for the performance screen.
/// Rebuilds whenever [performancePeriodProvider] changes.
final performanceSummaryProvider =
    AsyncNotifierProvider<PerformanceSummaryNotifier, PerformanceSummary>(
  PerformanceSummaryNotifier.new,
);

class PerformanceSummaryNotifier extends AsyncNotifier<PerformanceSummary> {
  @override
  Future<PerformanceSummary> build() async {
    final period = ref.watch(performancePeriodProvider);
    final repository = ref.watch(performanceRepositoryProvider);
    return repository.getPerformance(period: period);
  }

  Future<void> refresh() async {
    final period = ref.read(performancePeriodProvider);
    final repository = ref.read(performanceRepositoryProvider);
    state = const AsyncValue<PerformanceSummary>.loading();
    state = await AsyncValue.guard(
      () => repository.getPerformance(period: period),
    );
  }
}

/// Lifetime stats preview for the profile hero card.
final profilePerformancePreviewProvider =
    FutureProvider.autoDispose<PerformanceSummary>((ref) async {
  final repository = ref.watch(performanceRepositoryProvider);
  return repository.getPerformance(period: 'all');
});
