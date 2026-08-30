import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves API / socket base URLs for emulator, desktop, and physical devices.
class ApiHostResolver {
  ApiHostResolver._();

  static const _prefsApiKey = 'resolved_api_base_url';
  static const _prefsSocketKey = 'resolved_socket_base_url';

  static late String apiBaseUrl;
  static late String socketBaseUrl;

  static Future<void> init(SharedPreferences prefs) async {
    const fromEnvApi = String.fromEnvironment('API_BASE_URL');
    const fromEnvSocket = String.fromEnvironment('SOCKET_BASE_URL');
    if (fromEnvApi.isNotEmpty && fromEnvSocket.isNotEmpty) {
      apiBaseUrl = fromEnvApi;
      socketBaseUrl = fromEnvSocket;
      return;
    }

    final candidates = await _buildCandidates(prefs);
    for (final base in candidates) {
      final resolved = await _tryResolve(base);
      if (resolved != null) {
        apiBaseUrl = resolved.apiBaseUrl;
        socketBaseUrl = resolved.socketBaseUrl;
        await prefs.setString(_prefsApiKey, apiBaseUrl);
        await prefs.setString(_prefsSocketKey, socketBaseUrl);
        return;
      }
    }

    apiBaseUrl = candidates.first;
    socketBaseUrl = _socketFromApi(apiBaseUrl);
  }

  static Future<List<String>> _buildCandidates(SharedPreferences prefs) async {
    final list = <String>[];

    void add(String? url) {
      if (url == null || url.isEmpty) return;
      if (!list.contains(url)) list.add(url);
    }

    add(prefs.getString(_prefsApiKey));
    if (kDebugMode) {
      add(await _readDevHostAsset());
    }
    add(_platformDefault());

    if (kDebugMode) {
      add('http://10.0.2.2:3000/api/v1');
      add('http://localhost:3000/api/v1');
      if (!kIsWeb && Platform.isAndroid) {
        add('http://192.168.0.116:3000/api/v1');
      }
    }

    return list;
  }

  static Future<String?> _readDevHostAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/dev_api_host.txt');
      for (final line in raw.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        if (trimmed.startsWith('http')) return trimmed;
      }
    } catch (_) {}
    return null;
  }

  static String _platformDefault() {
    // Android can't reach the host machine via `localhost`; use the LAN IP.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://192.168.0.116:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  static String _socketFromApi(String apiBase) {
    return apiBase.replaceAll(RegExp(r'/api/v1/?$'), '');
  }

  static Future<({String apiBaseUrl, String socketBaseUrl})?> _tryResolve(
    String apiBaseUrl,
  ) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    try {
      final health = await dio.get<Map<String, dynamic>>('$apiBaseUrl/health');
      if (health.data?['status'] == 'ok') {
        if (kDebugMode) {
          try {
            final dev = await dio.get<Map<String, dynamic>>(
              '$apiBaseUrl/dev/client-config',
            );
            final data = dev.data;
            if (data != null) {
              final api = data['apiBaseUrl'] as String?;
              final socket = data['socketBaseUrl'] as String?;
              if (api != null && socket != null) {
                return (apiBaseUrl: api, socketBaseUrl: socket);
              }
            }
          } catch (_) {}
        }
        return (
          apiBaseUrl: apiBaseUrl,
          socketBaseUrl: _socketFromApi(apiBaseUrl),
        );
      }
    } catch (_) {}

    return null;
  }
}
