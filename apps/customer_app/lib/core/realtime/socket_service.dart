import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../network/api_client.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.disconnect);
  return service;
});

class SocketService {
  io.Socket? _socket;
  String? _activeOrderId;

  void connect(String token) {
    disconnect();
    _socket = io.io(
      AppConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );
    _socket!.onReconnect((_) {
      if (_activeOrderId != null) {
        _socket?.emit('order:join', {'orderId': _activeOrderId});
      }
    });
    _socket!.onError((err) {
      if (kDebugMode) debugPrint('Socket error: $err');
    });
    _socket!.onConnectError((err) {
      if (kDebugMode) debugPrint('Socket connect error: $err');
    });
    _socket!.connect();
  }

  void joinOrder(String orderId) {
    _activeOrderId = orderId;
    _socket?.emit('order:join', {'orderId': orderId});
  }

  void onOrderStatus(void Function(Map<String, dynamic> data) handler) {
    _socket?.on('order:status.changed', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onAssignmentAccepted(void Function(Map<String, dynamic> data) handler) {
    _socket?.on('assignment:accepted', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onAssignmentCreated(void Function(Map<String, dynamic> data) handler) {
    _socket?.on('assignment:created', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onRiderLocation(void Function(Map<String, dynamic> data) handler) {
    _socket?.on('rider:location.updated', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  /// Registers a handler for incoming chat messages (`order:message`).
  void onOrderMessage(void Function(Map<String, dynamic> data) handler) {
    _socket?.on('order:message', (data) {
      if (data is List && data.isNotEmpty) data = data.first;
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  /// Removes the chat message handler (used when a chat sheet closes).
  void offOrderMessage() {
    _socket?.off('order:message');
  }

  /// Clears tracking-screen listeners without tearing down the socket.
  void removeOrderTrackingListeners() {
    _activeOrderId = null;
    _socket?.off('order:status.changed');
    _socket?.off('assignment:accepted');
    _socket?.off('assignment:created');
    _socket?.off('rider:location.updated');
  }

  void reconnectWithToken(String token) {
    final orderId = _activeOrderId;
    connect(token);
    if (orderId != null) joinOrder(orderId);
  }

  void disconnect() {
    _activeOrderId = null;
    _socket?.dispose();
    _socket = null;
  }
}

void connectSocketFromRef(Ref ref) {
  final token = ref.read(authTokenProvider);
  if (token != null && token.isNotEmpty) {
    ref.read(socketServiceProvider).connect(token);
  }
}
