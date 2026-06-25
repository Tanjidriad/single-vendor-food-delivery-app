import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import 'cash_summary.dart';

final cashRepositoryProvider = Provider<CashRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CashRepository(apiClient);
});

class CashFailure implements Exception {
  final String message;
  const CashFailure(this.message);
  @override
  String toString() => message;
}

class CashRepository {
  final ApiClient _apiClient;

  CashRepository(this._apiClient);

  /// Fetches the rider's COD [CashSummary] for [period]
  /// (`day` | `week` | `month` | `all`).
  Future<CashSummary> getCashSummary({String period = 'day'}) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.riderCash}?period=$period',
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw CashFailure('Failed to load cash summary (status $statusCode).');
      }
      final data = response.data;
      if (data is Map<String, dynamic>) return CashSummary.fromJson(data);
      if (data is Map) return CashSummary.fromJson(Map<String, dynamic>.from(data));
      throw const CashFailure('Received an unexpected cash response.');
    } on CashFailure {
      rethrow;
    } on DioException catch (e) {
      debugPrint('Error fetching cash summary: $e');
      throw CashFailure(_messageForDioException(e));
    } catch (e) {
      debugPrint('Error fetching cash summary: $e');
      throw const CashFailure('Could not load cash summary. Please try again.');
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
            ? 'Failed to load cash summary (status $status).'
            : 'Failed to load cash summary.';
      default:
        return 'Could not load cash summary. Please try again.';
    }
  }
}
