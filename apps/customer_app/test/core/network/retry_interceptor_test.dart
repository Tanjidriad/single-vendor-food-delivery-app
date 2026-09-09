import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/core/network/retry_interceptor.dart';

/// Returns [status] for the first [failures] calls, then 200.
class _FlakyAdapter implements HttpClientAdapter {
  _FlakyAdapter({required this.failures, this.status = 503});

  final int failures;
  final int status;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (calls <= failures) {
      return ResponseBody.fromString('error', status);
    }
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Builds a Dio whose retry interceptor replays on itself (mirrors api_client).
Dio _dioWith(_FlakyAdapter adapter, {int maxRetries = 3}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(
    retryInterceptor(dio, maxRetries: maxRetries, baseDelay: Duration.zero),
  );
  return dio;
}

void main() {
  test('retries a transient GET and eventually succeeds', () async {
    final adapter = _FlakyAdapter(failures: 2);
    final dio = _dioWith(adapter);

    final res = await dio.get<Map<String, dynamic>>('/orders');

    expect(res.statusCode, 200);
    expect(adapter.calls, 3); // 2 failures + 1 success
  });

  test('gives up after maxRetries and rethrows', () async {
    final adapter = _FlakyAdapter(failures: 99);
    final dio = _dioWith(adapter, maxRetries: 3);

    await expectLater(dio.get('/orders'), throwsA(isA<DioException>()));
    expect(adapter.calls, 4); // 1 initial + 3 retries
  });

  test('does not retry non-idempotent POST requests', () async {
    final adapter = _FlakyAdapter(failures: 99);
    final dio = _dioWith(adapter);

    await expectLater(dio.post('/orders'), throwsA(isA<DioException>()));
    expect(adapter.calls, 1); // no retry
  });

  test('does not retry 4xx client errors', () async {
    final adapter = _FlakyAdapter(failures: 99, status: 404);
    final dio = _dioWith(adapter);

    await expectLater(dio.get('/orders'), throwsA(isA<DioException>()));
    expect(adapter.calls, 1); // 404 is not transient
  });
}
