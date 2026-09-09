import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../network/api_client.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = SocketService(apiClient);
  final sub = apiClient.tokenRefreshedStream.listen((_) {
    service.reconnect();
  });
  ref.onDispose(() {
    sub.cancel();
    service.dispose();
  });
  return service;
});

/// Fires when the realtime socket connects or reconnects.
final socketConnectedStreamProvider = StreamProvider<void>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.connectedStream;
});

/// Stream of incoming assignment data from WebSocket
final incomingAssignmentStreamProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.assignmentCreatedStream;
});

/// Stream of assignment expired events
final assignmentExpiredStreamProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.assignmentExpiredStream;
});

/// Stream of order status changes
final orderStatusStreamProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.orderStatusStream;
});

/// Stream of incoming chat messages (`order:message`).
final orderMessageStreamProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.orderMessageStream;
});

class SocketService {
  final ApiClient _apiClient;
  io.Socket? _socket;
  bool _isConnected = false;
  bool _manualDisconnect = false;
  bool _lifecycleAllowsReconnect = true;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  // Stream controllers for different event types
  final _assignmentCreatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _assignmentExpiredController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _orderStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _orderMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectedController = StreamController<void>.broadcast();

  Stream<void> get connectedStream => _connectedController.stream;

  Stream<Map<String, dynamic>> get assignmentCreatedStream =>
      _assignmentCreatedController.stream;
  Stream<Map<String, dynamic>> get assignmentExpiredStream =>
      _assignmentExpiredController.stream;
  Stream<Map<String, dynamic>> get orderStatusStream =>
      _orderStatusController.stream;
  Stream<Map<String, dynamic>> get orderMessageStream =>
      _orderMessageController.stream;

  bool get isConnected => _isConnected;

  SocketService(this._apiClient);

  Future<void> reconnect() async {
    disconnect(manual: false);
    await connect();
  }

  Future<void> connect() async {
    _reconnectTimer?.cancel();
    if (_isConnected && (_socket?.connected ?? false)) return;

    final token = await _apiClient.getToken();
    if (token == null) {
      if (kDebugMode) {
        debugPrint('[SocketService] No token available, skipping connect');
      }
      return;
    }

    disconnect(manual: false); // Clean up any stale connection

    _manualDisconnect = false;
    _socket = io.io(
      '${AppConfig.socketUrl}/realtime',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableForceNew()
          .build(),
    );

    _socket?.onConnect((_) {
      debugPrint('[SocketService] Connected to realtime');
      _isConnected = true;
      _reconnectAttempt = 0;
      if (!_connectedController.isClosed) {
        _connectedController.add(null);
      }
    });

    // Rider receives a new delivery assignment
    _socket?.on('assignment:created', (data) {
      if (kDebugMode) {
        debugPrint('[SocketService] assignment:created received');
      }
      if (data is List && data.isNotEmpty) {
        data = data.first;
      }
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data is Map<String, dynamic>) {
        debugPrint(
          '[AssignTrace] socket assignmentId=${data['assignmentId']} orderId=${data['orderId']}',
        );
        _assignmentCreatedController.add(data);
      } else if (data is Map) {
        final mapped = Map<String, dynamic>.from(data);
        debugPrint(
          '[AssignTrace] socket assignmentId=${mapped['assignmentId']} orderId=${mapped['orderId']}',
        );
        _assignmentCreatedController.add(mapped);
      }
    });

    // Assignment expired (rider didn't respond in time)
    _socket?.on('assignment:expired', (data) {
      debugPrint('[SocketService] assignment:expired received');
      if (data is List && data.isNotEmpty) data = data.first;
      if (data is Map<String, dynamic>) {
        _assignmentExpiredController.add(data);
      } else if (data is Map) {
        _assignmentExpiredController.add(Map<String, dynamic>.from(data));
      }
    });

    // Order status changed
    _socket?.on('order:status.changed', (data) {
      debugPrint('[SocketService] order:status.changed received');
      if (data is Map<String, dynamic>) {
        _orderStatusController.add(data);
      } else if (data is Map) {
        _orderStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    // Incoming chat message
    _socket?.on('order:message', (data) {
      if (data is List && data.isNotEmpty) data = data.first;
      if (data is Map<String, dynamic>) {
        _orderMessageController.add(data);
      } else if (data is Map) {
        _orderMessageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected from realtime');
      _isConnected = false;
      _scheduleReconnect();
    });

    _socket?.onConnectError((data) {
      debugPrint('[SocketService] Connection error: $data');
      _isConnected = false;
      _scheduleReconnect();
    });

    _socket?.onReconnect((_) {
      debugPrint('[SocketService] Reconnected');
      _isConnected = true;
      if (!_connectedController.isClosed) {
        _connectedController.add(null);
      }
    });

    _socket?.connect();
  }

  /// Join a specific order room to receive status updates for that order
  void joinOrderRoom(String orderId) {
    _socket?.emit('order:join', {'orderId': orderId});
  }

  /// Send rider location update
  void sendLocation({
    required String orderId,
    required double latitude,
    required double longitude,
    double? heading,
  }) {
    _socket?.emit('rider:location', {
      'orderId': orderId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': ?heading,
    });
  }

  void setLifecycleAllowsReconnect(bool allowed) {
    _lifecycleAllowsReconnect = allowed;
    if (!allowed) {
      _reconnectTimer?.cancel();
    }
  }

  void _scheduleReconnect() {
    if (!shouldScheduleReconnect(
      manualDisconnect: _manualDisconnect,
      lifecycleAllowsReconnect: _lifecycleAllowsReconnect,
    )) {
      return;
    }
    _reconnectTimer?.cancel();
    final delay = reconnectBackoff(_reconnectAttempt);
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () async {
      debugPrint('[SocketService] Reconnect attempt $_reconnectAttempt');
      await connect();
    });
  }

  void disconnect({bool manual = true}) {
    _manualDisconnect = manual;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect(manual: true);
    _assignmentCreatedController.close();
    _assignmentExpiredController.close();
    _orderStatusController.close();
    _orderMessageController.close();
    _connectedController.close();
  }
}

/// Reconnect backoff schedule: 3s on the first retry, 6s on the second, then a
/// steady 15s for every subsequent attempt. Keeping this pure (no socket, no
/// timer) makes the reconnection cadence directly testable. Exposed for tests.
Duration reconnectBackoff(int attempt) {
  final seconds = switch (attempt) {
    0 => 3,
    1 => 6,
    _ => 15,
  };
  return Duration(seconds: seconds);
}

/// Whether an automatic reconnect should be scheduled. Reconnection must be
/// suppressed after a deliberate/manual disconnect (e.g. logout) and while the
/// app is backgrounded (lifecycle paused), so a signed-out or backgrounded
/// rider is never dragged back online. Exposed for tests.
bool shouldScheduleReconnect({
  required bool manualDisconnect,
  required bool lifecycleAllowsReconnect,
}) =>
    !manualDisconnect && lifecycleAllowsReconnect;
