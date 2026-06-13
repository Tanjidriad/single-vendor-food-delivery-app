import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../../features/auth/providers/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  return dio;
});

/// In-memory access token for authenticated API calls.
final authTokenProvider = StateProvider<String?>(
  (ref) => null,
);

const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

void _scheduleAuthUpdate(Ref ref, String? accessToken) {
  Future.microtask(() {
    ref.read(authTokenProvider.notifier).state = accessToken;
  });
}

Future<void> _scheduleSessionClear(Ref ref) async {
  Future.microtask(() async {
    ref.read(authProvider.notifier).logout();
  });
}

final apiClientProvider = Provider<Dio>((ref) {
  final baseDio = ref.watch(dioProvider);
  final client = Dio(baseDio.options.copyWith(baseUrl: AppConfig.apiBaseUrl));
  var isRefreshing = false;

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
        if (error.response?.statusCode != 401 || isRefreshing) {
          return handler.next(error);
        }

        final path = error.requestOptions.path;
        if (path.contains('/auth/refresh') || path.contains('/auth/login')) {
          return handler.next(error);
        }

        isRefreshing = true;
        try {
          const storage = FlutterSecureStorage();
          final refreshToken = await storage.read(key: _kRefreshToken);

          if (refreshToken == null || refreshToken.isEmpty) {
            isRefreshing = false;
            await _scheduleSessionClear(ref);
            return handler.next(error);
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
            isRefreshing = false;
            await _scheduleSessionClear(ref);
            return handler.next(error);
          }

          await storage.write(key: _kAccessToken, value: newAccessToken);
          await storage.write(key: _kRefreshToken, value: newRefreshToken);
          _scheduleAuthUpdate(ref, newAccessToken);

          isRefreshing = false;
          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await client.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } on DioException {
          isRefreshing = false;
          await _scheduleSessionClear(ref);
          return handler.next(error);
        } catch (_) {
          isRefreshing = false;
          return handler.next(error);
        }
      },
    ),
  );

  return client;
});
