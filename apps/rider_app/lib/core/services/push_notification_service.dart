import 'dart:io' show Platform;
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'feedback_service.dart';

/// Background/terminated-isolate message handler. Must be a top-level function
/// annotated with `@pragma('vm:entry-point')` so it survives tree-shaking and
/// can be invoked by the platform in a separate isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The system tray notification is shown by the OS automatically for
  // notification messages; we only need Firebase initialized in this isolate.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // No Firebase config in this build yet — nothing to do.
  }
}

/// Whether [initFirebaseMessaging] successfully initialized Firebase. When
/// false (e.g. credential files not added yet), [PushNotificationService] no-ops
/// so the app keeps running on the WebSocket pipeline alone.
bool _firebaseReady = false;

/// Initializes Firebase and registers the background handler.
///
/// Guarded: a missing `google-services.json` / `GoogleService-Info.plist`
/// (credentials not added yet) degrades gracefully instead of crashing at
/// launch. Call once from `main()` before `runApp`.
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

/// Registers the device's FCM token with the backend and surfaces foreground
/// order alerts. All methods no-op until Firebase is configured.
class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  bool _listenersWired = false;

  ApiClient get _api => _ref.read(apiClientProvider);

  /// Requests notification permission, registers the FCM token with the
  /// backend, and wires foreground + token-refresh listeners. Safe to call
  /// repeatedly (e.g. on every login). No-ops if Firebase isn't configured.
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
          // Foreground push for a new order offer: buzz + alert sound, matching
          // the WebSocket incoming-assignment cue.
          _ref.read(feedbackServiceProvider).onIncomingAssignment();
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Push] register failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.post(
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

  /// A stable, app-generated device identifier persisted across launches.
  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('push_device_id');
    if (id == null || id.isEmpty) {
      id = 'rider-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 31)}';
      await prefs.setString('push_device_id', id);
    }
    return id;
  }
}
