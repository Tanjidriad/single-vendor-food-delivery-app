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
    _socket!.connect();
  }

  void joinOrder(String orderId) =>
      _socket?.emit('order:join', {'orderId': orderId});

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

  /// Clears tracking-screen listeners without tearing down the socket.
  void removeOrderTrackingListeners() {
    _socket?.off('order:status.changed');
    _socket?.off('assignment:accepted');
    _socket?.off('assignment:created');
    _socket?.off('rider:location.updated');
  }

  void disconnect() {
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
