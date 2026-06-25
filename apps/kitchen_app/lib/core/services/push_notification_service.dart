import 'dart:io' show Platform;
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import 'order_alert_service.dart';

/// Background/terminated-isolate handler. Top-level + vm:entry-point.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// True once Firebase initialized; when false the service no-ops so the KDS
/// keeps running on its socket + polling pipeline.
bool _firebaseReady = false;

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

/// Registers the tablet's FCM token so the backend can alert on a new order
/// even when the KDS is backgrounded or the screen is off.
class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  bool _listenersWired = false;

  ApiClient get _api => _ref.read(apiClientProvider);

  /// Requests permission, registers the token, and wires foreground + refresh
  /// listeners. Safe to call repeatedly. No-ops until Firebase is configured.
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
        FirebaseMessaging.onMessage.listen((_) {
          // Foreground new-order push: play the KDS alert sound.
          _ref.read(orderAlertServiceProvider).playNewOrderSound();
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] register failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.post(
        '/devices/register',
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
      id = 'kitchen-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 31)}';
      await prefs.setString('push_device_id', id);
    }
    return id;
  }
}
