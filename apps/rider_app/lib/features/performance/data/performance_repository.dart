import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import 'performance_summary.dart';

final performanceRepositoryProvider = Provider<PerformanceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PerformanceRepository(apiClient);
});

/// Typed failure raised when the performance summary cannot be fetched.
class PerformanceFailure implements Exception {
  final String message;
  const PerformanceFailure(this.message);
  @override
  String toString() => message;
}

class PerformanceRepository {
  final ApiClient _apiClient;

  PerformanceRepository(this._apiClient);

  /// Fetches the rider's [PerformanceSummary] for the given [period]
  /// (`day` | `week` | `month` | `all`). Throws [PerformanceFailure] with a
  /// rider-facing message on any failure.
  Future<PerformanceSummary> getPerformance({String period = 'week'}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.riderPerformance}?period=$period',
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw PerformanceFailure('Failed to load performance (status $statusCode).');
      }
      final data = response.data;
      if (data is Map<String, dynamic>) return PerformanceSummary.fromJson(data);
      if (data is Map) {
        return PerformanceSummary.fromJson(Map<String, dynamic>.from(data));
      }
      throw const PerformanceFailure('Received an unexpected performance response.');
    } on PerformanceFailure {
      rethrow;
    } on DioException catch (e) {
      debugPrint('Error fetching performance: $e');
      throw PerformanceFailure(_messageForDioException(e));
    } catch (e) {
      debugPrint('Error fetching performance: $e');
      throw const PerformanceFailure('Could not load performance. Please try again.');
    }
  }

  String _messageForDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        return status != null
            ? 'Failed to load performance (status $status).'
            : 'Failed to load performance.';
      default:
        return 'Could not load performance. Please try again.';
    }
  }
}
