import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for rider earnings data using SharedPreferences.
///
/// Stores the last successful earnings API response as JSON so the rider
/// sees their earnings immediately on app launch (including after reinstall
/// and re-login) without waiting for the network. The cache is keyed by
/// period so each period view has its own cached data.
class EarningsCache {
  static const _keyPrefix = 'earnings_cache_';
  static const _timestampPrefix = 'earnings_cache_ts_';

  /// Maximum age before cached data is considered stale and must be refreshed.
  static const staleDuration = Duration(minutes: 5);

  /// Saves the raw earnings JSON response for the given [period].
  Future<void> save(String period, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$period', jsonEncode(data));
    await prefs.setInt(
      '$_timestampPrefix$period',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Loads the cached earnings JSON for the given [period].
  /// Returns `null` if no cache exists.
  Future<Map<String, dynamic>?> load(String period) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$period');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Returns the [DateTime] when the cache for [period] was last saved.
  Future<DateTime?> lastUpdated(String period) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_timestampPrefix$period');
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  /// Whether the cached data for [period] is older than [staleDuration].
  Future<bool> isStale(String period) async {
    final ts = await lastUpdated(period);
    if (ts == null) return true;
    return DateTime.now().difference(ts) > staleDuration;
  }

  /// Clears cached data for all periods.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final period in ['day', 'week', 'month', 'all']) {
      await prefs.remove('$_keyPrefix$period');
      await prefs.remove('$_timestampPrefix$period');
    }
  }
}
