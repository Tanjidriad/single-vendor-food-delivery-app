import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../realtime/socket_service.dart';
import 'retry_interceptor.dart';

Completer<String?>? _tokenRefreshCompleter;

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  return dio;
});

/// In-memory access token for authenticated API calls.
final authTokenProvider = StateProvider<String?>((ref) => null);

const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

/// Schedules provider writes outside Dio interceptor/async gaps so Riverpod
/// does not assert during [apiClientProvider] rebuilds.
void _scheduleAuthUpdate(Ref ref, String? accessToken) {
  Future.microtask(() {
    ref.read(authTokenProvider.notifier).state = accessToken;
  });
}

Future<void> _scheduleSessionClear(Ref ref) async {
  unawaited(Future.microtask(() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: _kAccessToken);
    await storage.delete(key: _kRefreshToken);
    ref.read(authTokenProvider.notifier).state = null;
  }));
}

final apiClientProvider = Provider<Dio>((ref) {
  final baseDio = ref.watch(dioProvider);

  final client = Dio(baseDio.options.copyWith(baseUrl: AppConfig.apiBaseUrl));

  client.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authTokenProvider);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }

        final path = error.requestOptions.path;
        if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
          return handler.next(error);
        }

        try {
          final newAccessToken = await _refreshAccessToken(ref);
          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await client.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          await _scheduleSessionClear(ref);
          return handler.next(error);
        }
      },
    ),
  );

  // Retries idempotent GETs on transient 5xx/network errors with backoff.
  // Added after auth so 401 refresh runs first and only true transient
  // failures reach the retry logic.
  client.interceptors.add(retryInterceptor(client));

  return client;
});

Future<String> _refreshAccessToken(Ref ref) async {
  if (_tokenRefreshCompleter != null) {
    final existing = await _tokenRefreshCompleter!.future;
    if (existing == null || existing.isEmpty) {
      throw StateError('Token refresh failed');
    }
    return existing;
  }

  _tokenRefreshCompleter = Completer<String?>();
  try {
    const storage = FlutterSecureStorage();
    final refreshToken = await storage.read(key: _kRefreshToken);

    if (refreshToken == null || refreshToken.isEmpty) {
      _tokenRefreshCompleter!.complete(null);
      throw StateError('No refresh token');
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final response = await refreshDio.post<Map<String, dynamic>>(
      ApiEndpoints.authRefresh,
      data: {'refreshToken': refreshToken},
    );

    final newAccessToken = response.data?['accessToken'] as String?;
    final newRefreshToken = response.data?['refreshToken'] as String?;

    if (newAccessToken == null || newRefreshToken == null) {
      _tokenRefreshCompleter!.complete(null);
      throw StateError('Invalid refresh response');
    }

    await storage.write(key: _kAccessToken, value: newAccessToken);
    await storage.write(key: _kRefreshToken, value: newRefreshToken);
    _scheduleAuthUpdate(ref, newAccessToken);
    unawaited(Future.microtask(() {
      ref.read(socketServiceProvider).reconnectWithToken(newAccessToken);
    }));
    _tokenRefreshCompleter!.complete(newAccessToken);
    return newAccessToken;
  } catch (e) {
    if (!(_tokenRefreshCompleter?.isCompleted ?? true)) {
      _tokenRefreshCompleter!.complete(null);
    }
    rethrow;
  } finally {
    _tokenRefreshCompleter = null;
  }
}
