import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/earnings_cache.dart';
import '../../data/earnings_repository.dart';
import '../../data/earnings_summary.dart';

/// The currently selected earnings period.
class EarningsPeriodNotifier extends Notifier<String> {
  @override
  String build() => 'day';

  void setPeriod(String newPeriod) {
    state = newPeriod;
  }
}

final earningsPeriodProvider = NotifierProvider<EarningsPeriodNotifier, String>(
  EarningsPeriodNotifier.new,
);

/// Canonical provider exposing the rider [EarningsSummary] for the Home_Sheet
/// and Earnings screen (design "Data Models → EarningsSummary").
///
/// Implements a cache-first strategy: on build, it first loads cached data from
/// SharedPreferences so the rider sees their earnings instantly (even after
/// reinstall + re-login), then refreshes from the API in the background.
///
/// The provider rebuilds whenever [earningsPeriodProvider] changes, so the
/// period selector chips on the Earnings screen drive the data seamlessly.
final earningsSummaryProvider =
    AsyncNotifierProvider<EarningsSummaryNotifier, EarningsSummary>(
  EarningsSummaryNotifier.new,
);

/// [AsyncNotifier] backing [earningsSummaryProvider].
///
/// Holds the asynchronous [EarningsSummary] state and exposes [refresh] so a
/// retry control can re-request the summary after a failure (Requirements 1.7,
/// 9.4).
class EarningsSummaryNotifier extends AsyncNotifier<EarningsSummary> {
  final _cache = EarningsCache();

  /// Fetches the [EarningsSummary] using a cache-first strategy:
  /// 1. Show cached data immediately if available
  /// 2. Fetch fresh data from the API
  /// 3. Update the cache on success
  @override
  Future<EarningsSummary> build() async {
    final period = ref.watch(earningsPeriodProvider);
    final repository = ref.watch(earningsRepositoryProvider);

    // Try loading from cache first for instant display
    final cached = await _cache.load(period);
    if (cached != null) {
      // Show cached data, then refresh in background
      final cachedSummary = EarningsSummary.fromJson(cached);

      // Kick off a background refresh (don't await)
      Future.microtask(() async {
        try {
          final rawData = await repository.getRawEarnings(period: period);
          if (rawData != null) {
            await _cache.save(period, rawData);
            final fresh = EarningsSummary.fromJson(rawData);
            // Only update if widget is still mounted
            if (state.hasValue) {
              state = AsyncValue.data(fresh);
            }
          }
        } catch (e) {
          debugPrint('Background earnings refresh failed: $e');
        }
      });

      return cachedSummary;
    }

    // No cache — fetch directly from API
    try {
      final summary = await repository.getEarningsSummary(period: period);

      // Cache the result for next time
      final rawData = await repository.getRawEarnings(period: period);
      if (rawData != null) {
        await _cache.save(period, rawData);
      }

      return summary;
    } on EarningsFailure {
      rethrow;
    }
  }

  /// Re-requests the [EarningsSummary], driving the state back through
  /// `loading` and then `data`/`error`.
  ///
  /// Backs the retry control in the Home_Sheet / Earnings Error_State
  /// (Requirements 1.7, 9.4).
  Future<void> refresh() async {
    final period = ref.read(earningsPeriodProvider);
    final repository = ref.read(earningsRepositoryProvider);

    state = const AsyncValue<EarningsSummary>.loading();
    state = await AsyncValue.guard(() async {
      final summary = await repository.getEarningsSummary(period: period);

      // Update cache on successful refresh
      final rawData = await repository.getRawEarnings(period: period);
      if (rawData != null) {
        await _cache.save(period, rawData);
      }

      return summary;
    });
  }

  /// Alias for [refresh]; named to match the "retry" affordance in the spec.
  Future<void> retry() => refresh();
}

