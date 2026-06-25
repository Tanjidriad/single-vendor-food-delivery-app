import 'dart:io' show Platform;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

/// Background/terminated-isolate handler. Top-level + vm:entry-point so the
/// platform can invoke it. The OS renders the tray notification itself.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// True once Firebase initialized. When false (credentials not added yet),
/// [PushNotificationService] no-ops so the app runs normally.
bool _firebaseReady = false;

/// Whether [initFirebaseMessaging] managed to initialize Firebase. Used to gate
/// Crashlytics wiring so it is only enabled when Firebase is actually available.
bool isFirebaseConfigured() => _firebaseReady;

/// Initializes Firebase + background handler. Guarded so a missing
/// google-services.json / GoogleService-Info.plist degrades gracefully.
Future<void> initFirebaseMessaging() async {
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _firebaseReady = true;
  } catch (e) {
    _firebaseReady = false;
    if (kDebugMode) {
      debugPrint('[Push] Firebase not configured yet — push disabled: $e');
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

/// Registers the device's FCM token so the backend can push order-status
/// updates. No-ops until Firebase is configured.
class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  bool _listenersWired = false;

  Dio get _dio => _ref.read(apiClientProvider);

  /// Requests permission, registers the token, and wires the refresh listener.
  /// Safe to call repeatedly (e.g. each login).
  Future<void> register() async {
    if (!_firebaseReady) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }

      if (!_listenersWired) {
        _listenersWired = true;
        messaging.onTokenRefresh.listen(_registerToken);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] register failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _dio.post(
        ApiEndpoints.devicesRegister,
        data: {
          'deviceId': await _deviceId(),
          'platform': _platform(),
          'token': token,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] token registration failed: $e');
    }
  }

  String _platform() {
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'WEB';
  }

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('push_device_id');
    if (id == null || id.isEmpty) {
      id = 'customer-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 31)}';
      await prefs.setString('push_device_id', id);
    }
    return id;
  }
}
