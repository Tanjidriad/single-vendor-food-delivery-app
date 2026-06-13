import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import 'earnings_summary.dart';

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EarningsRepository(apiClient);
});

/// Typed failure raised by [EarningsRepository] when the Earnings_Summary
/// cannot be fetched (network error, non-2xx response, or an unexpected
/// payload).
///
/// Carrying a human-readable [message] lets the Home_Sheet and Earnings screen
/// render an Error_State with the failure reason and a retry control
/// (Requirements 1.6, 9.3) instead of silently swallowing the error and
/// returning `null`.
class EarningsFailure implements Exception {
  /// Human-readable reason the request failed.
  final String message;

  const EarningsFailure(this.message);

  @override
  String toString() => message;
}

class EarningsRepository {
  final ApiClient _apiClient;

  EarningsRepository(this._apiClient);

  /// Fetches the rider's [EarningsSummary] from the earnings endpoint.
  ///
  /// [period] controls the time range: `'day'`, `'week'`, `'month'`, or `'all'`.
  /// Defaults to `'day'` if not specified.
  ///
  /// Returns a parsed [EarningsSummary] on success. Throws an
  /// [EarningsFailure] (carrying a descriptive message) on any failure —
  /// network/connection error, non-2xx status, or an unexpected payload — so
  /// callers can surface an Error_State with a retry affordance.
  ///
  /// Also returns the raw JSON map via [rawJson] so callers can cache it.
  Future<EarningsSummary> getEarningsSummary({String period = 'day'}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.earnings}?period=$period',
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw EarningsFailure(
          'Failed to load earnings (status $statusCode).',
        );
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return EarningsSummary.fromJson(data);
      }
      if (data is Map) {
        return EarningsSummary.fromJson(Map<String, dynamic>.from(data));
      }

      throw const EarningsFailure('Received an unexpected earnings response.');
    } on EarningsFailure {
      rethrow;
    } on DioException catch (e) {
      debugPrint('Error fetching earnings: $e');
      throw EarningsFailure(_messageForDioException(e));
    } catch (e) {
      debugPrint('Error fetching earnings: $e');
      throw const EarningsFailure('Could not load earnings. Please try again.');
    }
  }

  /// Fetches raw JSON for caching purposes.
  Future<Map<String, dynamic>?> getRawEarnings({String period = 'day'}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.earnings}?period=$period',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Maps a [DioException] to a concise, rider-facing failure message.
  String _messageForDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The earnings request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        return status != null
            ? 'Failed to load earnings (status $status).'
            : 'Failed to load earnings.';
      default:
        return 'Could not load earnings. Please try again.';
    }
  }
}

