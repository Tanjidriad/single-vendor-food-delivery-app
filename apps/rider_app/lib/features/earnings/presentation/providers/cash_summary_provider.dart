import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cash_repository.dart';
import '../../data/cash_summary.dart';

/// The currently selected cash-summary period.
class CashPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setPeriod(String newPeriod) => state = newPeriod;
}

final cashPeriodProvider =
    NotifierProvider<CashPeriodNotifier, String>(CashPeriodNotifier.new);

/// Exposes the rider COD [CashSummary]; rebuilds when [cashPeriodProvider]
/// changes.
final cashSummaryProvider =
    AsyncNotifierProvider<CashSummaryNotifier, CashSummary>(
  CashSummaryNotifier.new,
);

class CashSummaryNotifier extends AsyncNotifier<CashSummary> {
  @override
  Future<CashSummary> build() async {
    final period = ref.watch(cashPeriodProvider);
    final repository = ref.watch(cashRepositoryProvider);
    return repository.getCashSummary(period: period);
  }

  Future<void> refresh() async {
    final period = ref.read(cashPeriodProvider);
    final repository = ref.read(cashRepositoryProvider);
    state = const AsyncValue<CashSummary>.loading();
    state = await AsyncValue.guard(
      () => repository.getCashSummary(period: period),
    );
  }
}
